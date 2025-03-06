import 'package:flutter/material.dart';
import 'package:trackify/screens/authenticate/forgot_password_page.dart';
import 'package:trackify/services/auth.dart';
import 'package:trackify/shared/constants.dart';
import 'package:trackify/shared/loading.dart';

class SignIn extends StatefulWidget {


  final Function toggleView;
  const SignIn({super.key, required this.toggleView}); 


  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SignIn> {

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
        title: const Text('Sign in to Trackify'),
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 50.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[

              const SizedBox(height: 50),
              const Icon(Icons.person, size: 80),
              const SizedBox(height: 10),

              // Title
              const Text(
                'Welcome to Trackify',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Sign in to continue',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),

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
                          return ForgotPasswordPage();
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
                  'Sign in',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () async {
                  if (_formKey.currentState!.validate()){
                    setState(() => loading = true);
                    dynamic result = await _auth.signInWithEmailAndPassword(email, password);
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


              // Register Option (Only "Register now" is clickable)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Not a member? ',
                  ),
                  GestureDetector(
                    onTap: () {
                      widget.toggleView();
                    },
                    child: const Text(
                      'Register now!',
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
              ),

            ],

            
          ),
        )
      ),
    );
  }
}