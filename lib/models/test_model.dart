class TestResult {
  final String url;
  final DateTime timestamp;
  final LinkAnalysis links;
  final List<String> technologies;
  final int performanceScore;
  final int seoScore;
  final int securityScore;
  final List<String> recommendations;
  final List<String> tests;
  final int duration;

  TestResult({
    required this.url,
    required this.timestamp,
    required this.links,
    required this.technologies,
    required this.performanceScore,
    required this.seoScore,
    required this.securityScore,
    required this.recommendations,
    required this.tests,
    required this.duration,
  });

  int get overallScore {
    final scores = [performanceScore, seoScore, securityScore];
    final sum = scores.reduce((a, b) => a + b);
    return (sum / scores.length).round();
  }

  factory TestResult.fromJson(Map<String, dynamic> json) {
    return TestResult(
      url: json['url'],
      timestamp: DateTime.parse(json['timestamp']),
      links: LinkAnalysis.fromJson(json['links']),
      technologies: List<String>.from(json['technologies']),
      performanceScore: json['performanceScore'],
      seoScore: json['seoScore'],
      securityScore: json['securityScore'],
      recommendations: List<String>.from(json['recommendations']),
      tests: List<String>.from(json['tests']),
      duration: json['duration'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'timestamp': timestamp.toIso8601String(),
      'links': links.toJson(),
      'technologies': technologies,
      'performanceScore': performanceScore,
      'seoScore': seoScore,
      'securityScore': securityScore,
      'recommendations': recommendations,
      'tests': tests,
      'duration': duration,
    };
  }
}

class LinkAnalysis {
  final int total;
  final int working;
  final int broken;
  final List<String> brokenLinks;

  LinkAnalysis({
    required this.total,
    required this.working,
    required this.broken,
    required this.brokenLinks,
  });

  factory LinkAnalysis.fromJson(Map<String, dynamic> json) {
    return LinkAnalysis(
      total: json['total'],
      working: json['working'],
      broken: json['broken'],
      brokenLinks: List<String>.from(json['brokenLinks']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'working': working,
      'broken': broken,
      'brokenLinks': brokenLinks,
    };
  }
}