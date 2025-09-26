// Improved Number Converter with negative/fractional support, input validation, error feedback, and copy-to-clipboard feature.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Number Converter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
      ),
      home: const NumberConverter(),
    );
  }
}

class NumberConverter extends StatefulWidget {
  const NumberConverter({super.key});

  @override
  State<NumberConverter> createState() => _NumberConverterState();
}

class _NumberConverterState extends State<NumberConverter> {
  final TextEditingController _numberController = TextEditingController();
  String _decimalResult = '';
  String _binaryResult = '';
  String _hexResult = '';
  String _errorMessage = '';
  int _selectedBase = 10;

  @override
  void initState() {
    super.initState();
    _numberController.addListener(_convertNumber);
  }

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  void _convertNumber() {
    setState(() {
      final input = _numberController.text.trim();
      _errorMessage = '';
      if (input.isEmpty) {
        _decimalResult = '';
        _binaryResult = '';
        _hexResult = '';
        return;
      }

      try {
        final value = _parseInput(input, _selectedBase);
        _decimalResult = value.toString();
        _binaryResult = _toBaseString(value, 2);
        _hexResult = _toBaseString(value, 16).toUpperCase();
      } catch (e) {
        _decimalResult = 'Invalid Input';
        _binaryResult = 'Invalid Input';
        _hexResult = 'Invalid Input';
        _errorMessage = e.toString().replaceFirst('FormatException: ', '');
      }
    });
  }

  double _parseInput(String input, int base) {
    final regExp = RegExp(r'^-?[0-9A-Fa-f]+(\.[0-9A-Fa-f]+)?$');
    if (!regExp.hasMatch(input)) {
      throw FormatException('Invalid format for base $base');
    }
    bool negative = input.startsWith('-');
    final parts = input.replaceFirst('-', '').split('.');
    double result = 0;
    // Integer part
    for (int i = 0; i < parts[0].length; i++) {
      int digit = int.parse(parts[0][i], radix: base);
      result = result * base + digit;
    }
    // Fractional part
    if (parts.length > 1) {
      double frac = 0;
      double basePow = base.toDouble();
      for (int i = 0; i < parts[1].length; i++) {
        int digit = int.parse(parts[1][i], radix: base);
        frac += digit / basePow;
        basePow *= base;
      }
      result += frac;
    }
    return negative ? -result : result;
  }

  String _toBaseString(double value, int base) {
    if (value.isNaN || value.isInfinite) return 'Invalid';
    bool negative = value < 0;
    value = value.abs();
    int intPart = value.floor();
    double fracPart = value - intPart;
    String intStr = intPart.toRadixString(base);
    String fracStr = '';
    if (fracPart > 0) {
      fracStr = '.';
      double frac = fracPart;
      for (int i = 0; i < 8 && frac > 0; i++) {
        frac *= base;
        int digit = frac.floor();
        fracStr += digit.toRadixString(base);
        frac -= digit;
      }
    }
    return (negative ? '-' : '') + intStr + fracStr;
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard!')),
    );
  }

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
                    keyboardType: TextInputType.text,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(
                        _selectedBase == 10
                            ? r'[-0-9.]'
                            : _selectedBase == 2
                                ? r'[-0-1.]'
                                : r'[-0-9a-fA-F.]',
                      )),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<int>(
                  value: _selectedBase,
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedBase = newValue;
                        _convertNumber();
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
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 30),
            _buildResultCard('Decimal', _decimalResult),
            _buildResultCard('Binary', _binaryResult),
            _buildResultCard('Hexadecimal', _hexResult),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(String title, String result) {
    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Expanded(
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
            IconButton(
              icon: const Icon(Icons.copy, color: Colors.blueAccent),
              tooltip: 'Copy $title',
              onPressed: result.isNotEmpty && result != 'Invalid Input'
                  ? () => _copyToClipboard(result, title)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}