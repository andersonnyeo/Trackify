import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class StatsScreen extends StatelessWidget {
  final String docId;

  const StatsScreen({Key? key, required this.docId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.purple[50],
      appBar: AppBar(
        title: const Text(
          'Category Breakdown',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        child: StreamBuilder<QuerySnapshot>(
          stream: firestore
              .collection('users')
              .doc(uid)
              .collection('expenseDocuments')
              .doc(docId)
              .collection('expenses')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'No expenses available for\n Category Breakdown.',
                  style: TextStyle(color: Colors.grey, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              );
            }

            final expenses = snapshot.data!.docs;

            final Map<String, double> categoryTotals = {};
            double totalAmount = 0.0;

            for (var doc in expenses) {
              final amount = (doc['amount'] as num).toDouble();
              final category = doc['category'] ?? 'Others';
              categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
              totalAmount += amount;
            }

            final List<PieChartSectionData> sections = categoryTotals.entries.map((entry) {
              final percentage = totalAmount == 0 ? 0 : (entry.value / totalAmount * 100).round();

              return PieChartSectionData(
                value: entry.value,
                // title: '${entry.key}\n$percentage%',
                title: '$percentage%',
                color: Colors.primaries[entry.key.hashCode % Colors.primaries.length], // Dynamic colors
                radius: 70,
                titleStyle: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black26, offset: Offset(1, 1), blurRadius: 3)], // Add shadow
              ),
              );
            }).toList();

            return Column(
              children: [
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'This chart shows your overall spending breakdown.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      height: 220,
                      child: PieChart(
                        PieChartData(
                          sections: sections,
                          centerSpaceRadius: 50,
                          sectionsSpace: 2,
                          borderData: FlBorderData(show: false),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    children: categoryTotals.entries.map((entry) {
                      final percentage = totalAmount == 0 ? 0 : (entry.value / totalAmount * 100).round();

                      return Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.primaries[entry.key.hashCode % Colors.primaries.length].withOpacity(0.7),
                            child: const Icon(Icons.pie_chart, color: Colors.white),
                          ),
                          title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('£${entry.value.toStringAsFixed(2)} ($percentage%)'),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
