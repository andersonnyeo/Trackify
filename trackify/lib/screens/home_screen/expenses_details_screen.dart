import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:trackify/screens/chart_screen/chart.dart';
import 'package:trackify/screens/chart_screen/stats.dart';

class ExpenseDetailsScreen extends StatelessWidget {
  final String docId;
  final String title;

  const ExpenseDetailsScreen({super.key, required this.docId, required this.title});

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'Chart') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => StatsScreen(docId: docId)), // Pass docId
                );
              } else if (value == 'Stats') {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (_) => ChartScreen(docId: docId)), // Pass docId
                // );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Chart', child: Text('Chart')),
              const PopupMenuItem(value: 'Stats', child: Text('Stats')),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('users')
            .doc(uid)
            .collection('expenseDocuments')
            .doc(docId)
            .collection('expenses')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final expenses = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              var expense = expenses[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 3,
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
                        '\$${expense['amount'].toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editExpense(context, firestore, uid, docId, expense),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteExpense(context, firestore, uid, docId, expense.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }



  void _editExpense(BuildContext context, FirebaseFirestore firestore, String uid, String docId, QueryDocumentSnapshot expense) {
    String description = expense['description'];
    double amount = expense['amount'];
    String category = expense['category'];
    DateTime selectedDate = (expense['date'] as Timestamp).toDate();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Expense'),
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
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid amount')));
                      return;
                    }

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
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteExpense(BuildContext context, FirebaseFirestore firestore, String uid, String docId, String expenseId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Expense"),
        content: const Text("Are you sure you want to delete this expense?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              firestore
                  .collection('users')
                  .doc(uid)
                  .collection('expenseDocuments')
                  .doc(docId)
                  .collection('expenses')
                  .doc(expenseId)
                  .delete();

              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
