// A number conversion system using Flutter.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// The main entry point of the application.
void main() {
  runApp(const MyApp());
}

// The root widget of the application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Number Converter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // Use a consistent font for a clean look.
        fontFamily: 'Inter', 
      ),
      home: const NumberConverter(),
    );
  }
}

// The stateful widget for the main conversion screen.
class NumberConverter extends StatefulWidget {
  const NumberConverter({super.key});

  @override
  State<NumberConverter> createState() => _NumberConverterState();
}

// The state class for the NumberConverter widget.
class _NumberConverterState extends State<NumberConverter> {
  final TextEditingController _numberController = TextEditingController();
  String _decimalResult = '';
  String _binaryResult = '';
  String _hexResult = '';
  int _selectedBase = 10; // Default base is Decimal.

  @override
  void initState() {
    super.initState();
    // Listen for changes in the text field to perform real-time conversion.
    _numberController.addListener(_convertNumber);
  }

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  // Converts the number from the selected base to others.
  void _convertNumber() {
    setState(() {
      final String input = _numberController.text.trim();
      if (input.isEmpty) {
        // Clear all results if the input is empty.
        _decimalResult = '';
        _binaryResult = '';
        _hexResult = '';
        return;
      }

      // Try to parse the input number based on the selected base.
      final int? number = int.tryParse(input, radix: _selectedBase);

      if (number != null) {
        // If parsing is successful, convert to other bases.
        _decimalResult = number.toString();
        _binaryResult = number.toRadixString(2);
        _hexResult = number.toRadixString(16).toUpperCase();
      } else {
        // If parsing fails, show an error message.
        _decimalResult = 'Invalid Input';
        _binaryResult = 'Invalid Input';
        _hexResult = 'Invalid Input';
      }
    });
  }

  // Builds the UI for the conversion screen.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Number Converter'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Input field and base selection dropdown.
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _numberController,
                    decoration: InputDecoration(
                      labelText: 'Enter a number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      prefixIcon: const Icon(Icons.numbers),
                    ),
                    keyboardType: TextInputType.number,
                    // Use a specific input formatter to allow valid characters for each base.
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(
                        _selectedBase == 10
                            ? r'[0-9]'
                            : _selectedBase == 2
                                ? r'[0-1]'
                                : r'[0-9a-fA-F]',
                      )),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Dropdown to select the number base.
                DropdownButton<int>(
                  value: _selectedBase,
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedBase = newValue;
                        _convertNumber(); // Re-convert with the new base.
                      });
                    }
                  },
                  items: const [
                    DropdownMenuItem(
                      value: 10,
                      child: Text('Decimal (10)'),
                    ),
                    DropdownMenuItem(
                      value: 2,
                      child: Text('Binary (2)'),
                    ),
                    DropdownMenuItem(
                      value: 16,
                      child: Text('Hexadecimal (16)'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),
            // Display results in a clear, card-like format.
            _buildResultCard('Decimal', _decimalResult),
            _buildResultCard('Binary', _binaryResult),
            _buildResultCard('Hexadecimal', _hexResult),
          ],
        ),
      ),
    );
  }

  // A helper method to build a result display card.
  Widget _buildResultCard(String title, String result) {
    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              result,
              style: const TextStyle(
                fontSize: 24,
                color: Colors.blueAccent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}