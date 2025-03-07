import 'package:flutter/material.dart';
import 'package:trackify/models/user.dart';
import 'package:trackify/screens/home/home.dart';
import 'package:trackify/services/database.dart';
import 'package:trackify/shared/constants.dart';
import 'package:provider/provider.dart';
import 'package:trackify/shared/loading.dart';

class SettingsForm extends StatefulWidget {
  const SettingsForm({super.key});

  @override
  State<SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends State<SettingsForm> {
  final _formKey = GlobalKey<FormState>();
  final List<String> sugars = ['0', '1', '2', '3', '4'];

  String? _currentName;
  String? _currentSugars;
  int? _currentStrength;

  @override
  Widget build(BuildContext context) {
    final User? user = Provider.of<User?>(context); // Allow nullable User

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings",  
            style: TextStyle(
                color: Colors.white, 
                fontWeight: FontWeight.bold
                )
        ),
        backgroundColor: Colors.deepPurple, // AppBar color
      ),
      backgroundColor: Colors.purple[50], // Background color for the page
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<UserData>(
          stream: DatabaseService(uid: user.uid).userData,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              UserData userData = snapshot.data!;

              return Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    const Text(
                      'Update your trackify settings',
                      style: TextStyle(
                        fontSize: 18.0, 
                        // color: Colors.white
                        ), // Text color changed for visibility
                    ),
                    const SizedBox(height: 20.0),
                    TextFormField(
                      initialValue: userData.name,
                      decoration: textInputDecoration.copyWith(
                        fillColor: Colors.white, // Input field background
                        filled: true,
                      ),
                      validator: (val) => val!.isEmpty ? 'Please enter a name' : null,
                      onChanged: (val) => setState(() => _currentName = val),
                    ),
                    const SizedBox(height: 20.0),

                    // Dropdown
                    DropdownButtonFormField(
                      decoration: textInputDecoration.copyWith(
                        fillColor: Colors.white, 
                        filled: true,
                      ),
                      value: _currentSugars ?? userData.sugars,
                      items: sugars.map((sugar) {
                        return DropdownMenuItem(
                          value: sugar,
                          child: Text('$sugar sugars'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _currentSugars = val);
                      },
                    ),

                    // Slider
                    Slider(
                      value: (_currentStrength ?? userData.strength).toDouble(),
                      activeColor: Colors.brown[_currentStrength ?? userData.strength],
                      inactiveColor: Colors.brown[_currentStrength ?? userData.strength],
                      min: 100.0,
                      max: 900.0,
                      divisions: 8,
                      onChanged: (val) => setState(() => _currentStrength = val.round()),
                    ),

                    // Submit Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink[400], // Button color
                      ),
                      child: const Text(
                        'Update',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          await DatabaseService(uid: user.uid).updateUserData(
                            _currentSugars ?? userData.sugars,
                            _currentName ?? userData.name,
                            _currentStrength ?? userData.strength,
                          );
                          // Navigator.pushReplacementNamed(context, '/home');
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Home(),
                          ),
                        );

                        }
                      },
                    )
                  ],
                ),
              );
            } else {
              return const Loading();
            }
          },
        ),
      ),
    );
  }
}
