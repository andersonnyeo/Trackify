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
          style: TextStyle(fontSize: 20.0 ,color: Colors.white, fontWeight: FontWeight.bold),
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
      : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (categorySpending.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Text(
                  "We have tailored these budget recommendation just for you! Curious how it works? Tap the '?' at the top right to learn more.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            
            Expanded(
              child: categorySpending.isEmpty
                  ? const Center(
                      child: Text(
                        "No expense available for Budget Recommendation.",
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      children: 
                      
                      categorySpending.keys.map((category) {
                        double spent = categorySpending[category]!;
                        double goal = budgetGoals[category] ?? _getRecommendedBudget(category, spent);
                        bool isOverBudget = spent > goal;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          color: isOverBudget ? Colors.red[100] : Colors.white,
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
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: isOverBudget ? Colors.red : Colors.green),
                              child: Text(
                                isOverBudget ? "Over Budget!" : "Set Goal",
                                style: const TextStyle(color: Colors.white),
                              ),
                              onPressed: () {
                                if (isOverBudget) {
                                  _showWarningDialog(category, spent, goal);
                                } else {
                                  _showBudgetDialog(category, spent);
                                }
                              },
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: const [
            Icon(Icons.info_outline, color: Colors.deepPurple),
            SizedBox(width: 8),
            Expanded(  // Use Expanded to prevent overflow
              child: Text(
                "Budget Recommendation Guide",
                style: TextStyle(fontSize:20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(  // Make the content scrollable
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,  // Set custom width, 80% of the screen width
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Here's how we recommend your budget based on your past spending:",
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 12),
                ListTile(
                  leading: Text("💸"),
                  title: Text(
                    "Spent over £500",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("Reduce budget by 20% to encourage savings."),
                ),
                ListTile(
                  leading: Text("📉"),
                  title: Text(
                    "Spent £200 - £500",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("Reduce budget by 10%."),
                ),
                ListTile(
                  leading: Text("✅"),
                  title: Text(
                    "Spent £50 - £200",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("Keep your budget as is."),
                ),
                ListTile(
                  leading: Text("📈"),
                  title: Text(
                    "Spent under £50",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("Slightly increase budget by 10% to avoid underspending."),
                ),
                SizedBox(height: 10),
                Text(
                  "💡 You can also manually adjust your budget by tapping the 'Set Goal' button next to each category.",
                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Got it!"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

}
