import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'statistics.dart';

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
        Uri.parse('http://ec2-54-197-155-194.compute-1.amazonaws.com:80/api/get_images'),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);

        if (decodedResponse.containsKey('images')) {
          final images = decodedResponse['images'];

          if (images is List) {
            setState(() {
              _images = images;
              _isLoading = false;
            });
          } else if (images == null || images.isEmpty) {
            setState(() {
              _errorMessage = 'No images available';
              _isLoading = false;
            });
          } else {
            throw FormatException('Unexpected data format: images is not a List or is null');
          }
        } else {
          throw FormatException('Unexpected data format: images key does not exist');
        }
      } else {
        throw Exception('Failed to load images: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  String _formatDate(String dateTimeString) {
    final DateTime dateTime = DateTime.parse(dateTimeString).toLocal();
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('History Gallery'),
        backgroundColor: const Color.fromARGB(255, 31, 133, 31),
        actions: [
          IconButton(
            icon: Icon(Icons.home),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
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
          crossAxisCount: 2,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
          childAspectRatio: 1.0,
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
                    currencies: image['currencies'] ?? {},
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
                        aspectRatio: 1.0,
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
  final Map<String, dynamic> currencies;

  FullScreenImage({
    required this.base64Image,
    required this.dateCaptured,
    required this.currencies,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Details'),
        backgroundColor: const Color.fromARGB(255, 31, 133, 31),
        actions: [
          IconButton(
            icon: Icon(Icons.home),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.memory(
              base64Decode(base64Image),
              fit: BoxFit.contain,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Captured on: $dateCaptured',
                style: TextStyle(fontSize: 18, color: Colors.black),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Detected Currencies:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: currencies.length,
              itemBuilder: (context, index) {
                String key = currencies.keys.elementAt(index);
                int amount = currencies[key];
                return Card(
                  child: ListTile(
                    leading: Image.asset(
                      currencyDetails[key]?['image'] ?? 'assets/default_currency.png',
                      width: 50,
                      height: 50,
                    ),
                    title: Text(
                      currencyDetails[key]?['name'] ?? key,
                    ),
                    subtitle: Text(
                      'Amount: $amount',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}