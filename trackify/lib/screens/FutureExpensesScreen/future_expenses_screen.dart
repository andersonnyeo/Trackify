import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ml_algo/ml_algo.dart';
import 'package:ml_dataframe/ml_dataframe.dart';
import 'package:intl/intl.dart';

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
      DateTime currentDate = DateTime.now();
      String currentMonthKey = "${currentDate.year}-${currentDate.month}";

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
        if (doc['date'] == null || doc['amount'] == null) continue;
        DateTime date = (doc['date'] as Timestamp).toDate();

        String monthKey = "${date.year}-${date.month}";

        monthlyExpenses[monthKey] =
            (monthlyExpenses[monthKey] ?? 0) + (doc['amount'] as num).toDouble();
      }

      sortedMonths = monthlyExpenses.keys.toList()..sort();
      if (sortedMonths.isEmpty || sortedMonths.last != currentMonthKey) {
        sortedMonths.add(currentMonthKey);
      }

      historicalExpenses =
          sortedMonths.map((month) => monthlyExpenses[month] ?? 0).toList();

      // 🔹 Keep the last 3 months, or less if there are not enough months
      int monthCount = historicalExpenses.length;
      if (monthCount > 3) {
        historicalExpenses = historicalExpenses.sublist(monthCount - 3);
        sortedMonths = sortedMonths.sublist(monthCount - 3);
      } else if (monthCount == 2) {
        historicalExpenses = historicalExpenses.sublist(monthCount - 2);
        sortedMonths = sortedMonths.sublist(monthCount - 2);
      } else if (monthCount == 1) {
        historicalExpenses = historicalExpenses.sublist(monthCount - 1);
        sortedMonths = sortedMonths.sublist(monthCount - 1);
      }

      // Now make prediction based on the available months
      if (historicalExpenses.length >= 2) {
        predictedExpense = await _predictWithMLModel(historicalExpenses);
      } else {
        predictedExpense = historicalExpenses.isNotEmpty ? historicalExpenses.last : null;
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

  // Use ML model (Linear Regression) to predict next month's expense
  Future<double> _predictWithMLModel(List<double> data) async {
    // Prepare data for training
    final dataset = [
      ['month', 'amount'],
      for (int i = 0; i < data.length; i++) [i, data[i]],  // Using 0-based month index
    ];


    var df = DataFrame(dataset);

    // Train the Linear Regression model
    final model = LinearRegressor(df, 'amount');

    // Predict the next month's expense (next month is just the data length + 1)
    final prediction = model.predict(DataFrame([['month'], [data.length + 1]]));
    return prediction.rows.first.first as double;
  }

  Widget _buildLineChart() {
    return Expanded(
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
                sideTitles:
                    SideTitles(showTitles: true, reservedSize: 40)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index < 0 || index >= sortedMonths.length) return Container();
              
                // Convert sortedMonths to month names safely
                if (index < sortedMonths.length) {
                  DateTime parsedDate = DateTime(
                    int.parse(sortedMonths[index].split('-')[0]),  // Year
                    int.parse(sortedMonths[index].split('-')[1]),  // Month
                    1
                  );
                  return Text(
                    DateFormat.MMM().format(parsedDate),
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  );
                } else {
                  return Text("Next", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold));
                }
              }
              
              ),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false), // Hide the top x-axis labels
            ),
          ),
          borderData: FlBorderData(
              show: true, border: Border.all(color: Colors.grey, width: 1)),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                historicalExpenses.length,
                (index) =>
                    FlSpot(index.toDouble(), historicalExpenses[index]),
              ),
              isCurved: true,
              color: Colors.deepPurpleAccent,
              barWidth: 4,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
            if (predictedExpense != null)

            // LineChartBarData(
            //     spots: [
            //       FlSpot(historicalExpenses.length.toDouble(),
            //           predictedExpense!),
            //     ],
            //     isCurved: true,
            //     color: Colors.red,
            //     barWidth: 4,
            //     dotData: FlDotData(show: true),
            //     belowBarData: BarAreaData(show: false),
            //     dashArray: [5, 5],
            //   ),
              LineChartBarData(
                spots: [
                  for (int i = 0; i < historicalExpenses.length; i++)
                    FlSpot(i.toDouble(), historicalExpenses[i]),
                  FlSpot(historicalExpenses.length.toDouble(), predictedExpense!),  // Ensure continuity
                ],
                isCurved: true,
                color: Colors.red,
                barWidth: 4,
                dotData: FlDotData(show: true),
                belowBarData: BarAreaData(show: false),
                dashArray: [5, 5],
              ),

          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple[50],
      appBar: AppBar(
        title: const Text('Future Expense Predictions',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), // Set back arrow color to white
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : historicalExpenses.isEmpty
                ? const Center(
                    child: Text("No expenses available for prediction.",
                        style: TextStyle(
                            fontSize: 18, color: Colors.grey)))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        elevation: 10,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Predicted Expense for Next Month",
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple)),
                              SizedBox(height: 10),
                              Text(
                                  predictedExpense != null
                                      ? "£${predictedExpense!.toStringAsFixed(2)}"
                                      : "Not enough data",
                                  style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurpleAccent)),
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
