import 'package:flutter/material.dart';
import 'package:trackify/screens/authenticate/forgot_password_page.dart';
import 'package:trackify/services/auth.dart';
import 'package:trackify/shared/constants.dart';
import 'package:trackify/shared/loading.dart';

class Register extends StatefulWidget {
  
  final Function toggleView;
  const Register({super.key, required this.toggleView}); 

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {

  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool loading = false;
  

  // text field state
  String email = '';
  String password = ''; 
  String error = '';  

  @override
  Widget build(BuildContext context) {
    return loading ? const Loading() : Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple[200],
        elevation: 0.0,
        title: const Text('Sign up to Trackify'),
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 50.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              const SizedBox(height: 20.0),
              TextFormField(
                decoration: textInputDecoration.copyWith(hintText: 'Email'),
                validator: (val) => val!.isEmpty ? 'Enter an email' : null,
                onChanged: (val) {
                  setState(() => email = val);
                },
              ),
              const SizedBox(height: 20.0),
              TextFormField(
                decoration: textInputDecoration.copyWith(hintText: 'Password'),
                obscureText: true,
                validator: (val) => val!.length < 6 ? 'Enter a password 6+ chars long' : null,
                onChanged: (val) {
                  setState(() => password = val);
                },
              ),
              const SizedBox(height: 20.0),

              
              // Forgot password function
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) {
                          return const ForgotPasswordPage();
                        }));
                      },
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                        ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10.0),



              ElevatedButton (
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[400], // Updated property name
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Register',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () async {
                  if (_formKey.currentState!.validate()){
                    setState(() => loading = true);                
                    dynamic result = await _auth.registerWithEmailAndPassword(email, password);
                    if (result == null) {
                      setState(() { 
                        error = 'could not sign in with those credentials';
                        loading = false;
                        });
                    }
                  }
                }
              ),
              const SizedBox(height: 10.0),

              // Sign in Option (Only "Register now" is clickable)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'I am a member! ',
                  ),
                  GestureDetector(
                    onTap: () {
                      widget.toggleView();
                    },
                    child: const Text(
                      'Login now',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              
              const SizedBox(height: 20.0),

              Text(
                error,
                style: const TextStyle(color: Colors.red, fontSize: 14.0),
              )
            ],
          ),
        )
      ),
    );
  }
}