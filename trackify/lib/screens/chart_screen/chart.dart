import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String _uid;
  Map<int, double> monthlyTotals = {}; // Stores month index -> total amount
  List<int> displayedMonths = []; // Stores months that have data
  bool isLoading = true;
  bool hasData = false; // Flag to check if there is any data

  @override
  void initState() {
    super.initState();
    _uid = _auth.currentUser?.uid ?? '';
    
    if (_uid.isNotEmpty) {
      fetchMonthlyExpenses();
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchMonthlyExpenses() async {
    if (_uid.isEmpty) return;

    Map<int, double> tempData = {};

    // Get all expense documents for the current user
    QuerySnapshot expenseDocs = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('expenseDocuments')
        .get();

    for (var doc in expenseDocs.docs) {
      // Get expenses inside each document
      QuerySnapshot expenses = await doc.reference.collection('expenses').get();

      for (var expense in expenses.docs) {
        var data = expense.data() as Map<String, dynamic>;
        if (data.containsKey('amount') && data.containsKey('date')) {
          double amount = (data['amount'] as num).toDouble();
          DateTime date = (data['date'] as Timestamp).toDate();
          int monthIndex = date.month - 1; // Convert to 0-based index

          tempData[monthIndex] = (tempData[monthIndex] ?? 0) + amount;
        }
      }
    }

    setState(() {
      monthlyTotals = tempData;
      displayedMonths = monthlyTotals.keys.toList()..sort(); // Sort months
      hasData = monthlyTotals.isNotEmpty;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!hasData) {
      return const Center(
        child: Text(
          "No data available",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
      );
    }

    return BarChart(mainBarData());
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
