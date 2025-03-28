import 'package:flutter/material.dart';
import 'package:trackify/screens/authenticate/forgot_password_page.dart';
import 'package:trackify/services/auth.dart';
import 'package:trackify/shared/constants.dart';
import 'package:trackify/shared/loading.dart';

class SignIn extends StatefulWidget {
  final Function toggleView;
  const SignIn({super.key, required this.toggleView});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  bool loading = false;
  bool obscurePassword = true;
  String error = '';

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() => loading = true);
      try {
        dynamic result = await _auth.signInWithEmailAndPassword(
          emailController.text.trim(),
          passwordController.text.trim(),
        );

        if (result == null) {
          setState(() {
            error = 'Invalid email or password.';
            loading = false;
          });
        }
      } catch (e) {
        setState(() {
          error = 'An error occurred. Please try again later.';
          loading = false;
        });
      }
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter an email';
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? const Loading()
        : Scaffold(
            backgroundColor: Colors.purple[50],
            appBar: AppBar(
              backgroundColor: Colors.deepPurple,
              elevation: 0.0,
              title: const Text(
                'Sign in to Trackify',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 40.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      const SizedBox(height: 50),
                      const Icon(Icons.login, size: 100, color: Colors.deepPurple),
                      const SizedBox(height: 20),
                      const Text(
                        'Welcome to Trackify',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Sign in to continue',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Colors.black54),
                      ),
                      const SizedBox(height: 30),

                      // Email Field
                      TextFormField(
                        controller: emailController,
                        decoration: textInputDecoration.copyWith(
                          hintText: 'Email',
                          prefixIcon: const Icon(Icons.email, color: Colors.deepPurple),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: [AutofillHints.email],
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 20.0),

                      // Password Field
                      TextFormField(
                        controller: passwordController,
                        decoration: textInputDecoration.copyWith(
                          hintText: 'Password',
                          prefixIcon: const Icon(Icons.lock, color: Colors.deepPurple),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.deepPurple,
                            ),
                            onPressed: () {
                              setState(() => obscurePassword = !obscurePassword);
                            },
                          ),
                        ),
                        obscureText: obscurePassword,
                        validator: _validatePassword,
                      ),
                      const SizedBox(height: 20.0),

                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (context) => const ForgotPasswordPage(),
                            ));
                          },
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30.0),

                      // Sign-in Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text(
                          'Sign in',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                        onPressed: _signIn,
                      ),
                      const SizedBox(height: 20.0),

                      // Register Now
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Not a member? ',
                            style: TextStyle(fontSize: 16, color: Colors.black54),
                          ),
                          GestureDetector(
                            onTap: () => widget.toggleView(),
                            child: const Text(
                              'Register now!',
                              style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20.0),

                      // Error Message with Animation
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: error.isNotEmpty
                            ? Text(
                                error,
                                key: ValueKey<String>(error),
                                style: const TextStyle(color: Colors.red, fontSize: 16.0),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
  }
}
