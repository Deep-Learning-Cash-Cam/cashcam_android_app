import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'welcome.dart'; // Make sure to import the WelcomeScreen

void main() async {
  // Ensure that plugin services are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Obtain a list of available cameras
  final cameras = await availableCameras();

  // Get the first camera from the list
  final firstCamera = cameras.first;

  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;

  const MyApp({Key? key, required this.camera}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CashCam',
      theme: ThemeData(
        primarySwatch: Colors.green,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: WelcomeScreen(camera: camera),
    );
  }
}