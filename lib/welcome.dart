import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:camera/camera.dart';
import 'registration_screen.dart';
import 'login_screen.dart';
import 'camera.dart';
import 'package:permission_handler/permission_handler.dart';


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

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration successful. Please log in.')),
      );
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logged in successfully')),
      );
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

  Future<bool> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.storage,
    ].request();

    if (statuses[Permission.camera]!.isGranted &&
        statuses[Permission.storage]!.isGranted) {
      return true;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Permissions not granted')),
      );
      return false;
    }
  }

  void _continueToApp() async {
    if (await _requestPermissions()) {
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
  }

  void _openGallery() {
    // Placeholder function for gallery functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gallery functionality not implemented yet')),
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
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Commented out Image.asset as the asset might not be available
                  // Image.asset(
                  //   'assets/logo.jpeg',
                  //   height: 100,
                  // ),
                  SizedBox(height: 20),
                  Text(
                    "Snap and detect the value of your currency!",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.normal,
                        color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  Text(
                    _connectivityMessage,
                    style: TextStyle(
                        fontSize: 18,
                        color: _isConnected ? Colors.green : Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  if (_userName != null)
                    Text(
                      'Welcome, $_userName!',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      ],
                    )
                  else
                    ElevatedButton(
                      onPressed: _logout,
                      child: Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        textStyle: TextStyle(fontSize: 18),
                      ),
                    ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isConnected ? _continueToApp : null,
                    child: Text(_accessToken == null ? 'Continue as Guest' : 'Open Camera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 31, 133, 31),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      textStyle: TextStyle(fontSize: 18),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isConnected ? _openGallery : null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Gallery'),
                        SizedBox(width: 18),
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
            ),
          ),
        ),
      ),
    );
  }
}