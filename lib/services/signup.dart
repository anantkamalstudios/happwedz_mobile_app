import 'package:flutter/material.dart';

import 'login_screen.dart';

class SignupPage extends StatelessWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 40),
                Image.asset(
                  'assets/images/logoo.png',
                  height: 80,
                ),
                const SizedBox(height: 20),
                Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink,
                  ),
                ),
                const SizedBox(height: 30),

                // Name
                _buildTextField(hint: 'Full Name'),

                // Email
                _buildTextField(hint: 'Email Address', keyboardType: TextInputType.emailAddress),

                // Mobile
                _buildTextField(hint: 'Mobile Number', keyboardType: TextInputType.phone),

                // Password
                _buildTextField(hint: 'Password', obscureText: true),

                const SizedBox(height: 20),

                // Sign Up Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink[200],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      // Sign-up logic
                    },
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(fontSize: 16,color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'or continue with',
                  style: TextStyle(color: Colors.grey.shade600),
                ),

                const SizedBox(height: 10),

                // Google Button
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: Image.asset(
                    'assets/icons/google.png',
                    height: 30,
                  ),
                  label: const Text('Continue with Google', style: TextStyle(fontSize: 16,color: Colors.white),),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.pink[200],
                    minimumSize: const Size(double.infinity, 48),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                // const SizedBox(height: 24),

                // Already have account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    TextButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage()));
                      },
                      child: Text(
                        'Login',
                        style: TextStyle(color: Colors.pink),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
