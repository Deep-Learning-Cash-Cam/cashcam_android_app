import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

final Map<String, Map<String, String>> currencyDetails = {
  'USD_C_1': {'image': 'assets/USD_C_1.png', 'name': '1 Cent (USD)'},
  'USD_C_5': {'image': 'assets/USD_C_5.png', 'name': '5 Cents (USD)'},
  'USD_C_10': {'image': 'assets/USD_C_10.png', 'name': '10 Cents (USD)'},
  'USD_C_25': {'image': 'assets/USD_C_25.png', 'name': '25 Cents (USD)'},
  'USD_C_50': {'image': 'assets/USD_C_50.png', 'name': '50 Cents (USD)'},
  'USD_C_100': {'image': 'assets/USD_C_100.png', 'name': '1 Dollar Coin (USD)'},
  'USD_B_1': {'image': 'assets/USD_B_1.png', 'name': '1 Dollar (USD)'},
  'USD_B_2': {'image': 'assets/USD_B_2.png', 'name': '2 Dollars (USD)'},
  'USD_B_5': {'image': 'assets/USD_B_5.png', 'name': '5 Dollars (USD)'},
  'USD_B_10': {'image': 'assets/USD_B_10.png', 'name': '10 Dollars (USD)'},
  'USD_B_20': {'image': 'assets/USD_B_20.png', 'name': '20 Dollars (USD)'},
  'USD_B_50': {'image': 'assets/USD_B_50.png', 'name': '50 Dollars (USD)'},
  'USD_B_100': {'image': 'assets/USD_B_100.png', 'name': '100 Dollars (USD)'},
  'EUR_C_1': {'image': 'assets/EUR_C_1.png', 'name': '1 Cent (EUR)'},
  'EUR_C_2': {'image': 'assets/EUR_C_2.png', 'name': '2 Cents (EUR)'},
  'EUR_C_5': {'image': 'assets/EUR_C_5.png', 'name': '5 Cents (EUR)'},
  'EUR_C_10': {'image': 'assets/EUR_C_10.png', 'name': '10 Cents (EUR)'},
  'EUR_C_20': {'image': 'assets/EUR_C_20.png', 'name': '20 Cents (EUR)'},
  'EUR_C_50': {'image': 'assets/EUR_C_50.png', 'name': '50 Cents (EUR)'},
  'EUR_C_100': {'image': 'assets/EUR_C_100.png', 'name': '1 Euro (EUR)'},
  'EUR_C_200': {'image': 'assets/EUR_C_200.png', 'name': '2 Euros (EUR)'},
  'EUR_B_5': {'image': 'assets/EUR_B_5.png', 'name': '5 Euros (EUR)'},
  'EUR_B_10': {'image': 'assets/EUR_B_10.png', 'name': '10 Euros (EUR)'},
  'EUR_B_20': {'image': 'assets/EUR_B_20.png', 'name': '20 Euros (EUR)'},
  'EUR_B_50': {'image': 'assets/EUR_B_50.png', 'name': '50 Euros (EUR)'},
  'EUR_B_100': {'image': 'assets/EUR_B_100.png', 'name': '100 Euros (EUR)'},
  'EUR_B_200': {'image': 'assets/EUR_B_200.png', 'name': '200 Euros (EUR)'},
  'EUR_B_500': {'image': 'assets/EUR_B_500.png', 'name': '500 Euros (EUR)'},
  'NIS_C_10': {'image': 'assets/NIS_C_10.png', 'name': '10 Agorot (NIS)'},
  'NIS_C_50': {'image': 'assets/NIS_C_50.png', 'name': '50 Agorot (NIS)'},
  'NIS_C_100': {'image': 'assets/NIS_C_100.png', 'name': '1 Shekel (NIS)'},
  'NIS_C_200': {'image': 'assets/NIS_C_200.png', 'name': '2 Shekels (NIS)'},
  'NIS_C_500': {'image': 'assets/NIS_C_500.png', 'name': '5 Shekels (NIS)'},
  'NIS_C_1000': {'image': 'assets/NIS_C_1000.png', 'name': '10 Shekels (NIS)'},
  'NIS_B_20': {'image': 'assets/NIS_B_20.png', 'name': '20 Shekels (NIS)'},
  'NIS_B_50': {'image': 'assets/NIS_B_50.png', 'name': '50 Shekels (NIS)'},
  'NIS_B_100': {'image': 'assets/NIS_B_100.png', 'name': '100 Shekels (NIS)'},
  'NIS_B_200': {'image': 'assets/NIS_B_200.png', 'name': '200 Shekels (NIS)'},
};

class StatisticsScreen extends StatefulWidget {
  final String imagePath;
  final String annotatedImageBase64;
  final Map<String, dynamic> currencies;
  final String selectedCurrency;
  final String? imageId;
  final String accessToken;

  StatisticsScreen({
    required this.imagePath,
    required this.annotatedImageBase64,
    required this.currencies,
    required this.selectedCurrency,
    this.imageId,
    required this.accessToken,
  });

  @override
  _StatisticsScreenState createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _isReported = false;
  late Future<Size> _imageSize;
  final TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    _imageSize = _getImageSize();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<Size> _getImageSize() async {
    final Uint8List bytes = base64Decode(widget.annotatedImageBase64);
    final decodedImage = await decodeImageFromList(bytes);
    return Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
  }

  Future<void> _reportIncorrectRecognition(BuildContext context) async {
    if (widget.imageId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reporting is not available for guest users.')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(
            'http://ec2-54-197-155-194.compute-1.amazonaws.com:80/api/flag_image/${widget.imageId}'),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _isReported = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalAmount = widget.currencies.entries.fold(
      0.0,
          (sum, entry) {
        double itemTotalValue =
            entry.value['quantity'] * entry.value['return_currency_value'];
        return sum + itemTotalValue;
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Recognition Results'),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<Size>(
              future: _imageSize,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                  final size = snapshot.data!;
                  final screenWidth = MediaQuery.of(context).size.width;
                  final screenHeight = MediaQuery.of(context).size.height * 0.7;

                  // Calculate height based on the aspect ratio of the image
                  double height = screenWidth * (size.height / size.width);

                  return Stack(
                    children: [
                      Container(
                        width: screenWidth,
                        height: height,
                        child: InteractiveViewer(
                          transformationController: _transformationController,
                          minScale: 1.0,
                          maxScale: 4.0,
                          child: Image.memory(
                            base64Decode(widget.annotatedImageBase64),
                            width: screenWidth,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      if (widget.imageId != null)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: ElevatedButton(
                            onPressed: _isReported
                                ? null
                                : () => _reportIncorrectRecognition(context),
                            child: Text(_isReported ? 'Thanks' : 'Report'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                              _isReported ? Colors.green : Colors.red,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              textStyle: TextStyle(fontSize: 12),
                              disabledBackgroundColor: Colors.green,
                              disabledForegroundColor: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  );
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detected Currencies:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  for (var entry in widget.currencies.entries)
                    Card(
                      child: ListTile(
                        leading: Image.asset(
                          currencyDetails[entry.key]?['image'] ??
                              'assets/default_currency.png',
                          width: 50,
                          height: 50,
                        ),
                        title: Text(
                          currencyDetails[entry.key]?['name'] ?? entry.key,
                        ),
                        subtitle: Text(
                          '${entry.value['quantity']} items, ${(entry.value['quantity'] * entry.value['return_currency_value']).toStringAsFixed(2)} ${widget.selectedCurrency}',
                        ),
                      ),
                    ),
                  SizedBox(height: 16),
                  Text(
                    'Total Amount:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Card(
                    child: ListTile(
                      title: Text('Total'),
                      subtitle: Text('${totalAmount.toStringAsFixed(2)} ${widget.selectedCurrency}'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}