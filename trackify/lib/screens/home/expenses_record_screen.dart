  import 'package:flutter/material.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:intl/intl.dart';

  class ExpenseRecordScreen extends StatefulWidget {
    const ExpenseRecordScreen({super.key});

    @override
    State<ExpenseRecordScreen> createState() => _ExpenseRecordScreenState();
  }

  class _ExpenseRecordScreenState extends State<ExpenseRecordScreen> {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    void _createNewDocument(String title) async {
      await _firestore.collection('expenseDocuments').add({
        'title': title,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    void _addExpense(String docId, String description, double amount, String category, DateTime date) async {
      await _firestore.collection('expenseDocuments').doc(docId).collection('expenses').add({
        'description': description,
        'amount': amount,
        'category': category,
        'date': date,
      });
    }

    void _editExpense(String docId, String expenseId, String description, double amount, String category, DateTime date) async {
      await _firestore.collection('expenseDocuments').doc(docId).collection('expenses').doc(expenseId).update({
        'description': description,
        'amount': amount,
        'category': category,
        'date': date,
      });
    }

    void _deleteExpense(String docId, String expenseId) async {
      await _firestore.collection('expenseDocuments').doc(docId).collection('expenses').doc(expenseId).delete();
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: const Text('Expense Records')),
        body: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('expenseDocuments').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

            final documents = snapshot.data!.docs;

            return ListView.builder(
              itemCount: documents.length,
              itemBuilder: (context, index) {
                var doc = documents[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.all(10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    title: Text(doc['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _showAddExpenseDialog(doc.id),
                    ),
                    onTap: () => _showExpenseDetails(doc.id, doc['title']),
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.deepPurple,
          child: const Icon(Icons.add),
          onPressed: () => _showNewDocumentDialog(),
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
        builder: (context) => AlertDialog(
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
                onChanged: (value) => setState(() => category = value!),
              ),
              TextButton(
                onPressed: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) setState(() => selectedDate = pickedDate);
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
        ),
      );
    }

    void _showExpenseDetails(String docId, String title) {
      showModalBottomSheet(
        context: context,
        builder: (context) {
          return StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('expenseDocuments').doc(docId).collection('expenses').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final expenses = snapshot.data!.docs;
              double totalAmount = expenses.fold(0.0, (sum, doc) => sum + (doc['amount'] as double));

              return Container(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text('Total: \$${totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: expenses.length,
                        itemBuilder: (context, i) {
                          var expense = expenses[i];
                          return Dismissible(
                            key: Key(expense.id),
                            background: Container(color: Colors.red, child: const Icon(Icons.delete, color: Colors.white)),
                            onDismissed: (_) => _deleteExpense(docId, expense.id),
                            child: ListTile(
                              title: Text(expense['description']),
                              subtitle: Text('${expense['category']} - \$${expense['amount'].toStringAsFixed(2)}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showAddExpenseDialog(
                                  docId,
                                  expenseId: expense.id,
                                  existingDescription: expense['description'],
                                  existingAmount: expense['amount'],
                                  existingCategory: expense['category'],
                                  existingDate: (expense['date'] as Timestamp).toDate(),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    }
  }
