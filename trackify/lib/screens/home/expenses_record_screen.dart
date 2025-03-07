import 'package:flutter/material.dart';

class ExpenseRecordScreen extends StatefulWidget {
  const ExpenseRecordScreen({super.key});

  @override
  State<ExpenseRecordScreen> createState() => _ExpenseRecordScreenState();
}

class _ExpenseRecordScreenState extends State<ExpenseRecordScreen> {
  final List<Map<String, dynamic>> _documents = [];

  void _createNewDocument(String title) {
    setState(() {
      _documents.add({'title': title, 'expenses': []});
    });
  }

  void _addExpense(int docIndex, String description, double amount) {
    setState(() {
      _documents[docIndex]['expenses'].add({'description': description, 'amount': amount});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView.builder(
        itemCount: _documents.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              title: Text(_documents[index]['title']),
              trailing: IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showAddExpenseDialog(index),
              ),
              onTap: () => _showExpenseDetails(index),
            ),
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
        title: const Text('New Document'),
        content: TextField(
          onChanged: (value) => title = value,
          decoration: const InputDecoration(hintText: 'Document title'),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
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

  void _showAddExpenseDialog(int docIndex) {
    String description = '';
    double amount = 0.0;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              onChanged: (value) => description = value,
              decoration: const InputDecoration(hintText: 'Expense description'),
            ),
            TextField(
              onChanged: (value) => amount = double.tryParse(value) ?? 0.0,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Amount'),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Add'),
            onPressed: () {
              if (description.isNotEmpty && amount > 0) {
                _addExpense(docIndex, description, amount);
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showExpenseDetails(int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final expenses = _documents[index]['expenses'];
        return Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _documents[index]['title'],
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: expenses.isEmpty
                    ? const Center(child: Text('No expenses recorded'))
                    : ListView.builder(
                        itemCount: expenses.length,
                        itemBuilder: (context, i) => ListTile(
                          title: Text(expenses[i]['description']),
                          subtitle: Text('\$${expenses[i]['amount'].toStringAsFixed(2)}'),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
