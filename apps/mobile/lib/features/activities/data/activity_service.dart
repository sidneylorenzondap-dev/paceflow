import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/api_constants.dart';
import '../domain/run_session.dart';

final activityServiceProvider = Provider((ref) => ActivityService());

final runHistoryProvider = FutureProvider<List<RunSession>>((ref) async {
  final service = ref.watch(activityServiceProvider);
  return await service.getRunHistory();
});

class ActivityService {
  Future<List<RunSession>> getRunHistory() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null || session.accessToken == null) {
      throw Exception('Not authenticated');
    }

    final url = Uri.parse('${ApiConstants.baseUrl}/training/history');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer ${session.accessToken}',
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> historyJson = data['history'] ?? [];
      return historyJson.map((json) => RunSession.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch run history: ${response.statusCode}');
    }
  }
}
