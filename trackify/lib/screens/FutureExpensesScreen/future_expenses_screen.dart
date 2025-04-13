import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ml_algo/ml_algo.dart';
// ignore: depend_on_referenced_packages
import 'package:ml_dataframe/ml_dataframe.dart';
import 'package:intl/intl.dart';

class FutureExpenseScreen extends StatefulWidget {
  final String docId;

  const FutureExpenseScreen({super.key, required this.docId});

  @override
  // ignore: library_private_types_in_public_api
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
        // print("No expenses data available.");
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

      if (historicalExpenses.length >= 2) {
        predictedExpense = await _predictWithMLModel(historicalExpenses);
      } else {
        predictedExpense =
            historicalExpenses.isNotEmpty ? historicalExpenses.last : null;
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // print("Error fetching historical data: $e");
    }
  }

  Future<double> _predictWithMLModel(List<double> data) async {
    final dataset = [
      ['month', 'amount'],
      for (int i = 0; i < data.length; i++) [i, data[i]],
    ];

    var df = DataFrame(dataset);
    final model = LinearRegressor(df, 'amount');

    final prediction =
        model.predict(DataFrame([['month'], [data.length]]));
    return prediction.rows.first.first as double;
  }

  Widget _buildLineChart() {
    double maxY = predictedExpense != null
        ? ([
              ...historicalExpenses,
              predictedExpense!
            ].reduce((a, b) => a > b ? a : b))
        : (historicalExpenses.isNotEmpty
            ? historicalExpenses.reduce((a, b) => a > b ? a : b)
            : 100);

    double roundedMaxY = (maxY / 10).ceil() * 10;

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: roundedMaxY,
        gridData: FlGridData(show: false),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
          tooltipRoundedRadius: 12,
          getTooltipColor: (touchedSpot) => Colors.deepPurple.shade100,
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots.map((spot) {
              return LineTooltipItem(
                '£${spot.y.toStringAsFixed(2)}',
                const TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              );
            }).toList();
          },
        ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            axisNameWidget: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text('Amount Spent (£)',
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ),
            axisNameSize: 26,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,
              interval: (roundedMaxY / 10),
              getTitlesWidget: (value, meta) {
                return Text(
                  '£${value.toInt()}',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text('Month',
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ),
            axisNameSize: 26,
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value % 1 != 0) return Container();

                int index = value.toInt();
                if (index < 0 || index >= sortedMonths.length + 1) return Container();

                if (index == sortedMonths.length) {
                  return Text(
                    "Next",
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }

                DateTime parsedDate = DateTime(
                  int.parse(sortedMonths[index].split('-')[0]),
                  int.parse(sortedMonths[index].split('-')[1]),
                  1,
                );

                return Text(
                  DateFormat.MMM().format(parsedDate),
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey, width: 1),
        ),
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
            LineChartBarData(
              spots: [
                FlSpot((historicalExpenses.length - 1).toDouble(),
                    historicalExpenses.last),
                FlSpot(historicalExpenses.length.toDouble(), predictedExpense!),
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
        iconTheme: const IconThemeData(color: Colors.white),
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
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          "Track your spending & preview next month with AI ",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Card(
                        elevation: 10,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(15.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Predicted Expense for Next Month",
                                  style: TextStyle(
                                      fontSize: 18,
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
                                      color: Colors.green)),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Card(
                        elevation: 10,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: SizedBox(
                            height: 430,
                            child: _buildLineChart(),
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
