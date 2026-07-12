class SavedPlan {
  final String id;
  final String goal;
  final DateTime createdAt;
  final dynamic planData;

  SavedPlan({
    required this.id,
    required this.goal,
    required this.createdAt,
    required this.planData,
  });

  factory SavedPlan.fromJson(Map<String, dynamic> json) {
    return SavedPlan(
      id: json['id'],
      goal: json['goal'],
      createdAt: DateTime.parse(json['createdAt']),
      planData: json['planData'],
    );
  }
}
