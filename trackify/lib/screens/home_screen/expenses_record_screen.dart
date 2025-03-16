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

  void _addExpense(String docId, String description, double amount, String category, DateTime date) async {
    if (_uid.isNotEmpty) {
      await _firestore.collection('users').doc(_uid).collection('expenseDocuments').doc(docId).collection('expenses').add({
        'description': description,
        'amount': amount,
        'category': category,
        'date': Timestamp.fromDate(date),
      });
    }
  }

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
      appBar: AppBar(
        title: const Text(
          'Expense Records',
          )),
      body: _uid.isEmpty
    ? const Center(child: Text("Please log in to view expenses."))
    : StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').doc(_uid).collection('expenseDocuments').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                // mainAxisAlignment: MainAxisAlignment.center,
                children: [ 
                  const SizedBox(height: 150),
                  Icon(Icons.inbox, size: 80, color: Colors.grey[500]), 
                  const SizedBox(height: 20),
                  const Text(
                    "No expense documents available.",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Tap the + button below to add a new document.",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    title: Text(doc['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _showAddExpenseDialog(doc.id),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ExpenseDetailsScreen(docId: doc.id, title: doc['title']),
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

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Expense Document'),
        content: TextField(
          onChanged: (value) => title = value,
          decoration: const InputDecoration(hintText: 'Document title'),
        ),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
          TextButton(
            child: const Text('Create'),
            onPressed: () {
              if (title.isNotEmpty) {
                _createNewDocument(title);
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showAddExpenseDialog(String docId, {String? expenseId, String? existingDescription, double? existingAmount, String? existingCategory, DateTime? existingDate}) {
  String description = existingDescription ?? '';
  double amount = existingAmount ?? 0.0;
  String category = existingCategory ?? 'Food';
  DateTime selectedDate = existingDate ?? DateTime.now();
  List<String> categories = ['Food', 'Transport', 'Shopping', 'Bills', 'Other'];
  TextEditingController customCategoryController = TextEditingController();
  bool isAddingCustomCategory = false;

  void fetchCategories() async {
    var categoryDocs = await _firestore.collection('users').doc(_uid).collection('categories').get();
    categories.addAll(categoryDocs.docs.map((doc) => doc['name'].toString()));
  }

  fetchCategories();

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            contentPadding: EdgeInsets.all(20), // Add padding for spacing
            title: Text(expenseId == null ? 'Add Expense' : 'Edit Expense'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: TextEditingController(text: description),
                    onChanged: (value) => description = value,
                    decoration: InputDecoration(
                      labelText: 'Expense Description',
                      hintText: 'Enter a description of the expense',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: TextEditingController(text: amount > 0 ? amount.toString() : ''),
                    onChanged: (value) => amount = double.tryParse(value) ?? 0.0,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      hintText: 'Enter the amount spent',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                    ),
                  ),
                  SizedBox(height: 20),
                  // Category dropdown or custom input field
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                    ),
                    items: [
                      ...categories.map((e) => DropdownMenuItem(value: e, child: Text(e))),
                      const DropdownMenuItem(value: 'custom', child: Text('Add New Category'))
                    ],
                    onChanged: (value) {
                      if (value == 'custom') {
                        setDialogState(() => isAddingCustomCategory = true);
                      } else {
                        setDialogState(() => category = value!);
                      }
                    },
                  ),
                  SizedBox(height: 20),
                  if (isAddingCustomCategory)
                    TextField(
                      controller: customCategoryController,
                      decoration: InputDecoration(
                        labelText: 'Enter New Category',
                        hintText: 'Enter a new custom category',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                      ),
                    ),
                  SizedBox(height: 20),
                  // Date picker button
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
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
              TextButton(
                child: Text(expenseId == null ? 'Add' : 'Save'),
                onPressed: () async {
                  if (description.isNotEmpty && amount > 0) {
                    if (isAddingCustomCategory && customCategoryController.text.isNotEmpty) {
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
