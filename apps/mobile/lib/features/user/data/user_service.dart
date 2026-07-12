import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/api_constants.dart';
import '../domain/user_profile.dart';

final userServiceProvider = Provider((ref) => UserService());

final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  final service = ref.watch(userServiceProvider);
  return await service.getProfile();
});

class UserService {
  Future<UserProfile> getProfile() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null || session.accessToken == null) {
      throw Exception('Not authenticated');
    }

    final url = Uri.parse('${ApiConstants.baseUrl}/user/profile');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer ${session.accessToken}',
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserProfile.fromJson(data);
    } else {
      throw Exception('Failed to fetch user profile: ${response.statusCode}');
    }
  }
}
