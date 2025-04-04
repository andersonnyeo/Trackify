import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ChartScreen extends StatefulWidget {
  final String docId;

  const ChartScreen({super.key, required this.docId});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String _uid;
  Map<int, double> monthlyTotals = {};
  List<int> displayedMonths = [];

  @override
  void initState() {
    super.initState();
    _uid = _auth.currentUser?.uid ?? '';
  }

  Stream<Map<int, double>> getExpenseStream() {
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('expenseDocuments')
        .doc(widget.docId)
        .collection('expenses')
        .snapshots()
        .map((expenses) {
      Map<int, double> tempData = {};

      for (var expense in expenses.docs) {
        var data = expense.data();
        if (data.containsKey('amount') && data.containsKey('date')) {
          double amount = (data['amount'] as num).toDouble();
          DateTime date = (data['date'] as Timestamp).toDate();
          int monthIndex = date.month - 1;

          tempData[monthIndex] = (tempData[monthIndex] ?? 0) + amount;
        }
      }

      return tempData;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<int, double>>(
      stream: getExpenseStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        monthlyTotals = snapshot.data!;
        displayedMonths = monthlyTotals.keys.toList()..sort();

        if (monthlyTotals.isEmpty) {
          return const Center(
            child: Text(
              "No expenses available for Monthly Overview.",
              style: TextStyle(fontSize: 18, color: Colors.grey, ),
              textAlign: TextAlign.center,
            ),
          );
        }

        return BarChart(mainBarData());
      },
    );
  }

  BarChartGroupData makeGroupData(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
            transform: const GradientRotation(pi / 4),
          ),
          width: 20,
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: monthlyTotals.values.isNotEmpty ? monthlyTotals.values.reduce(max) : 0,
            color: Colors.grey.shade300,
          ),
        )
      ],
    );
  }

  List<BarChartGroupData> showingGroups() {
    return displayedMonths
        .map((monthIndex) => makeGroupData(monthIndex, monthlyTotals[monthIndex]!))
        .toList();
  }

  BarChartData mainBarData() {
    return BarChartData(
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 38,
            getTitlesWidget: getMonthTitle,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: getLeftTitles,
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      gridData: const FlGridData(show: false),
      barGroups: showingGroups(),
    );
  }

  Widget getMonthTitle(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.grey,
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );

    List<String> monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    int index = value.toInt();

    String text = displayedMonths.contains(index) ? monthNames[index] : '';

    return SideTitleWidget(meta: meta, space: 8, child: Text(text, style: style));
  }

  Widget getLeftTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.grey,
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );

    if (value == 0) return const SizedBox.shrink();

    String text = value >= 1000
        ? '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}K'
        : value.toStringAsFixed(0);

    return SideTitleWidget(meta: meta, space: 4, child: Text(text, style: style));
  }
}