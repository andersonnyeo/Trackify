
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:trackify/screens/FutureExpensesScreen/future_expenses_screen.dart';
import 'package:trackify/screens/chart_screen/chart.dart';
import 'package:trackify/screens/chart_screen/stats_screen.dart';
import 'package:trackify/screens/budget/budget_recommendation.dart';

class ExpenseDetailsScreen extends StatelessWidget {
  final String docId;
  final String title;

  const ExpenseDetailsScreen({super.key, required this.docId, required this.title});

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.purple[50],
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Text(title, 
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
              if (value == 'Monthly Overview') {
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FutureExpenseScreen(docId: docId)),
                );
              } else if (value == 'Budget') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => BudgetRecommendationScreen(docId: docId)),
                );
              } else if (value == 'Delete') {
                _deleteExpenseDocument(context, firestore, uid, docId);
              }
            },
            itemBuilder: (context) => [
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
                    Text('Spending Insights', style: TextStyle(fontSize: 16)),
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
                            return await _showDeleteConfirmationDialog(context, expense.id);
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
                                    onPressed: () => _editExpense(context, firestore, uid, docId, expense),
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
    );
  }

  Future<bool?> _showDeleteConfirmationDialog(BuildContext context, String docId) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense Detail'),
        content: const Text('Are you sure you want to delete this expense?'),
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

  void _deleteExpenseDetails(String expenseId) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (uid.isNotEmpty) {
      await firestore
          .collection('users')
          .doc(uid)
          .collection('expenseDocuments')
          .doc(docId) // Use the document ID from the parent screen
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
    // List<String> categories = ['Food', 'Transport', 'Shopping', 'Groceries', 'Entertainment', 'Other'];
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
                      controller: TextEditingController(text: description),
                      onChanged: (value) => description = value,
                      decoration: InputDecoration(
                        labelText: 'Expense Description',
                        labelStyle: TextStyle(color: Colors.deepPurple),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.deepPurple),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                      ),
                    ),
                    SizedBox(height: 20),
                    // Amount TextField
                    TextField(
                      controller: TextEditingController(text: amount > 0 ? amount.toString() : ''),
                      onChanged: (value) => amount = double.tryParse(value) ?? 0.0,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        hintText: 'Enter the amount spent',
                        hintStyle: TextStyle(color: Colors.grey),
                        labelStyle: TextStyle(color: Colors.deepPurple),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.deepPurple),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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
                    
                        List<String> categories = ['Food', 'Transport', 'Shopping', 'Groceries', 'Entertainment', 'Other'];
                    
                        // Add Firebase categories to the list
                        snapshot.data?.docs.forEach((doc) {
                          categories.add(doc['name']);
                        });
                    
                        return DropdownButtonFormField<String>(
                          value: categories.contains(category) ? category : null,
                          decoration: InputDecoration(
                            labelText: 'Category',
                            labelStyle: TextStyle(color: Colors.deepPurple),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.deepPurple),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                          ),
                          items: [
                            ...categories.map((e) => DropdownMenuItem(value: e, child: Text(e))),
                          ],
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
                          lastDate: DateTime(2101),
                        );
                        if (pickedDate != null) setDialogState(() => selectedDate = pickedDate);
                      },
                      child: Text(
                        'Select Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                        style: TextStyle(fontSize: 16, color: Colors.deepPurple),
                      ),
                    ),
                    SizedBox(height: 10),

                    Center(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.pink[400]),
                        
                        icon: const Icon(Icons.delete, color: Colors.white),
                        label: const Text('Delete', style: TextStyle(color: Colors.white)),
                        onPressed: () => _deleteExpenseWhenEdit(context, firestore, uid, docId, expense.id),
                        
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
                ),
              ],
            );
          },
        );
      },
    );
  }   


   void _deleteExpenseWhenEdit(BuildContext context, FirebaseFirestore firestore, String uid, String docId, String expenseId) {
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
