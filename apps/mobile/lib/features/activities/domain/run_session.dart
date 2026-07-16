class RunSession {
  final String id;
  final String courseId;
  final DateTime date;
  final int totalTime;
  final double avgPace;
  final bool isBaseline;

  RunSession({
    required this.id,
    required this.courseId,
    required this.date,
    required this.totalTime,
    required this.avgPace,
    this.isBaseline = false,
  });

  factory RunSession.fromJson(Map<String, dynamic> json) {
    return RunSession(
      id: json['id'],
      courseId: json['courseId'],
      date: DateTime.parse(json['date']),
      totalTime: json['totalTime'],
      avgPace: (json['avgPace'] as num).toDouble(),
      isBaseline: json['isBaseline'] ?? false,
    );
  }
}
