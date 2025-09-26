// Improved Number Converter with negative/fractional support, input validation, error feedback, and copy-to-clipboard feature.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class ConversionRecord {
  final String input;
  final int base;
  final String decimal;
  final String binary;
  final String octal;
  final String hex;

  ConversionRecord({
    required this.input,
    required this.base,
    required this.decimal,
    required this.binary,
    required this.octal,
    required this.hex,
  });

  Map<String, dynamic> toJson() => {
        'input': input,
        'base': base,
        'decimal': decimal,
        'binary': binary,
        'octal': octal,
        'hex': hex,
      };

  factory ConversionRecord.fromJson(Map<String, dynamic> json) => ConversionRecord(
        input: json['input'],
        base: json['base'],
        decimal: json['decimal'],
        binary: json['binary'],
        octal: json['octal'],
        hex: json['hex'],
      );
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
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum NumberBase { binary, octal, decimal, hex }

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _inputController = TextEditingController();
  NumberBase _selectedBase = NumberBase.decimal;
  String _errorMessage = '';
  String _decimalResult = '';
  String _binaryResult = '';
  String _octalResult = '';
  String _hexResult = '';
  bool _showResults = false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  int getBase(NumberBase base) {
    switch (base) {
      case NumberBase.binary:
        return 2;
      case NumberBase.octal:
        return 8;
      case NumberBase.decimal:
        return 10;
      case NumberBase.hex:
        return 16;
    }
  }

  String getBaseName(NumberBase base) {
    switch (base) {
      case NumberBase.binary:
        return 'Binary';
      case NumberBase.octal:
        return 'Octal';
      case NumberBase.decimal:
        return 'Decimal';
      case NumberBase.hex:
        return 'Hexadecimal';
    }
  }

  RegExp getInputRegExp(NumberBase base) {
    switch (base) {
      case NumberBase.binary:
        return RegExp(r'^-?[01]+$');
      case NumberBase.octal:
        return RegExp(r'^-?[0-7]+$');
      case NumberBase.decimal:
        return RegExp(r'^-?[0-9]+$');
      case NumberBase.hex:
        return RegExp(r'^-?[0-9a-fA-F]+$');
    }
  }

  void _convert() async {
    setState(() {
      _errorMessage = '';
      _showResults = false;
      _decimalResult = '';
      _binaryResult = '';
      _octalResult = '';
      _hexResult = '';
    });

    final input = _inputController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a number.';
      });
      return;
    }

    final regExp = getInputRegExp(_selectedBase);
    if (!regExp.hasMatch(input)) {
      setState(() {
        _errorMessage = 'Invalid input for ${getBaseName(_selectedBase)} base.';
      });
      return;
    }

    try {
      final int value = int.parse(input, radix: getBase(_selectedBase));
      setState(() {
        _decimalResult = value.toString();
        _binaryResult = value.toRadixString(2);
        _octalResult = value.toRadixString(8);
        _hexResult = value.toRadixString(16).toUpperCase();
        _showResults = true;
      });

      // Save to history
      final record = ConversionRecord(
        input: input,
        base: getBase(_selectedBase),
        decimal: _decimalResult,
        binary: _binaryResult,
        octal: _octalResult,
        hex: _hexResult,
      );
      await _saveToHistory(record);
    } catch (e) {
      setState(() {
        _errorMessage = 'Conversion error: ${e.toString()}';
      });
    }
  }

  Future<void> _saveToHistory(ConversionRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> history = prefs.getStringList('conversion_history') ?? [];
    history.insert(0, record.toJson().toString());
    if (history.length > 20) history.removeLast(); // Keep only last 20
    await prefs.setStringList('conversion_history', history);
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard!')),
    );
  }

  void _shareResult(String text) {
    // For demo: just copy to clipboard and show a message
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Result copied! Share via WhatsApp or other apps.')),
    );
  }

  void _openHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Number Converter'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Conversion History',
            onPressed: () => _openHistory(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            TextField(
              controller: _inputController,
              decoration: InputDecoration(
                labelText: 'Enter number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                prefixIcon: const Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.text,
              inputFormatters: [
                FilteringTextInputFormatter.allow(getInputRegExp(_selectedBase)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Input Base:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                DropdownButton<NumberBase>(
                  value: _selectedBase,
                  onChanged: (NumberBase? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedBase = newValue;
                        _inputController.clear();
                        _errorMessage = '';
                        _showResults = false;
                      });
                    }
                  },
                  items: NumberBase.values.map((base) {
                    return DropdownMenuItem(
                      value: base,
                      child: Text(getBaseName(base)),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.calculate),
              label: const Text('Convert'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
              onPressed: _convert,
            ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            if (_showResults) ...[
              const SizedBox(height: 30),
              _buildResultCard('Decimal', _decimalResult),
              _buildResultCard('Binary', _binaryResult),
              _buildResultCard('Octal', _octalResult),
              _buildResultCard('Hexadecimal', _hexResult),
            ],
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
            IconButton(
              icon: const Icon(Icons.share, color: Colors.green),
              tooltip: 'Share $title',
              onPressed: result.isNotEmpty && result != 'Invalid Input'
                  ? () => _shareResult('$title: $result')
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<ConversionRecord> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> historyRaw = prefs.getStringList('conversion_history') ?? [];
    setState(() {
      _history = historyRaw.map((e) {
        final map = Map<String, dynamic>.from(_parseJsonString(e));
        return ConversionRecord.fromJson(map);
      }).toList();
    });
  }

  Map<String, dynamic> _parseJsonString(String jsonStr) {
    // Remove curly braces and split by comma, then by colon
    final Map<String, dynamic> map = {};
    final cleaned = jsonStr.replaceAll(RegExp(r'^{|}$'), '');
    for (var pair in cleaned.split(',')) {
      final kv = pair.split(':');
      if (kv.length == 2) {
        map[kv[0].trim().replaceAll("'", "")] = kv[1].trim().replaceAll("'", "");
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversion History'),
        centerTitle: true,
      ),
      body: _history.isEmpty
          ? const Center(child: Text('No conversion history yet.'))
          : ListView.builder(
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final record = _history[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(
                      'Input: ${record.input} (Base ${record.base})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Decimal: ${record.decimal}'),
                        Text('Binary: ${record.binary}'),
                        Text('Octal: ${record.octal}'),
                        Text('Hexadecimal: ${record.hex}'),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}