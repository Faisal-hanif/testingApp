class AppConstants {

  // static const String pythonServer = "http://192.168.1.100:5000";
  // static const String pythonServer = "http://10.0.2.2:5000";
  static const String pythonServer = "http://192.168.100.159:5000";
  // static const String pythonServer = "http://192.168.100.138:5000";

  static const List<Map<String, dynamic>> testOptions = [
    {
      'id': 'links',
      'name': '🔗 Link Checker',
      'description': 'Checks all website links'
    },
    {
      'id': 'tech',
      'name': '🔧 Technology Detector',
      'description': 'Detects tech stack'
    },

    {
      'id': 'github',
      'name': '🐙 GitHub Analyzer',
      'description': 'Analyzes GitHub repository'
    },
  ];
}