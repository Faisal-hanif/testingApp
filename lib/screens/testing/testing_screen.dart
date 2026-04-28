import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'results_screen.dart';
import '../../utils/constants.dart';

class TestingScreen extends StatefulWidget {
  final String url;
  final List<String> selectedTests;
  final Map<String, dynamic>? fullTestData;  // ✅ PARAMETER ADD KAR DIYA

  const TestingScreen({
    super.key,
    required this.url,
    required this.selectedTests,
    this.fullTestData,  // ✅ OPTIONAL, AGAR PASS HO TO IGNORE
  });

  @override
  State<TestingScreen> createState() => _TestingScreenState();
}

class _TestingScreenState extends State<TestingScreen> {
  double _progress = 0.0;
  String _currentStatus = 'Initializing tests...';
  bool _isComplete = false;
  List<Map<String, dynamic>> _testProgress = [];

  @override
  void initState() {
    super.initState();
    _initializeTests();
    _startRealTesting();
  }

  void _initializeTests() {
    _testProgress = widget.selectedTests.map((testId) {
      final test = AppConstants.testOptions.firstWhere(
            (t) => t['id'] == testId,
        orElse: () => {'name': 'Test', 'description': ''},
      );
      return {
        'id': testId,
        'name': test['name'],
        'status': 'pending',
      };
    }).toList();
  }

  Future<void> _startRealTesting() async {
    setState(() => _currentStatus = 'Connecting to server...');

    try {
      // ✅ FULL TEST DATA PEHLE SE HAI TO SKIP BACKEND CALL (OPTIONAL)
      if (widget.fullTestData != null) {
        for (int i = 0; i < _testProgress.length; i++) {
          await Future.delayed(const Duration(milliseconds: 500));
          setState(() {
            _testProgress[i]['status'] = 'completed';
            _progress = (i + 1) / _testProgress.length;
            _currentStatus = 'Completed ${_testProgress[i]['name']}';
          });
        }
        setState(() {
          _isComplete = true;
          _progress = 1.0;
        });
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ResultsScreen(testResult: widget.fullTestData!),
            ),
          );
        }
        return;
      }

      // ELSE: NORMAL BACKEND CALL
      await _testWebsite();

      setState(() {
        _isComplete = true;
        _currentStatus = 'Tests completed!';
        _progress = 1.0;
      });

    } catch (e) {
      print('❌ Error: $e');
      _showErrorDialog('Test failed: ${e.toString()}');
    }
  }

  Future<void> _testWebsite() async {
    setState(() => _currentStatus = 'Testing website...');

    final response = await http.post(
      Uri.parse('${AppConstants.pythonServer}/api/test/website'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'url': widget.url,
        'tests': widget.selectedTests,
        'include_emotions': true,
        'include_competitors': true,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      for (int i = 0; i < _testProgress.length; i++) {
        await Future.delayed(const Duration(milliseconds: 300));
        setState(() {
          _testProgress[i]['status'] = 'completed';
          _progress = (i + 1) / _testProgress.length;
          _currentStatus = 'Completed ${_testProgress[i]['name']}';
        });
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResultsScreen(testResult: data),
          ),
        );
      }
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Test Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed': return Colors.green;
      case 'running': return Colors.blue;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed': return Icons.check_circle;
      case 'running': return Icons.autorenew;
      default: return Icons.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Testing Progress'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (!_isComplete) {
              _showCancelDialog();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildProgressHeader(),
            const SizedBox(height: 30),
            _buildProgressBar(),
            const SizedBox(height: 40),
            Expanded(child: _buildTestList()),
            _buildStatusMessage(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: CircularProgressIndicator(
                value: _progress,
                strokeWidth: 8,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _isComplete ? Colors.green : Colors.blue,
                ),
              ),
            ),
            Text(
              '${(_progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _isComplete ? Colors.green : Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          _isComplete ? 'Tests Complete!' : 'Testing Website...',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Text(
          widget.url,
          style: const TextStyle(color: Colors.grey, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          '${_testProgress.where((t) => t['status'] == 'completed').length} of ${_testProgress.length} tests completed',
          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        LinearProgressIndicator(
          value: _progress,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(
            _isComplete ? Colors.green : Colors.blue,
          ),
          minHeight: 10,
          borderRadius: BorderRadius.circular(5),
        ),
        const SizedBox(height: 10),
        Text(
          '${(_progress * 100).toStringAsFixed(0)}% Complete',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTestList() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Test Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            const Divider(),
            const SizedBox(height: 15),
            Expanded(
              child: ListView.builder(
                itemCount: _testProgress.length,
                itemBuilder: (context, index) {
                  final test = _testProgress[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _getStatusColor(test['status']).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_getStatusIcon(test['status']), color: _getStatusColor(test['status']), size: 20),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(test['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 3),
                              Text(
                                test['status'] == 'completed' ? 'Completed successfully'
                                    : test['status'] == 'running' ? 'Running...' : 'Pending...',
                                style: TextStyle(color: _getStatusColor(test['status']), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        if (test['status'] == 'completed')
                          const Icon(Icons.check_circle, color: Colors.green),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusMessage() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            _isComplete ? Icons.check_circle : Icons.info,
            color: _isComplete ? Colors.green : Colors.blue,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isComplete
                  ? 'Preparing results...'
                  : 'Testing may take a few minutes. Please wait...',
              style: TextStyle(
                color: _isComplete ? Colors.green[800] : Colors.blue[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Test?'),
        content: const Text('Are you sure you want to cancel the ongoing test?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
