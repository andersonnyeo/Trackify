import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ml_algo/ml_algo.dart';
import 'package:ml_dataframe/ml_dataframe.dart';

class FutureExpenseScreen extends StatefulWidget {
  final String docId;

  const FutureExpenseScreen({Key? key, required this.docId}) : super(key: key);

  @override
  _FutureExpenseScreenState createState() => _FutureExpenseScreenState();
}

class _FutureExpenseScreenState extends State<FutureExpenseScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<double> historicalExpenses = [];
  List<String> sortedMonths = [];
  double? predictedExpense;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistoricalExpenses();
  }

  Future<void> _fetchHistoricalExpenses() async {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('expenseDocuments')
          .doc(widget.docId)
          .collection('expenses')
          .orderBy('date', descending: false)
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          isLoading = false;
        });
        print("No expenses data available.");
        return;
      }

      Map<String, double> monthlyExpenses = {};
      for (var doc in snapshot.docs) {
        DateTime date = (doc['date'] as Timestamp).toDate();
        String monthKey = "${date.year}-${date.month}";
        monthlyExpenses[monthKey] = (monthlyExpenses[monthKey] ?? 0) + (doc['amount'] as num).toDouble();
      }

      sortedMonths = monthlyExpenses.keys.toList()..sort();
      if (sortedMonths.length > 2) {
        sortedMonths = sortedMonths.sublist(sortedMonths.length - 3);
      }
      historicalExpenses = sortedMonths.map((month) => monthlyExpenses[month]!).toList();

      if (historicalExpenses.length >= 2) {
        predictedExpense = _predictNextMonthExpense(historicalExpenses);
      } else {
        predictedExpense = null;
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching historical data: $e");
    }
  }

  double _predictNextMonthExpense(List<double> data) {
    if (data.length < 2) {
      return 0;
    }

    final dataset = [
      ['month', 'amount'],
      for (int i = 0; i < data.length; i++) [i + 1, data[i]],
    ];

    var df = DataFrame(dataset);
    final model = LinearRegressor(df, 'amount');
    final prediction = model.predict(DataFrame([['month'], [data.length + 1]]));
    return prediction.rows.first.first as double;
  }

  Widget _buildLineChart() {
    return Expanded(
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index < 0 || index >= sortedMonths.length) return Container();
                  return Text(sortedMonths[index], style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold));
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey, width: 1)),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                historicalExpenses.length,
                (index) => FlSpot(index.toDouble(), historicalExpenses[index]),
              ),
              isCurved: true,
              color: Colors.deepPurpleAccent,
              barWidth: 4,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Future Expense Predictions', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : historicalExpenses.isEmpty
                ? const Center(child: Text("No expenses available for prediction.", style: TextStyle(fontSize: 18, color: Colors.grey)))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        elevation: 10,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Predicted Expense for Next Month",
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                              ),
                              SizedBox(height: 10),
                              Text(
                                predictedExpense != null
                                    ? "\$${predictedExpense!.toStringAsFixed(2)}"
                                    : "Not enough data",
                                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 30),
                      _buildLineChart(),
                    ],
                  ),
      ),
    );
  }
}
