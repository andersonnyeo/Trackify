import 'package:flutter/material.dart';
import 'package:trackify/screens/home/settings_form.dart';
import 'package:trackify/screens/home/trackify_list.dart';
import 'package:trackify/services/auth.dart';
import 'package:trackify/services/database.dart';
import 'package:provider/provider.dart';
import 'package:trackify/models/trackify.dart';

class Home extends StatelessWidget {
  Home({super.key});

  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {

    void _showSettingsPanel() {
      showModalBottomSheet(context: context, builder: (context){
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 60.0),
          child: const SettingsForm(),
        );
      });
    }

    return StreamProvider<List<Trackify>?>.value(
      value: DatabaseService(uid: "").trackify,
      initialData: null,
      catchError: (_, __) => null,
      child: Scaffold(
        backgroundColor: Colors.purple[50],
        appBar: AppBar(
          title: const Text('Trackify',
            style: TextStyle(
                color: Colors.white, 
                fontWeight: FontWeight.bold
                )
          ), 
          // centerTitle: true,
          backgroundColor: Colors.deepPurple,
          elevation: 0.0,
          
          actions: <Widget>[
            TextButton.icon(
              icon: const Icon(Icons.person, color: Colors.white),
              label: const Text('logout',
                style: TextStyle(
                  color: Colors.white, 
                  fontWeight: FontWeight.bold
                )
              ),
              onPressed: () async{
                await _auth.signOut();
              },
            ),
            TextButton.icon(
              icon: const Icon(Icons.settings, color: Colors.white),
              label: const Text('settings',
                style: TextStyle(
                  color: Colors.white, 
                  fontWeight: FontWeight.bold
                )
              ),
              onPressed: () => _showSettingsPanel(),
            )
          ],
        ),
        body: Container(
          // decoration: const BoxDecoration(
          //   image: DecorationImage(
          //     image: AssetImage('assets/coffee_bg.png'),
          //     fit: BoxFit.cover,
          //     )
          // ),
          child: const TrackifyList()
          ),
      ),
    );
  }
}