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
      appBar: AppBar(title: const Text('Expense Records')),
      body: _uid.isEmpty
          ? const Center(child: Text("Please log in to view expenses."))
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').doc(_uid).collection('expenseDocuments').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final documents = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    var doc = documents[index];

                    return Dismissible(
                      key: Key(doc.id), // Unique key for each item
                      direction: DismissDirection.endToStart, // Swipe left to delete
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

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(expenseId == null ? 'Add Expense' : 'Edit Expense'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: TextEditingController(text: description),
                    onChanged: (value) => description = value,
                    decoration: const InputDecoration(hintText: 'Expense description'),
                  ),
                  TextField(
                    controller: TextEditingController(text: amount > 0 ? amount.toString() : ''),
                    onChanged: (value) => amount = double.tryParse(value) ?? 0.0,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'Amount'),
                  ),
                  DropdownButton<String>(
                    value: category,
                    items: ['Food', 'Transport', 'Shopping', 'Bills', 'Other']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) => setDialogState(() => category = value!),
                  ),
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
                    child: Text('Select Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}'),
                  ),
                ],
              ),
              actions: [
                TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
                TextButton(
                  child: Text(expenseId == null ? 'Add' : 'Save'),
                  onPressed: () {
                    if (description.isNotEmpty && amount > 0) {
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
