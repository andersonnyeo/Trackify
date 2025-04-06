import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:trackify/screens/home_screen/expenses_details_screen.dart';

class ExpenseRecordScreen extends StatefulWidget {
  const ExpenseRecordScreen({super.key});

  @override
  State<ExpenseRecordScreen> createState() => _ExpenseRecordScreenState();
}

class _ExpenseRecordScreenState extends State<ExpenseRecordScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String _uid;
  TextEditingController descriptionController = TextEditingController();
  
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

  
  @override
  void initState() {
    super.initState();
    _uid = _auth.currentUser?.uid ?? '';

    if (_uid.isEmpty) {
      Future.delayed(Duration.zero, () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not authenticated! Please log in.")),
        );
      });
    }
  }

  void _createNewDocument(String title) async {
    if (_uid.isNotEmpty) {
      await _firestore.collection('users').doc(_uid).collection('expenseDocuments').add({
        'title': title,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

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
  void _suggestCategory(String description, Function(String) updateCategory) async {
    String predictedCategory = _predictCategory(description);
    updateCategory(predictedCategory);

    var categoryRef = _firestore.collection('users').doc(_uid).collection('categoryMappings');
    var query = await categoryRef.where('description', isEqualTo: description.toLowerCase()).get();

    if (query.docs.isNotEmpty) {
      updateCategory(query.docs.first['category']);
    }
  }

  // Add Expense
  void _addExpense(String docId, String description, double amount, String category, DateTime date) async {
    if (_uid.isNotEmpty) {
      CollectionReference expensesRef = _firestore
          .collection('users')
          .doc(_uid)
          .collection('expenseDocuments')
          .doc(docId)
          .collection('expenses');

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
  }


  // Edit Expense
  void _editExpense(String docId, String expenseId, String description, double amount, String category, DateTime date) async {
    if (_uid.isNotEmpty) {
      await _firestore.collection('users').doc(_uid).collection('expenseDocuments').doc(docId).collection('expenses').doc(expenseId).update({
        'description': description,
        'amount': amount,
        'category': category,
        'date': Timestamp.fromDate(date),
      });
    }
  }

  // Delete whole expense Document
  void _deleteExpenseDocument(String docId) async {
    if (_uid.isNotEmpty) {
      // Delete all expenses inside the document first
      var expenses = await _firestore.collection('users').doc(_uid).collection('expenseDocuments').doc(docId).collection('expenses').get();
      for (var expense in expenses.docs) {
        await expense.reference.delete();
      }
      // Delete the document itself
      await _firestore.collection('users').doc(_uid).collection('expenseDocuments').doc(docId).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple[50],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10.0),
          // Header Text
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 20.0, right: 20.0),
            child: Text(
              'Expense Records 📒 ',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
                
              ),
              textAlign: TextAlign.center,
              
            ),
          ),
          const SizedBox(height: 10.0),
          // Main content (expenses list)
          Expanded(
            child: _uid.isEmpty
                ? const Center(child: Text("Please log in to view expenses."))
                : StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('users')
                        .doc(_uid)
                        .collection('expenseDocuments')
                        .orderBy('createdAt', descending: true) // Order by 'createdAt' in descending order
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            children: [
                              const SizedBox(height: 150),
                              Icon(Icons.inbox, size: 80, color: Colors.grey[500]),
                              const SizedBox(height: 20),
                              const Text(
                                "You haven't added any expense records yet!",
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 10),
                              const Text(
                                "Tap the '+' button at the bottom right to create your first record.",
                                style: TextStyle(fontSize: 14, color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),

                            ],
                          ),
                        );
                      }

                      final documents = snapshot.data!.docs;

                      return ListView.builder(
                        itemCount: documents.length,
                        itemBuilder: (context, index) {
                          var doc = documents[index];

                          return Dismissible(
                            key: Key(doc.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              color: Colors.red,
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            confirmDismiss: (direction) async {
                              return await _showDeleteConfirmationDialog(doc.id);
                            },
                            onDismissed: (direction) {
                              _deleteExpenseDocument(doc.id);
                            },
                            child: Card(
                              elevation: 4,
                              margin: const EdgeInsets.all(10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              child: ListTile(
                                title: Text(doc['title'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)
                                        ),
                                subtitle: const Text(
                                  "Tap to view or add expenses",
                                  style: TextStyle(color: Colors.grey),
                                ),

                                trailing: IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () => _showAddExpenseDialog(context, doc.id),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ExpenseDetailsScreen(docId: doc.id, title: doc['title']),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
        foregroundColor: Colors.white,
        onPressed: _showNewDocumentDialog,
      ),
    );
  }


  Future<bool?> _showDeleteConfirmationDialog(String docId) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense Document'),
        content: const Text('Are you sure you want to delete this document? All associated expenses will also be deleted.'),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(context, false)),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
  }

  void _showNewDocumentDialog() {
    String title = '';
    String? titleError; // Variable for error message
  
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('New Expense Document'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  const Text(
                    "Each document can represent a budget, trip, or a month of spending.",
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    onChanged: (value) {
                      title = value;
                      setDialogState(() {
                        // Clear error when the user starts typing
                        titleError = value.isEmpty ? 'Title is required' : null;
                      });
                    },
                    decoration: InputDecoration(
                      labelText : 'Document title',
                      errorText: titleError, // Display error message if title is empty
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
                TextButton(
                  child: const Text('Create'),
                  onPressed: () {
                    if (title.isNotEmpty) {
                      _createNewDocument(title);
                      Navigator.pop(context);
                    } else {
                      setDialogState(() {
                        // Show error message if the title is empty
                        titleError = 'Title is required';
                      });
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


  void _showAddExpenseDialog(BuildContext context, String docId, {String? expenseId, String? existingDescription, double? existingAmount, String? existingCategory, DateTime? existingDate}) {
    String description = existingDescription ?? '';
    TextEditingController descriptionController = TextEditingController(text: description);
    double amount = existingAmount ?? 0.0;
    TextEditingController amountController = TextEditingController(text: existingAmount != null ? existingAmount.toString() : '');
    String category = existingCategory ?? 'Food';
    DateTime selectedDate = existingDate ?? DateTime.now();
    List<String> categories = ['Food', 'Transport', 'Shopping', 'Groceries', 'Entertainment', 'Other'];
    TextEditingController customCategoryController = TextEditingController();
    bool isAddingCustomCategory = false;

    // Error messages
    String? descriptionError;
    String? amountError;
    String? customCategoryError;

    // Timer for debounce
    Timer? _debounceTimer;

    // Fetch categories from Firestore
    void fetchCategories() async {
      var categoryDocs = await _firestore.collection('users').doc(_uid).collection('categories').get();
      categories.addAll(categoryDocs.docs.map((doc) => doc['name'].toString()).toSet());
    }

    fetchCategories();

    // Debounce function to suggest category after typing stops
    void _suggestCategoryWithDelay(String value, Function(String) updateCategory) {
      if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

      _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
        _suggestCategory(value, updateCategory);
      });
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              contentPadding: EdgeInsets.all(20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: Text(
                expenseId == null ? 'Add Expense' : 'Edit Expense',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.deepPurple),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description TextField

                    Text(
                      "Fill out the details below. We'll try to guess the category for you!",
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    SizedBox(height: 15),
                    TextField(
                      controller: descriptionController,
                      onChanged: (value) {
                        description = value;
                        setDialogState(() => descriptionError = value.isEmpty ? 'Description is required' : null);

                        _suggestCategoryWithDelay(value, (suggestedCategory) {
                          setDialogState(() {
                            category = suggestedCategory;
                          });
                        });
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
                    DropdownButtonFormField<String>(
                      value: categories.contains(category) ? category : 'Other',
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                      ),
                      items: [
                        ...categories.map((e) => DropdownMenuItem(value: e, child: Text(e))),
                        const DropdownMenuItem(value: 'custom', child: Text('Add New Category'))
                      ],
                      onChanged: (value) {
                        if (value == 'custom') {
                          setDialogState(() {
                            isAddingCustomCategory = true;
                            customCategoryError = null;
                          });
                        } else {
                          setDialogState(() {
                            category = value!;
                            isAddingCustomCategory = false;
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

                    // Custom Category TextField (only appears when 'Add New Category' is selected)
                    if (isAddingCustomCategory)
                      TextField(
                        controller: customCategoryController,
                        decoration: InputDecoration(
                          labelText: 'Enter New Category',
                          errorText: customCategoryError,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                        ),
                      ),
                    SizedBox(height: 20),

                    // Date Picker Button
                    TextButton(
                      onPressed: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
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
                    expenseId == null ? 'Add' : 'Save',
                    style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
                  ),
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
                      if (expenseId == null) {
                        _addExpense(docId, description, amount, category, selectedDate);
                      } else {
                        _editExpense(docId, expenseId, description, amount, category, selectedDate);
                      }
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

