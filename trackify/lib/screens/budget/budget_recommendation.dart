import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BudgetRecommendationScreen extends StatefulWidget {
  final String docId;

  const BudgetRecommendationScreen({super.key, required this.docId});

  @override
  _BudgetRecommendationScreenState createState() => _BudgetRecommendationScreenState();
}

class _BudgetRecommendationScreenState extends State<BudgetRecommendationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  Map<String, double> categorySpending = {};
  Map<String, double> budgetGoals = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchExpenseData();
  }

  Future<void> _fetchExpenseData() async {
    QuerySnapshot expensesSnapshot = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('expenseDocuments')
        .doc(widget.docId)
        .collection('expenses')
        .get();
  
    Map<String, double> tempCategorySpending = {};
    Map<String, double> tempBudgetGoals = {};
  
    // Fetch spending data
    for (var doc in expensesSnapshot.docs) {
      String category = doc['category'];
      double amount = (doc['amount'] as num).toDouble();
  
      tempCategorySpending[category] = (tempCategorySpending[category] ?? 0) + amount;
    }
  
    // Fetch budget goals for this specific document
    QuerySnapshot budgetSnapshot = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('expenseDocuments')
        .doc(widget.docId) // Load from the specific document
        .collection('budgetGoals')
        .get();
  
    for (var doc in budgetSnapshot.docs) {
      tempBudgetGoals[doc.id] = (doc['goal'] as num).toDouble();
    }
  
    setState(() {
      categorySpending = tempCategorySpending;
      budgetGoals = tempBudgetGoals; // Store document-specific budget goals
      isLoading = false;
    });
  }

  void _setBudgetGoal(String category, double goal) async {
    setState(() {
      budgetGoals[category] = goal;
    });

    // Store the budget goal inside the specific expense document
    await _firestore
        .collection('users')
        .doc(_uid)
        .collection('expenseDocuments')
        .doc(widget.docId) // Save budget goal under the specific expense document
        .collection('budgetGoals') // Separate collection for budget goals per document
        .doc(category)
        .set({'goal': goal});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple[50],
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text(
          "Budget Recommendations",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              _showBudgetExplanationDialog();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : categorySpending.isEmpty
              ? const Center(child: Text("No expense available for Budget Recommendation.",
              style: TextStyle(fontSize: 18, color: Colors.grey),
              textAlign: TextAlign.center,
              ))
              : ListView(
                  padding: const EdgeInsets.all(15),
                  children: categorySpending.keys.map((category) {
                    double spent = categorySpending[category]!; 
                    double goal = budgetGoals[category] ?? _getRecommendedBudget(category, spent);
                    bool isOverBudget = spent > goal;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      color: isOverBudget ? Colors.red[100] : Colors.white, // Highlight overspending
                      child: ListTile(
                        title: Text(
                          category, 
                          style: TextStyle(fontWeight: FontWeight.bold, color: isOverBudget ? Colors.red : Colors.black),
                        ),
                        subtitle: Text(
                          "Spent: £${spent.toStringAsFixed(2)}\nRecommended Budget: £${goal.toStringAsFixed(2)}",
                          style: TextStyle(color: isOverBudget ? Colors.red[800] : Colors.black),
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: isOverBudget ? Colors.red : Colors.green),
                          child: Text(
                            isOverBudget ? "Over Budget!" : "Set Goal",
                            style: const TextStyle(color: Colors.white),
                          ),
                          onPressed: () {
                            if (isOverBudget) {
                              _showWarningDialog(category, spent, goal); // Show warning if over budget
                            } else {
                              _showBudgetDialog(category, spent);
                            }
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
    );
  }

  void _showWarningDialog(String category, double spent, double goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("⚠ Over Budget for $category"),
        content: Text(
          "You have spent £${spent.toStringAsFixed(2)} in $category, exceeding the recommended budget of £${goal.toStringAsFixed(2)}.\n\n"
          "Consider reducing your spending or setting a stricter budget goal.",
          style: TextStyle(color: Colors.red[800]),
        ),
        actions: [
          TextButton(child: const Text("Close"), onPressed: () => Navigator.pop(context)),
          TextButton(
            child: const Text("Set New Goal"),
            onPressed: () {
              Navigator.pop(context);
              _showBudgetDialog(category, spent);
            },
          ),
        ],
      ),
    );
  }

  double _getRecommendedBudget(String category, double spent) {
    // Base rule: Start with past spending
    double recommendedBudget = spent;

    if (spent > 500) {
      // If spending is high, reduce budget by 20% to encourage savings
      recommendedBudget *= 0.8;
    } else if (spent >= 200) {
      // If spending is moderate, reduce budget by 10%
      recommendedBudget *= 0.9;
    } else if (spent >= 50) {
      // If spending is low, maintain budget (100%)
      recommendedBudget = spent;
    } else {
      // If spending is very low (< £50), allow a 10% increase
      recommendedBudget *= 1.1;
    }

    return recommendedBudget;
  }

  void _showBudgetDialog(String category, double spent) {
    // Correctly set the initial budget value
    double initialGoal = budgetGoals[category] ?? _getRecommendedBudget(category, spent);

    TextEditingController budgetController =
        TextEditingController(text: initialGoal.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Set Budget for $category"),
        content: TextField(
          controller: budgetController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Enter your budget goal"),
        ),
        actions: [
          TextButton(child: const Text("Cancel"), onPressed: () => Navigator.pop(context)),
          TextButton(
            child: const Text("Save"),
            onPressed: () {
              double? goal = double.tryParse(budgetController.text);
              if (goal != null && goal > 0) {
                _setBudgetGoal(category, goal);
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }


  // Show explanation about how budget recommendations are calculated
  void _showBudgetExplanationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("How Budget Recommendations Are Made"),
        content: const Text(
          "Our budget recommendations are based on your past spending behavior:\n\n"
          "- If you've spent a lot in a category (e.g., over £500), we suggest reducing your budget by 20% to encourage savings.\n"
          "- For moderate spending (e.g., between £200-£500), we suggest reducing your budget by 10%.\n"
          "- For low spending (e.g., less than £200), we recommend maintaining your current budget.\n"
          "- If your spending is very low (e.g., under £50), we allow a 10% increase to help you avoid underspending.\n\n"
          "You can also set your own budget goal for each category by clicking 'Set Goal' next to each category.",
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          TextButton(
            child: const Text("Close"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
