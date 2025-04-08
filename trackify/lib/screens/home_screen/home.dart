import 'package:flutter/material.dart';
import 'package:trackify/screens/home_screen/expenses_tab_screen.dart';
import 'package:trackify/screens/settings_screen/settings_form.dart';
import 'package:trackify/services/database.dart';
import 'package:provider/provider.dart';
import 'package:trackify/models/trackify.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const ExpenseRecordScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamProvider<List<Trackify>?>.value(
      value: DatabaseService(uid: "").trackify,
      initialData: null,
      catchError: (_, __) => null,
      child: Scaffold(
        backgroundColor: Colors.purple[50],

        // Appbar
        appBar: AppBar(
          title: const Text(
            'Trackify',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.deepPurple,
          elevation: 0.0,
        ),

        // body content
        body: _screens[_selectedIndex],

        // bottom Navigation Bar (Only Home & Settings)
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.deepPurple,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          iconSize: 25.0,
          selectedLabelStyle: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold), 
          unselectedLabelStyle: TextStyle(fontSize: 14.0), 
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
