import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'statistics.dart';

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;
  final String selectedCurrency;
  final String accessToken;
  final String tokenType;

  CameraScreen({
    required this.camera,
    required this.selectedCurrency,
    required this.accessToken,
    required this.tokenType,
  });

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _controller.initialize();
    try {
      await _initializeControllerFuture;
      setState(() {});
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage(BuildContext context) async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        File compressedFile = await compressAndGetFile(File(pickedFile.path), pickedFile.path);
        await _sendImageToServer(context, compressedFile.path);
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<File> compressAndGetFile(File file, String targetPath) async {
    try {
      var result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 90,
        rotate: 0,
      );
      return File(result!.path);
    } catch (e) {
      print('Error compressing image: $e');
      return file;  // Return original file if compression fails
    }
  }

  Future<void> _sendImageToServer(BuildContext context, String imagePath) async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_controller.value.isInitialized) {
        await _controller.pausePreview();
      }

      if (!await File(imagePath).exists()) {
        throw Exception("Image file does not exist at the path: $imagePath");
      }

      final bytes = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(bytes);

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.accessToken}',
      };
      final body = jsonEncode({
        'image': base64Image,
        'return_currency': widget.selectedCurrency,
      });

      final response = await http.post(
        Uri.parse('http://ec2-54-197-155-194.compute-1.amazonaws.com/api/predict'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final annotatedImageBase64 = responseBody['image'];
        final currencies = responseBody['currencies'] as Map<String, dynamic>;
        final imageId = responseBody['image_id'] as String?; // Make imageId nullable

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StatisticsScreen(
                imagePath: imagePath,
                annotatedImageBase64: annotatedImageBase64,
                currencies: currencies,
                selectedCurrency: widget.selectedCurrency,
                imageId: imageId, // Pass imageId as nullable
                accessToken: widget.accessToken,
              ),
            ),
          );
        }
      } else {
        throw Exception('Failed to get response from server: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending image to server: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      if (_controller.value.isInitialized) {
        await _controller.resumePreview();
      }
    }
  }

  Future<void> _takePicture(BuildContext context) async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();
      File compressedFile = await compressAndGetFile(File(image.path), image.path);
      final path = join(
        (await getTemporaryDirectory()).path,
        '${DateTime.now()}.png',
      );
      await compressedFile.copy(path);
      await _sendImageToServer(context, path);
    } catch (e) {
      print('Error taking picture: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking picture: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double buttonSize = screenWidth * 0.3;

    return Scaffold(
      appBar: AppBar(
        title: Text('CashCam'),
        backgroundColor: const Color.fromARGB(255, 31, 133, 31),
      ),
      body: Stack(
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return Container(
                  width: screenWidth,
                  height: screenHeight,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: screenWidth,
                      height: screenWidth * _controller.value.aspectRatio,
                      child: CameraPreview(_controller),
                    ),
                  ),
                );
              } else {
                return Center(
                  child: CircularProgressIndicator(
                    color: const Color.fromARGB(255, 31, 133, 31),
                  ),
                );
              }
            },
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(
                  color: const Color.fromARGB(255, 31, 133, 31),
                ),
              ),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 16.0,
            bottom: 16.0,
            child: FloatingActionButton(
              child: Icon(Icons.photo_library),
              onPressed: _isLoading ? null : () => _pickImage(context),
              heroTag: 'gallery',
              foregroundColor: Color.fromARGB(255, 29, 30, 29),
              backgroundColor: const Color.fromARGB(255, 217, 245, 198),
            ),
          ),
          Positioned(
            bottom: 16.0,
            child: GestureDetector(
              onTap: _isLoading ? null : () => _takePicture(context),
              child: Container(
                width: buttonSize,
                height: buttonSize,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/logo.jpeg'),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 3,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}