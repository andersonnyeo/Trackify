import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:trackify/screens/FutureExpensesScreen/future_expenses_screen.dart';
import 'package:trackify/screens/chart_screen/chart.dart';
import 'package:trackify/screens/chart_screen/category_breakdown.dart';
import 'package:trackify/screens/budget/budget_recommendation.dart';
import 'package:trackify/screens/home_screen/expense_utils.dart'; // Import the utility file

class ExpenseDetailsScreen extends StatefulWidget {
  final String docId;
  final String title;

  ExpenseDetailsScreen({super.key, required this.docId, required this.title});

  @override
  State<ExpenseDetailsScreen> createState() => _ExpenseDetailsScreenState();
}

class _ExpenseDetailsScreenState extends State<ExpenseDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  late String _title; 

  

  final TextEditingController descriptionController = TextEditingController();

  // Local NLP-based categorization model (keywords)
  final Map<String, String> _categoryKeywords = {
    'food': 'Food',
    'restaurant': 'Food',
    'grocery': 'Groceries',
    'supermarket': 'Groceries',
    'bus': 'Transport',
    'train': 'Transport',
    'fuel': 'Transport',
    'uber': 'Transport',
    'shopping': 'Shopping',
    'clothes': 'Shopping',
    'movie': 'Entertainment',
    'netflix': 'Entertainment',
    'game': 'Entertainment',
  };

  // NLP-based category prediction
  String _predictCategory(String description) {
    description = description.toLowerCase();
    for (var keyword in _categoryKeywords.keys) {
      if (description.contains(keyword)) {
        return _categoryKeywords[keyword]!;
      }
    }
    return 'Other';
  }

  // Suggest category using NLP first, then Firestore
  Future<void> _suggestCategory(String description, Function(String) updateCategory) async {
    String predictedCategory = _predictCategory(description);
    updateCategory(predictedCategory);

    var categoryRef = _firestore.collection('users').doc(_uid).collection('categoryMappings');
    var query = await categoryRef.where('description', isEqualTo: description.toLowerCase()).get();

    if (query.docs.isNotEmpty) {
      updateCategory(query.docs.first['category']);
    }
  }

  void _addExpense(String docId, String description, double amount, String category, DateTime date) async {
  try {
    if (_uid.isNotEmpty) {
      CollectionReference expensesRef = _firestore
          .collection('users')
          .doc(_uid)
          .collection('expenseDocuments')
          .doc(docId)
          .collection('expenses');

      // Add the new expense
      await expensesRef.add({
        'description': description.toLowerCase(),
        'amount': amount,
        'category': category,
        'date': Timestamp.fromDate(date),
      });

      // Check if the description already has a category mapping
      var categoryRef = _firestore.collection('users').doc(_uid).collection('categoryMappings');
      var query = await categoryRef.where('description', isEqualTo: description.toLowerCase()).get();

      if (query.docs.isNotEmpty) {
        // If a mapping exists but has a different category, update it
        if (query.docs.first.get('category') != category) {
          await categoryRef.doc(query.docs.first.id).update({'category': category});
        }
      } else {
        // If no mapping exists, create a new one
        await categoryRef.add({'description': description.toLowerCase(), 'category': category});
      }
    }
  } catch (e) {
    // Handle any errors that occur during the Firestore operations
    print('Error adding expense: $e');
    // Optionally, show an alert or feedback to the user
  }
}

  void _showAddExpenseDialog(BuildContext context, String docId, {String? expenseId, String? existingDescription, double? existingAmount, String? existingCategory, DateTime? existingDate}) {
  String description = existingDescription ?? '';
  double amount = existingAmount ?? 0.0;
  String category = existingCategory ?? 'Food';
  DateTime selectedDate = existingDate ?? DateTime.now();
  List<String> categories = ['Food', 'Transport', 'Shopping', 'Groceries', 'Entertainment', 'Other'];

  String? descriptionError;
  String? amountError;
  String? customCategoryError;

  TextEditingController descriptionController = TextEditingController(text: existingDescription ?? '');
  TextEditingController amountController = TextEditingController(text: existingAmount != null ? existingAmount.toString() : '');
  TextEditingController customCategoryController = TextEditingController();

  bool isAddingCustomCategory = false;
  bool isCategoryLocked = false; // Flag to lock category
  Timer? _debounceTimer;

  void fetchCategories() async {
    var categoryDocs = await _firestore.collection('users').doc(_uid).collection('categories').get();
    categories.addAll(categoryDocs.docs.map((doc) => doc['name'].toString()).toSet()); // Avoid duplicates
  }

  fetchCategories();

  void _suggestCategoryWithDelay(String value, Function(String) updateCategory) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _suggestCategory(value, updateCategory);
    });
  }

  showDialog(
    context: context, 
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: Text(expenseId == null ? 'Add Expense' : 'Edit Expense', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.deepPurple)),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Fill out the details below. We'll try to guess the category for you!",
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  SizedBox(height: 15),
                  
                  // Description Field
                  TextField(
                    controller: descriptionController,
                    onChanged: (value) {
                      description = value;
                      setDialogState(() => descriptionError = value.isEmpty ? 'Description is required' : null);
                      if (!isCategoryLocked) {
                        _suggestCategoryWithDelay(value, (suggestedCategory) {
                          setDialogState(() => category = suggestedCategory);
                        });
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Expense Description',
                      errorText: descriptionError,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Amount Field
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      amount = double.tryParse(value) ?? 0.0;
                      setDialogState(() => amountError = (amount <= 0) ? 'Enter a valid amount' : null);
                    },
                    decoration: InputDecoration(
                      labelText: 'Amount (£)',
                      errorText: amountError,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    value: categories.contains(category) ? category : 'Other',
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: [
                      ...categories.map((e) => DropdownMenuItem(value: e, child: Text(e))),
                      const DropdownMenuItem(value: 'custom', child: Text('Add New Category')),
                    ],
                    onChanged: (value) {
                      if (value == 'custom') {
                        setDialogState(() {
                          isAddingCustomCategory = true;
                          customCategoryError = null;
                          isCategoryLocked = true; // Lock category once custom is selected
                        });
                      } else {
                        setDialogState(() {
                          category = value!;
                          isAddingCustomCategory = false;
                          isCategoryLocked = true; // Lock category once a predefined one is selected
                        });
                      }
                    },
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Tip: Type something like 'Netflix' to auto-suggest 'Entertainment'",
                    style: TextStyle(fontSize: 12, color: Colors.deepPurple),
                  ),
                  SizedBox(height: 20),

                  // Custom Category TextField
                  if (isAddingCustomCategory)
                    TextField(
                      controller: customCategoryController,
                      onChanged: (value) {
                        setDialogState(() => customCategoryError = value.trim().isEmpty ? 'Custom category is required' : null);
                      },
                      decoration: InputDecoration(
                        labelText: 'Enter New Category',
                        errorText: customCategoryError,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                      ),
                    ),
                  SizedBox(height: 20),

                  // Date Picker
                  TextButton(
                    onPressed: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null) setDialogState(() => selectedDate = pickedDate);
                    },
                    child: Text('Select Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}', style: TextStyle(fontSize: 16, color: Colors.deepPurple)),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                onPressed: () {
                  _debounceTimer?.cancel(); // Cancel debounce when closing
                  Navigator.pop(context);
                },
              ),
              // When the user submits the form
              TextButton(
                child: Text(expenseId == null ? 'Add' : 'Save', style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                onPressed: () async {
                  bool isValid = true;

                  if (description.isEmpty) {
                    setDialogState(() => descriptionError = 'Description is required');
                    isValid = false;
                  }
                  if (amount <= 0) {
                    setDialogState(() => amountError = 'Enter a valid amount');
                    isValid = false;
                  }
                  if (isAddingCustomCategory && customCategoryController.text.trim().isEmpty) {
                    setDialogState(() => customCategoryError = 'Custom category is required');
                    isValid = false;
                  }

                  if (isValid) {
                    if (isAddingCustomCategory) {
                      category = customCategoryController.text.trim();
                      await _firestore.collection('users').doc(_uid).collection('categories').add({'name': category});
                    }
                    _addExpense(docId, description, amount, category, selectedDate);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          );
        },
      );
    },
  );
}


  @override
  void initState() {
    super.initState();
    _title = widget.title; // Initialize with passed title
  }

  // Function to edit document name
  void _editDocumentName(BuildContext context) {
    TextEditingController nameController = TextEditingController(text: _title);
    
    // Error message variable
    String? nameError;
  
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Edit Document Name"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "New Document Name",
                      errorText: nameError, // Display error text if exists
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                  onPressed: () => Navigator.pop(context),
                ),
                TextButton(
                  child: const Text("Save", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                  onPressed: () async {
                    String newName = nameController.text.trim();
  
                    // Validate if the name is empty
                    if (newName.isEmpty) {
                      setDialogState(() => nameError = "Document name cannot be empty");
                      return;
                    }
  
                    try {
                      await _firestore
                          .collection('users')
                          .doc(_uid)
                          .collection('expenseDocuments')
                          .doc(widget.docId)
                          .update({'title': newName});
  
                      setState(() {
                        _title = newName; // Update the UI title immediately
                      });
  
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: 10),
                              Text(
                                "Document name updated!",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 6,
                        ),
                      );
                    } catch (e) {
                      print("Error updating document name: $e");
  
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: 10),
                              Text(
                                "Failed to update document name.",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 6,
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.purple[50],
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Text(_title, 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white), // Set back arrow color to white

        actions: [
          PopupMenuButton<String>(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 8,
            iconColor: Colors.white,
            offset: const Offset(0, 50),
            onSelected: (value) {
              if (value == 'EditDocumentName') {
                _editDocumentName(context
                );
              } else if (value == 'Monthly Overview') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => Chart(docId: widget.docId)),
                );
              } else if (value == 'Stats') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => StatsScreen(docId: widget.docId)),
                );
              } else if (value == 'FutureExpenses') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FutureExpenseScreen(docId: widget.docId)),
                );
              } else if (value == 'Budget') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => BudgetRecommendationScreen(docId: widget.docId)),
                );
              } else if (value == 'Delete') {
                deleteExpenseDocument(context, firestore, uid, widget.docId);
              }
            },
            itemBuilder: (context) => [

              PopupMenuItem(
                value: 'EditDocumentName',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.orangeAccent),
                    SizedBox(width: 10),
                    Text('Edit Document Name', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),



              const PopupMenuItem(
                value: 'Monthly Overview',
                child: Row(
                  children: [
                    Icon(Icons.bar_chart, color: Colors.blue),
                    SizedBox(width: 10),
                    Text('Monthly Overview', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'Stats',
                child: Row(
                  children: [
                    Icon(Icons.pie_chart, color: Colors.green),
                    SizedBox(width: 10),
                    Text('Category Breakdown', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'FutureExpenses',
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.orange),
                    SizedBox(width: 10),
                    Text('Future Expense Predictions', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'Budget',
                child: Row(
                  children: [
                    Icon(Icons.money_off, color: Colors.green),
                    SizedBox(width: 10),
                    Text('Budget Recommendation', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'Delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Delete Document', style: TextStyle(fontSize: 16, color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('users')
            .doc(uid)
            .collection('expenseDocuments')
            .doc(widget.docId)
            .collection('expenses')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                children: [
                  const SizedBox(height: 200),
                  Icon(Icons.receipt_long, size: 80, color: Colors.grey[500]),
                  const SizedBox(height: 20),
                  const Text("No expenses recorded yet.", style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 10),
                  const Text("Tap the + button to add your first expense.", style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            );
          }

          final expenses = snapshot.data!.docs;

          // Group expenses by date
          Map<String, List<QueryDocumentSnapshot>> groupedExpenses = {};
          for (var expense in expenses) {
            final date = DateFormat('yyyy-MM-dd').format((expense['date'] as Timestamp).toDate());
            if (!groupedExpenses.containsKey(date)) {
              groupedExpenses[date] = [];
            }
            groupedExpenses[date]!.add(expense);
          }

          return ListView(
            padding: const EdgeInsets.all(10),
            children: groupedExpenses.entries.map((entry) {
              String date = entry.key;
              List<QueryDocumentSnapshot> dailyExpenses = entry.value;

              // Calculate total amount for the day
              double totalAmount = 0;
              for (var expense in dailyExpenses) {
                totalAmount += expense['amount'];
              }

              // Format the total amount in GBP (£)
              String formattedTotalAmount = NumberFormat.currency(symbol: '£', decimalDigits: 2).format(totalAmount);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date and total amount section
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            date,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                          ),
                          Text(
                            formattedTotalAmount,  // Display formatted total amount in GBP
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                    // List of expenses for that day
                    Column(
                      children: dailyExpenses.map((expense) {
                        double expenseAmount = expense['amount'];
                        String formattedAmount = NumberFormat.currency(symbol: '£', decimalDigits: 2).format(expenseAmount);

                        return Dismissible(
                          key: Key(expense.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            color: Colors.red,
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDeleteConfirmationDialog(context, expense.id);
                          },
                          onDismissed: (direction) {
                            _deleteExpenseDetails(expense.id);
                          },
                          child: Card(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            child: ListTile(
                              title: Text(expense['description'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                '${expense['category']} - ${DateFormat('yyyy-MM-dd').format((expense['date'] as Timestamp).toDate())}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    formattedAmount, // Display formatted amount in GBP
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _editExpense(context, firestore, uid, widget.docId, expense),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    

                    
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddExpenseDialog(context, widget.docId ),
      ),
    );
  }

  void _deleteExpenseDetails(String expenseId) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (uid.isNotEmpty) {
      await firestore
          .collection('users')
          .doc(uid)
          .collection('expenseDocuments')
          .doc(widget.docId) // Use the document ID from the parent screen
          .collection('expenses')
          .doc(expenseId) // Use the specific expense ID
          .delete();
    }
  }

  void _editExpense(BuildContext context, FirebaseFirestore firestore, String uid, String docId, QueryDocumentSnapshot expense) {
    String description = expense['description'];
    double amount = expense['amount'];
    String category = expense['category'];
    DateTime selectedDate = (expense['date'] as Timestamp).toDate();

    // Error messages
    String? descriptionError;
    String? amountError;

    TextEditingController descriptionController = TextEditingController(text: description);
    TextEditingController amountController = TextEditingController(text: amount.toString());

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              contentPadding: EdgeInsets.all(20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: const Text(
                'Edit Expense',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.deepPurple),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description TextField
                    TextField(
                      controller: descriptionController,
                      onChanged: (value) {
                        description = value;
                        setDialogState(() => descriptionError = value.isEmpty ? 'Description is required' : null);
                      },
                      decoration: InputDecoration(
                        labelText: 'Expense Description',
                        errorText: descriptionError,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Amount TextField
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        amount = double.tryParse(value) ?? 0.0;
                        setDialogState(() => amountError = (amount <= 0) ? 'Enter a valid amount' : null);
                      },
                      decoration: InputDecoration(
                        labelText: 'Amount (£)',
                        errorText: amountError,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Category Dropdown
                    StreamBuilder<QuerySnapshot>(
                      stream: firestore.collection('users').doc(uid).collection('categories').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }

                        if (snapshot.hasError) {
                          return const Text('Error fetching categories');
                        }

                        // Add Firebase categories to the list
                        Set<String> categories = {'Food', 'Transport', 'Shopping', 'Groceries', 'Entertainment', 'Other'};

                        snapshot.data?.docs.forEach((doc) {
                          categories.add(doc['name']);
                        });

                        // Convert the Set back to a list
                        List<String> categoryList = categories.toList();

                        return DropdownButtonFormField<String>(
                          value: categoryList.contains(category) ? category : 'Other', // Default to 'Other' if no match
                          decoration: InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                          ),
                          items: categoryList
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (value) {
                            setDialogState(() => category = value!);
                          },
                        );
                      },
                    ),
                    SizedBox(height: 10),

                    // Date Picker Button
                    TextButton(
                      onPressed: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (pickedDate != null) setDialogState(() => selectedDate = pickedDate);
                      },
                      child: Text(
                        'Select Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                        style: TextStyle(fontSize: 16, color: Colors.deepPurple),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                  onPressed: () => Navigator.pop(context),
                ),
                TextButton(
                  child: Text(
                    'Save',
                    style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    bool isValid = true;

                    // Validate description and amount fields
                    if (description.isEmpty) {
                      setDialogState(() => descriptionError = 'Description is required');
                      isValid = false;
                    }
                    if (amount <= 0) {
                      setDialogState(() => amountError = 'Enter a valid amount');
                      isValid = false;
                    }

                    // If valid, save the changes
                    if (isValid) {
                      firestore
                          .collection('users')
                          .doc(uid)
                          .collection('expenseDocuments')
                          .doc(docId)
                          .collection('expenses')
                          .doc(expense.id)
                          .update({
                        'description': description,
                        'amount': amount,
                        'category': category,
                        'date': Timestamp.fromDate(selectedDate),
                      });
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }


}
