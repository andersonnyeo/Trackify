
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:trackify/screens/FutureExpensesScreen/future_expenses_screen.dart';
import 'package:trackify/screens/chart_screen/chart.dart';
import 'package:trackify/screens/chart_screen/stats_screen.dart';

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
        backgroundColor: Colors.deepPurple,
        title: Text(title, 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<String>(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 8,
            color: Colors.white,
            offset: const Offset(0, 50),
            onSelected: (value) {
              if (value == 'Chart') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => Chart(docId: docId)),
                );
              } else if (value == 'Stats') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => StatsScreen(docId: docId)),
                );
              } else if (value == 'FutureExpenses') {
                // Navigate to the FutureExpensesScreen (create this screen if not yet implemented)
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FutureExpenseScreen(docId: docId)),
                );
              } else if (value == 'Delete') {
                _deleteExpenseDocument(context, firestore, uid, docId);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'Chart',
                child: Row(
                  children: [
                    Icon(Icons.pie_chart, color: Colors.blue),
                    SizedBox(width: 10),
                    Text('View Chart', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'Stats',
                child: Row(
                  children: [
                    Icon(Icons.bar_chart, color: Colors.green),
                    SizedBox(width: 10),
                    Text('View Stats', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
      const PopupMenuItem(
        value: 'FutureExpenses',
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.orange),
            SizedBox(width: 10),
            Text('View Future Expenses', style: TextStyle(fontSize: 16)),
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
              .doc(docId)
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
                  // mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 200),
                    Icon(Icons.receipt_long, size: 80, color: Colors.grey[500]),
                    const SizedBox(height: 20),
                    const Text(
                      "No expenses recorded yet.",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Tap the + button to add your first expense.",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

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

  void _deleteExpenseDocument(BuildContext context, FirebaseFirestore firestore, String uid, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Expense Document"),
        content: const Text("Are you sure you want to delete this expense document? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              firestore.collection('users').doc(uid).collection('expenseDocuments').doc(docId).delete();
              Navigator.pop(context);
              Navigator.pop(context); // Go back to the previous screen after deletion
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
