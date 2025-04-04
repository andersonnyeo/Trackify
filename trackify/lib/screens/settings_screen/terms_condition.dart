import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.purple[50], 
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Privacy & Confidentiality',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your privacy is our top priority. This expense tracker ensures that all personal and financial data you provide is stored securely and is never shared with third parties.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),

              const Text(
                'Data Security',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'All expense records and personal details are encrypted and stored safely. No unauthorized access is allowed, and your data remains confidential at all times.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),

              const Text(
                'Usage Agreement',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'By using this app, you agree that your data will only be used for tracking your expenses and generating insights. We do not collect, store, or share any unnecessary personal information beyond what is required for app functionality.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),

              const Text(
                'Developer Commitment',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'This application was developed by a dedicated Computer Science student with the goal of providing users with a secure, intuitive, and efficient expense tracking solution. Your trust is valued, and all measures have been taken to ensure a safe user experience.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),

              // Center(
              //   child: ElevatedButton(
              //     onPressed: () => Navigator.pop(context),
              //     style: ElevatedButton.styleFrom(
              //       backgroundColor: Colors.deepPurple,
              //       padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              //     ),
              //     child: const Text(
              //       'Accept & Continue',
              //       style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
