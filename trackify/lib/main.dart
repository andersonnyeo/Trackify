import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:trackify/screens/wrapper.dart';
import 'package:trackify/services/auth.dart';
import 'package:trackify/models/user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures Flutter is ready
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamProvider<User?>(
      create: (context) => AuthService().user,
      initialData: null, // Set an initial value
      child: const MaterialApp(
        home: Wrapper(),
      ),
    );
  }
}
