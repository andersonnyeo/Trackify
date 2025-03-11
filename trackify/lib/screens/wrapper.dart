import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trackify/screens/authenticate/authenticate.dart';
import 'package:trackify/models/user.dart';
import 'package:trackify/screens/home/home.dart';
// import 'package:trackify/screens/home/views/home_screen.dart';


class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {

    final User? user = Provider.of<User?>(context); // Allow nullable User
    


    // return either Home or Authenticate widget
    if (user == null) {
      return const Authenticate();
    } else {
      return Home();
    }
  }
}