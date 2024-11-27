import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import './registration_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> login() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();
    final hashedPassword = hashPassword(password);
    final user = ParseUser(username, hashedPassword, null);
      // Use ParseUser.login() to authenticate the user
    final response = await user.login();

    if (response.success && response.results != null && response.results!.isNotEmpty) {
      // Login success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login Successful!')),
      );
      // print('✅ Login successful!');
      // Navigate to home or dashboard
      Navigator.pushReplacementNamed(context, '/home');
      // Delay before checking the current user
      Future.delayed(Duration(seconds: 1), () async {
        ParseUser? currentUser = await ParseUser.currentUser() as ParseUser?;
        if (currentUser != null) {
          print('Logged in as: ${currentUser.username}');
        } else {
          print('Current user is null after delay');
        }
      });
    } else {
      // Login failed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login Failed: Invalid username or password.')),
      );
      // print('❌ Login failed: ${response.error?.message}');
    }
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: login,
              child: Text('Login'),
            ),

            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegistrationPage()),
                );
              },
              child: Text('Don\'t have an account? Register here'),
            ),
          ],
        ),
      ),
    );
  }
}
