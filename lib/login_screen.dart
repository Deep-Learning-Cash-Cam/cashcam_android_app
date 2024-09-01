import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _emailError;
  String? _passwordError;
  bool _isLoading = false;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _emailError = null;
        _passwordError = null;
      });

      try {
        final response = await http.post(
          Uri.parse('http://ec2-54-197-155-194.compute-1.amazonaws.com/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': _emailController.text,
            'password': _passwordController.text,
          }),
        );

        if (response.statusCode == 200) {
          // Login successful
          final responseBody = jsonDecode(response.body);
          final accessToken = responseBody['access_token'];
          final refreshToken = responseBody['refresh_token'];
          final tokenType = responseBody['token_type'];

          // Fetch user details
          final userResponse = await http.get(
            Uri.parse('http://ec2-54-197-155-194.compute-1.amazonaws.com/auth/users/me'),
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
          );

          if (userResponse.statusCode == 200) {
            final userData = jsonDecode(userResponse.body);
            final userName = userData['name']; // Adjust this based on your API response structure

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Login successful')),
            );

            // Pass login success information back to WelcomeScreen
            Navigator.pop(context, {
              'accessToken': accessToken,
              'tokenType': tokenType,
              'userName': userName, // Add the user's name
              'loginSuccess': true,
            });
          } else {
            throw Exception('Failed to fetch user details');
          }
        } else {
          // Login failed
          final errorData = jsonDecode(response.body);
          String errorMessage = 'Login failed. ';
          if (errorData['detail'] != null) {
            errorMessage += errorData['detail'];
          } else if (errorData['email'] != null) {
            errorMessage += 'Email: ${errorData['email'][0]}';
          } else if (errorData['password'] != null) {
            errorMessage += 'Password: ${errorData['password'][0]}';
          } else {
            errorMessage += 'Please check your credentials.';
          }

          setState(() {
            _emailError = errorData['email']?[0];
            _passwordError = errorData['password']?[0];
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
        backgroundColor: const Color.fromARGB(255, 0, 128, 0),
        actions: [
          HomeButton(), // Add the HomeButton here
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    errorText: _emailError,
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    errorText: _passwordError,
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 31, 133, 31),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    textStyle: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeButton extends StatelessWidget {
  const HomeButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.home),
      onPressed: () {
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
    );
  }
}