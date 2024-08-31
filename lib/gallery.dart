import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Import for date formatting
import 'dart:convert';
import 'package:flutter/material.dart';

class GalleryScreen extends StatefulWidget {
  final String accessToken;

  GalleryScreen({required this.accessToken});

  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<dynamic> _images = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchImages();
  }

  Future<void> _fetchImages() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://ec2-54-197-155-194.compute-1.amazonaws.com:80/api/get_images'),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _images = jsonDecode(response.body)['images'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load images';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  String _formatDate(String dateTimeString) {
    final DateTime dateTime = DateTime.parse(dateTimeString);
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('History Gallery'),
        backgroundColor: const Color.fromARGB(255, 31, 133, 31),
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: const Color.fromARGB(255, 31, 133, 31),
        ),
      )
          : _errorMessage != null
          ? Center(
        child: Text(
          _errorMessage!,
          style: TextStyle(color: Colors.red, fontSize: 18),
        ),
      )
          : GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Two images per row
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
          childAspectRatio: 1.0, // Aspect ratio to make images square
        ),
        itemCount: _images.length,
        itemBuilder: (BuildContext context, int index) {
          final image = _images[index];
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FullScreenImage(
                    base64Image: image['base64_string'],
                    dateCaptured: _formatDate(image['upload_date']),
                  ),
                ),
              );
            },
            child: Card(
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(15.0),
                      ),
                      child: AspectRatio(
                        aspectRatio: 1.0, // Make image square
                        child: Image.memory(
                          base64Decode(image['base64_string']),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Captured on: ${_formatDate(image['upload_date'])}',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class FullScreenImage extends StatelessWidget {
  final String base64Image;
  final String dateCaptured;

  FullScreenImage({required this.base64Image, required this.dateCaptured});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Details'),
        backgroundColor: const Color.fromARGB(255, 31, 133, 31),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Image.memory(
                base64Decode(base64Image),
                fit: BoxFit.contain,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Captured on: $dateCaptured',
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}