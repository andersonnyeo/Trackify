import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.purple[50],
      body: SafeArea(
        child: Padding(
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
                  'Your privacy is our top priority. This expense tracker ensures that all personal and financial data you provide is stored securely and is never shared with third parties. '
                  'We do not engage in any form of data selling, advertising, or unauthorized analytics tracking. All inputs you provide remain confidential and are strictly used to enhance your personal expense tracking experience.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Data Security',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'All expense records and personal details are encrypted using industry-standard methods and stored safely in a cloud database. Access to this data is protected by secure authentication methods. '
                  'The app is continuously updated to fix vulnerabilities and improve protection mechanisms. No third-party services are allowed to access or process your information.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Usage Agreement',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'By using this app, you agree that your data will be used solely for the purpose of tracking your personal expenses, generating spending insights, and providing budgeting support. '
                  'You understand that misuse of the application, such as inputting false data or attempting to breach app security, is strictly prohibited. Your continued use of the app implies acceptance of any future changes to these terms.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),

                const Text(
                  'User Responsibilities',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Users are responsible for keeping their login credentials secure and for ensuring the accuracy of the data they enter. Any loss resulting from the sharing of login details or intentional misuse of app features is the sole responsibility of the user.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Developer Commitment',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'This application was developed by a passionate Computer Science student aiming to provide a reliable, transparent, and privacy-focused expense tracking solution. Feedback is welcome to help improve the app and ensure it continues to meet user needs.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
