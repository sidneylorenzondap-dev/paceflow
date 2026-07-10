class TrainingWorkout {
  final String day;
  final String type;
  final String description;
  final int? targetDistanceMeters;

  TrainingWorkout({
    required this.day,
    required this.type,
    required this.description,
    this.targetDistanceMeters,
  });

  factory TrainingWorkout.fromJson(Map<String, dynamic> json) {
    return TrainingWorkout(
      day: json['day'] ?? 'Unknown',
      type: json['type'] ?? 'Rest',
      description: json['description'] ?? '',
      targetDistanceMeters: json['targetDistanceMeters'],
    );
  }
}
