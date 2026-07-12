class UserProfile {
  final String id;
  final String email;
  final String subscriptionTier;
  final int aiCredits;

  UserProfile({
    required this.id,
    required this.email,
    required this.subscriptionTier,
    required this.aiCredits,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      email: json['email'],
      subscriptionTier: json['subscriptionTier'],
      aiCredits: json['aiCredits'],
    );
  }
}
