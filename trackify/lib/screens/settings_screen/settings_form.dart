import 'package:flutter/material.dart';
import 'package:trackify/models/user.dart';
import 'package:trackify/screens/settings_screen/terms_condition.dart';
import 'package:trackify/services/auth.dart';
import 'package:trackify/services/database.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _auth = AuthService();

  void _showChangeNameDialog(User user, String currentName) {
    final TextEditingController nameController = TextEditingController(text: currentName);
    String errorMessage = ""; // To store the error message

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: const Text('Change Name', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Update your display name used across the app.",
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      hintText: 'Enter new name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (errorMessage.isNotEmpty)
                    Text(
                      errorMessage,
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    String newName = nameController.text.trim();
                    if (newName.isEmpty) {
                      setStateDialog(() {
                        errorMessage = 'Name cannot be empty!';
                      });
                    } else {
                      await DatabaseService(uid: user.uid).updateUserData(newName);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Name updated successfully!'), backgroundColor: Colors.green),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  void _showChangePasswordDialog() {
    final TextEditingController passwordController = TextEditingController();
    bool isPasswordVisible = false;
    String errorMessage = ""; // To store the error message

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Use at least 6 characters for your new password.",
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: passwordController,
                    obscureText: !isPasswordVisible,
                    decoration: InputDecoration(
                      hintText: 'Enter new password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setStateDialog(() {
                            isPasswordVisible = !isPasswordVisible; 
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (errorMessage.isNotEmpty)
                    Text(
                      errorMessage,
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    String password = passwordController.text.trim();
                    if (password.isEmpty) {
                      setStateDialog(() {
                        errorMessage = 'Password cannot be empty!';
                      });
                    } else if (password.length < 6) {
                      setStateDialog(() {
                        errorMessage = 'Password must be at least 6 characters';
                      });
                    } else {
                      try {
                        await _auth.updatePassword(password);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password updated successfully!'), backgroundColor: Colors.green),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to update password. Try again.'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?\nYou can always log back in anytime.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _auth.signOut();
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user = Provider.of<User?>(context);

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<UserData>(
      stream: DatabaseService(uid: user.uid).userData,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        UserData userData = snapshot.data!;

        return Scaffold(
          backgroundColor: Colors.purple[50],
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
            child: ListView( // <-- Changed to ListView to prevent overflow
              children: [
                const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 24, // Increase size for better emphasis
                    fontWeight: FontWeight.w700, // Make it slightly bolder
                    color: Colors.deepPurple, 
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Manage your account and app preferences below.",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                // const SizedBox(height: 20),


                const SizedBox(height: 20),

                _buildSettingsItem(
                  icon: Icons.person_outline,
                  title: 'Change Name',
                  
                  onTap: () => _showChangeNameDialog(user, userData.name),
                ),

                _buildSettingsItem(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  onTap: _showChangePasswordDialog,
                ),

                _buildSettingsItem(
                  icon: Icons.description_outlined,
                  title: 'Terms and Conditions',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TermsAndConditionsScreen()),
                    );
                  },
                ),

                _buildSettingsItem(
                  icon: Icons.logout,
                  title: 'Logout',
                  isLogout: true,
                  onTap: _confirmLogout, // <-- Uses confirmation dialog
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: isLogout ? Colors.red : Colors.black),
              const SizedBox(width: 15),
              Expanded(
                child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: isLogout ? Colors.red : Colors.black)),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
