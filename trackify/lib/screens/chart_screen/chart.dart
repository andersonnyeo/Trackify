import 'package:flutter/material.dart';
import 'package:trackify/screens/chart_screen/chart_screen.dart';

class Chart extends StatelessWidget {
  final String docId;

  const Chart({super.key, required this.docId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Monthly Overview',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: Column(
            children: [
              
              const SizedBox(height: 10),
              Text(
                'The chart below shows your monthly expense overview, helping you visualize spending trends.',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                height: 500, // Set the desired height for the chart
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 20, 8, 8),
                  child: ChartScreen(docId: docId),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
