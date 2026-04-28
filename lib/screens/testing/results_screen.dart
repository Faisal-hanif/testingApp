import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/constants.dart';
import '../home_screen.dart';

class ResultsScreen extends StatefulWidget {
  final Map<String, dynamic> testResult;

  const ResultsScreen({
    super.key,
    required this.testResult,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  String _aiSuggestion = '';
  bool _isLoadingSuggestion = false;

  Future<void> _getAISuggestion() async {
    setState(() => _isLoadingSuggestion = true);

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.pythonServer}/api/ai-suggest'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'url': widget.testResult['url'],
          'score': widget.testResult['score'],
          'broken': widget.testResult['links']['broken']
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _aiSuggestion = data['suggestion']);
      }
    } catch (e) {
      print('AI error: $e');
    } finally {
      setState(() => _isLoadingSuggestion = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final links = widget.testResult['links'] as Map<String, dynamic>;
    final technologies = widget.testResult['technologies'] as List<dynamic>;
    final score = widget.testResult['score'] as int;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Results'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _downloadFullReport(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(),
            const SizedBox(height: 20),
            _buildImprovedScoreCard(score),
            const SizedBox(height: 20),
            _buildLinkAnalysisCard(links),
            const SizedBox(height: 15),
            _buildTechStackCard(technologies),
            const SizedBox(height: 15),
            _buildAISuggestionCard(),
            const SizedBox(height: 15),

            // 🆕 COMPETITOR SCORECARD
            if (widget.testResult.containsKey('competitors'))
              _buildCompetitorCard(),

            // 🆕 EMOTIONAL ANALYSIS
            if (widget.testResult.containsKey('emotions'))
              _buildEmotionCard(),

            const SizedBox(height: 15),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  // ==================== AI SUGGESTION CARD ====================
  Widget _buildAISuggestionCard() {
    return Card(
      color: Colors.purple[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  '🤖 AI Suggestion',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple),
                ),
                const Spacer(),
                if (_aiSuggestion.isEmpty && !_isLoadingSuggestion)
                  TextButton(
                    onPressed: _getAISuggestion,
                    child: const Text('Get Suggestion'),
                  ),
                if (_isLoadingSuggestion)
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator()),
              ],
            ),
            if (_aiSuggestion.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(_aiSuggestion, style: const TextStyle(fontSize: 14)),
            ],
          ],
        ),
      ),
    );
  }

  // ==================== COMPETITOR SCORECARD ====================
  Widget _buildCompetitorCard() {
    final competitors = widget.testResult['competitors'] as List;
    final loadTime = widget.testResult['load_time']?.toString() ?? '?';

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.emoji_events, color: Colors.amber),
                  SizedBox(width: 8),
                  Text(
                    'Competitor Scorecard',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: DataTable(
                  columnSpacing: 8,
                  columns: const [
                    DataColumn(label: Text('Website', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Score', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Load', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Broken', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: [
                    DataRow(cells: [
                      const DataCell(Text('You (Current)', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text('${widget.testResult['score']}')),
                      DataCell(Text('$loadTime s')),
                      DataCell(Text('${widget.testResult['links']['broken']}')),
                    ]),
                    ...competitors.map((comp) {
                      return DataRow(cells: [
                        DataCell(Text(comp['name'])),
                        DataCell(Text('${comp['score']}')),
                        DataCell(Text('${comp['load_time']} s')),
                        DataCell(Text('${comp['broken_links']}')),
                      ]);
                    }).toList(),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '💡 Fix ${widget.testResult['links']['broken']} broken links to improve your rank',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== EMOTIONAL ANALYSIS ====================
  Widget _buildEmotionCard() {
    final emotions = widget.testResult['emotions'];
    final loadTime = widget.testResult['load_time']?.toString() ?? '?';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.emoji_emotions, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Emotional Response Analysis',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Trust Score
            _buildEmotionBar(
              'Trust Score',
              emotions['trust_score'],
              Colors.green,
              List<String>.from(emotions['trust_details']),
            ),
            const SizedBox(height: 12),

            // Excitement Score
            _buildEmotionBar(
              'Excitement Score',
              emotions['excitement_score'],
              Colors.orange,
              List<String>.from(emotions['excitement_details']),
            ),
            const SizedBox(height: 12),

            // Professionalism Score
            _buildEmotionBar(
              'Professionalism',
              emotions['professionalism_score'],
              Colors.blue,
              List<String>.from(emotions['professional_indicators']),
            ),

            const SizedBox(height: 10),
            Text(
              '⚡ Page Load Time: $loadTime seconds',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== EMOTION BAR HELPER ====================
  Widget _buildEmotionBar(String label, int score, Color color, List<String> details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            const Spacer(),
            Text('$score/100', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: score / 100,
          backgroundColor: Colors.grey[200],
          color: color,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: details.map((detail) {
            bool isPositive = detail.startsWith('SSL') || detail.startsWith('Good') ||
                detail.startsWith('Fast') || detail.startsWith('Rich') ||
                detail.startsWith('Proper') || detail.startsWith('Modern') ||
                detail.startsWith('Contact') || detail.startsWith('About') ||
                detail.startsWith('Social') || detail.startsWith('Hero');
            return Chip(
              label: Text(detail, style: const TextStyle(fontSize: 11)),
              backgroundColor: isPositive ? Colors.green.shade50 : Colors.orange.shade50,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
      ],
    );
  }

  // ==================== EXISTING WIDGETS ====================
  Widget _buildHeaderSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: _getScoreColor(widget.testResult['score'] as int),
              child: Text(
                '${widget.testResult['score']}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.testResult['url'].toString(),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Tested: ${_formatDateTime(widget.testResult['timestamp'])}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImprovedScoreCard(int score) {
    Color scoreColor = _getScoreColor(score);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [scoreColor.withOpacity(0.7), scoreColor.withOpacity(0.3)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: scoreColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          const Text('OVERALL QUALITY SCORE', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$score', style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold, color: Colors.white)),
              const Text('/100', style: TextStyle(fontSize: 24, color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(30)),
            child: Text(_getScoreStatus(score), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkAnalysisCard(Map<String, dynamic> links) {
    final total = links['total'] as int;
    final working = links['working'] as int;
    final broken = links['broken'] as int;
    final successRate = total > 0 ? (working / total * 100) : 0;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [Icon(Icons.link, color: Colors.blue), SizedBox(width: 10), Text('Link Analysis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
            const SizedBox(height: 15),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _buildStatCircle('Total', total.toString(), Colors.blue),
              _buildStatCircle('Working', working.toString(), Colors.green),
              _buildStatCircle('Broken', broken.toString(), Colors.red),
            ]),
            const SizedBox(height: 15),
            LinearProgressIndicator(value: successRate / 100, backgroundColor: Colors.grey[200], color: successRate >= 80 ? Colors.green : successRate >= 60 ? Colors.orange : Colors.red, minHeight: 10, borderRadius: BorderRadius.circular(5)),
            const SizedBox(height: 8),
            Text('Success Rate: ${successRate.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          ],
        ),
      ),
    );
  }

  Widget _buildTechStackCard(List<dynamic> technologies) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [Icon(Icons.build, color: Colors.orange), SizedBox(width: 10), Text('Technology Stack', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
            const SizedBox(height: 15),
            Wrap(spacing: 10, runSpacing: 10, children: technologies.map((tech) => Chip(label: Text(tech.toString(), style: const TextStyle(fontSize: 12)), backgroundColor: Colors.blue[50], side: BorderSide(color: Colors.blue[100]!))).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCircle(String label, String value, Color color) {
    return Column(
      children: [
        Container(width: 60, height: 60, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.1), border: Border.all(color: color, width: 2)), child: Center(child: Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)))),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/')),
            icon: const Icon(Icons.home),
            label: const Text('Home'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) =>  HomeScreen()),
              );
            },
            icon: const Icon(Icons.replay),
            label: const Text('Test Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== DOWNLOAD & HELPERS ====================
  Future<void> _downloadFullReport(BuildContext context) async {
    try {
      if (Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (!status.isGranted) { status = await Permission.storage.request(); if (!status.isGranted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Storage permission denied'), backgroundColor: Colors.red)); return; } }
      }

      final links = widget.testResult['links'] as Map<String, dynamic>;
      final technologies = widget.testResult['technologies'] as List<dynamic>;
      final score = widget.testResult['score'] as int;

      String report = "════════════════════════════════════════\n";
      report += "         SQA TESTING AGENT REPORT\n";
      report += "════════════════════════════════════════\n\n";
      report += "TEST DETAILS\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
      report += "URL: ${widget.testResult['url']}\n";
      report += "Date: ${_formatDateTime(widget.testResult['timestamp'])}\n";
      report += "Overall Score: $score/100 (${_getScoreStatus(score)})\n\n";
      report += "LINK ANALYSIS\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
      report += "Total Links: ${links['total']}\n";
      report += "Working Links: ${links['working']}\n";
      report += "Broken Links: ${links['broken']}\n\n";
      if (links['broken'] > 0) {
        report += "BROKEN LINKS DETAILS\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
        final brokenList = links.containsKey('broken_list') ? (links['broken_list'] as List<dynamic>).cast<String>() : <String>[];
        for (int i = 0; i < brokenList.length; i++) { report += "${i + 1}. ${brokenList[i]}\n"; }
        report += "\n";
      }
      report += "DETECTED TECHNOLOGIES\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
      for (var tech in technologies) { report += "- $tech\n"; }
      report += "\n════════════════════════════════════════\nGenerated by SQA Testing Agent\n════════════════════════════════════════\n";

      Directory? directory;
      if (Platform.isAndroid) { directory = Directory('/storage/emulated/0/Download'); if (!await directory.exists()) { directory = await getExternalStorageDirectory(); } }
      else { directory = await getDownloadsDirectory(); }
      if (directory == null) { throw Exception('Cannot access Downloads folder'); }

      final fileName = "SQA_Report_${DateTime.now().millisecondsSinceEpoch}.txt";
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(report);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Report saved to Downloads/$fileName'), backgroundColor: Colors.green, duration: const Duration(seconds: 5), action: SnackBarAction(label: 'OPEN', textColor: Colors.white, onPressed: () { OpenFile.open(file.path); })));
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)); }
  }

  Color _getScoreColor(int score) { if (score >= 80) return Colors.green; if (score >= 60) return Colors.orange; return Colors.red; }
  String _getScoreStatus(int score) { if (score >= 80) return 'EXCELLENT'; if (score >= 60) return 'GOOD'; if (score >= 40) return 'FAIR'; return 'NEEDS IMPROVEMENT'; }
  String _formatDateTime(String timestamp) { try { final dateTime = DateTime.parse(timestamp); return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}'; } catch (e) { return 'Invalid Date'; } }
}