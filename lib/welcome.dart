import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:camera/camera.dart';
import 'registration_screen.dart';
import 'login_screen.dart';
import 'camera.dart';
import 'gallery.dart';

class WelcomeScreen extends StatefulWidget {
  final CameraDescription camera;

  WelcomeScreen({required this.camera});

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String _connectivityMessage = 'Checking connectivity...';
  bool _isConnected = false;
  String _selectedCurrency = 'NIS';
  String? _accessToken;
  String? _tokenType;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Exit App'),
        content: Text('Do you want to exit the app?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () => SystemNavigator.pop(),
            child: Text('Yes'),
          ),
        ],
      ),
    )) ?? false;
  }

  Future<void> _checkConnectivity() async {
    try {
      final response = await http.get(
        Uri.parse('http://ec2-54-197-155-194.compute-1.amazonaws.com'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody['message'] == 'Welcome to CashCam!') {
          setState(() {
            _connectivityMessage = 'Server Available';
            _isConnected = true;
          });
        } else {
          setState(() {
            _connectivityMessage = 'Unexpected response from server';
            _isConnected = false;
          });
        }
      } else {
        setState(() {
          _connectivityMessage = 'Connection Failed: ${response.reasonPhrase}';
          _isConnected = false;
        });
      }
    } catch (e) {
      setState(() {
        _connectivityMessage = 'Connection Error: $e';
        _isConnected = false;
      });
    }
  }

  void _register() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegistrationScreen()),
    );

    if (result != null && result['registrationSuccess'] == true) {
      // Registration was successful, but message already shown
      // You can update UI here if needed, e.g., highlight login button
    }
  }

  void _login() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );

    if (result != null && result['accessToken'] != null) {
      setState(() {
        _accessToken = result['accessToken'];
        _tokenType = result['tokenType'];
        _userName = result['userName'];
      });

      if (result['loginSuccess'] != true) {
        // Only show this message if it wasn't already shown in LoginScreen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logged in successfully')),
        );
      }
    }
  }

  void _logout() {
    setState(() {
      _accessToken = null;
      _tokenType = null;
      _userName = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Logged out successfully')),
    );
  }

  void _continueToApp() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(
          camera: widget.camera,
          selectedCurrency: _selectedCurrency,
          accessToken: _accessToken ?? '',
          tokenType: _tokenType ?? '',
        ),
      ),
    );
  }

  void _openGallery() {
    if (_accessToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in to view your image history')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GalleryScreen(
          accessToken: _accessToken!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text('CashCam'),
          backgroundColor: const Color.fromARGB(255, 0, 128, 0),
          actions: [
            if (_accessToken != null)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ElevatedButton(
                  onPressed: _logout,
                  child: Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    textStyle: TextStyle(fontSize: 14),
                  ),
                ),
              ),
          ],
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/logo.jpeg',
                    height: 100,
                  ),
                  SizedBox(height: 20),
                  if (_userName != null)
                    Text(
                      'Welcome, $_userName!',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 31, 133, 31)),
                    ),
                  SizedBox(height: 20),
                  Text(
                    "Snap and detect the value of your currency!",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.normal,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  Text(
                    _connectivityMessage,
                    style: TextStyle(
                      fontSize: 18,
                      color: _isConnected ? Colors.green : Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Select Currency: ',
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(width: 10),
                      DropdownButton<String>(
                        value: _selectedCurrency,
                        items: <String>['NIS', 'USD', 'EUR'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedCurrency = newValue!;
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  if (_accessToken == null)
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: _isConnected ? _register : null,
                          child: Text('Register'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 31, 133, 31),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            textStyle: TextStyle(fontSize: 18),
                          ),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _isConnected ? _login : null,
                          child: Text('Login'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 31, 133, 31),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            textStyle: TextStyle(fontSize: 18),
                          ),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _isConnected ? _continueToApp : null,
                          child: Text('Continue as Guest'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 31, 133, 31),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                            textStyle: TextStyle(fontSize: 18),
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: _isConnected ? _continueToApp : null,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Capture'),
                              SizedBox(width: 10),
                              Icon(Icons.camera_alt),
                            ],
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 31, 133, 31),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                            textStyle: TextStyle(fontSize: 18),
                          ),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _isConnected ? _openGallery : null,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Gallery'),
                              SizedBox(width: 10),
                              Icon(Icons.photo_library),
                            ],
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 31, 133, 31),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            textStyle: TextStyle(fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}