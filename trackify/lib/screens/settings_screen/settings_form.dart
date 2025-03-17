import 'package:flutter/material.dart';
import 'package:trackify/models/user.dart';
import 'package:trackify/services/auth.dart';
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
  final AuthService _auth = AuthService();

  String? _currentName;
  String? _currentSugars;
  int? _currentStrength;
  String? _currentPassword;

  @override
  Widget build(BuildContext context) {
    final User? user = Provider.of<User?>(context);

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<UserData>(
        stream: DatabaseService(uid: user.uid).userData,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            UserData userData = snapshot.data!;

            return Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 20.0, right: 20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    const SizedBox(height: 20.0),
                    const Text(
                      'Update your profile settings',
                      style: TextStyle(
                        fontSize: 22.0, 
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                        ),
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: 30.0),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Name',
                        style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 5.0),
                    TextFormField(
                      initialValue: userData.name,
                      decoration: textInputDecoration,
                      validator: (val) => val!.isEmpty ? 'Please enter a name' : null,
                      onChanged: (val) => setState(() => _currentName = val),
                    ),
                    const SizedBox(height: 20.0),

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'New Password',
                        style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 5.0),
                    TextFormField(
                      decoration: textInputDecoration.copyWith(hintText: 'Enter new password'),
                      obscureText: true,
                      validator: (val) => val != null && val.length < 6 ? 'Password must be at least 6 characters' : null,
                      onChanged: (val) => setState(() => _currentPassword = val),
                    ),
                    const SizedBox(height: 20.0),

                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.pink[400]),
                      icon: const Icon(Icons.update, color: Colors.white),
                      label: const Text('Update', style: TextStyle(color: Colors.white)),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          await DatabaseService(uid: user.uid).updateUserData(
                              _currentSugars ?? userData.sugars,
                              _currentName ?? userData.name,
                              _currentStrength ?? userData.strength);

                          if (_currentPassword != null && _currentPassword!.isNotEmpty) {
                            try {
                              await _auth.updatePassword(_currentPassword!);
                            } catch (e) {
                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to update password: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }

                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile updated successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 20.0),

                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: const Icon(Icons.person, color: Colors.white),
                      label: const Text(
                        'Log Out',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        await _auth.signOut();
                      },
                    ),
                  ],
                ),
              ),
            );
          } else {
            return const Loading();
          }
        });
  }
}