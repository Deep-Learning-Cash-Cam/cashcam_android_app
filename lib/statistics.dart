import 'dart:convert';
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
  final String? imageId;  // Make imageId nullable
  final String accessToken;

  StatisticsScreen({
    required this.imagePath,
    required this.annotatedImageBase64,
    required this.currencies,
    required this.selectedCurrency,
    this.imageId,  // Make imageId optional
    required this.accessToken,
  });

  @override
  _StatisticsScreenState createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _isReported = false;

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
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Image.memory(base64Decode(widget.annotatedImageBase64)),
                  if (widget.imageId != null)  // Only show report button for logged-in users
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
                          padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              ),
              SizedBox(height: 16),
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
      ),
    );
  }
}