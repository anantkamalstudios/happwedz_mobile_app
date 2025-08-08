import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

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

                // Logo
                Image.asset(
                  'assets/images/logoo.png', // Replace with your asset
                  height: 80,
                ),

                const SizedBox(height: 20),

                // Welcome Text
                Text(
                  'Login to continue',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink,
                  ),
                ),

                const SizedBox(height: 30),

                // Email
                _buildTextField(hint: 'Email Address', keyboardType: TextInputType.emailAddress),

                // Password
                _buildTextField(hint: 'Password', obscureText: true),

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Navigate to forgot password screen
                    },
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(color: Colors.pink),
                    ),
                  ),
                ),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Login logic
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:  Colors.pink[200],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(fontSize: 16,color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Divider with OR
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        'or',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),

                const SizedBox(height: 10),

                // Google Login
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

                const SizedBox(height: 10),

                // Don't have an account?
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Don’t have an account?'),
                    TextButton(
                      onPressed: () {
                        // Navigate to signup
                      },
                      child: Text(
                        'Sign Up',
                          style: TextStyle(color: Colors.pink)
                      ),
                    ),
                  ],
                ),
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
