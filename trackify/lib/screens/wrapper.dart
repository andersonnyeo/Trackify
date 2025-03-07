import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trackify/models/user.dart';
import 'package:trackify/screens/home/home.dart';
import 'package:trackify/screens/home/settings_form.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  _WrapperState createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  int _selectedIndex = 0; // Ensure it starts within valid range

  // List of screens (Only Home and Settings)
  final List<Widget> _pages = [
    Home(),
    SettingsForm(),
  ];

  void _onItemTapped(int index) {
    if (index >= 0 && index < _pages.length) { // Ensure index is valid
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }
}
