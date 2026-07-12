import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/api_constants.dart';
import '../domain/saved_plan.dart';

final savedPlanServiceProvider = Provider((ref) => SavedPlanService());

final savedPlansProvider = FutureProvider<List<SavedPlan>>((ref) async {
  final service = ref.watch(savedPlanServiceProvider);
  return await service.getSavedPlans();
});

class SavedPlanService {
  Future<List<SavedPlan>> getSavedPlans() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null || session.accessToken == null) {
      throw Exception('Not authenticated');
    }

    final url = Uri.parse('${ApiConstants.baseUrl}/training/saved-plans');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer ${session.accessToken}',
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> plansJson = data['plans'];
      return plansJson.map((json) => SavedPlan.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch saved plans');
    }
  }

  Future<void> setActivePlan(String planId) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null || session.accessToken == null) {
      throw Exception('Not authenticated');
    }

    final url = Uri.parse('${ApiConstants.baseUrl}/training/active-plan');
    final response = await http.post(
      url, 
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'planId': planId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to set active plan');
    }
  }
}
