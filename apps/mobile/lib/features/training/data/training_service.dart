import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../domain/training_workout.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrainingServiceResponse {
  final List<TrainingWorkout>? plan;
  final String? adjustmentNotice;
  final bool requiresBaseline;
  final String? errorMessage;
  final String? baselineInstruction;

  TrainingServiceResponse({
    this.plan,
    this.adjustmentNotice,
    this.requiresBaseline = false,
    this.errorMessage,
    this.baselineInstruction,
  });
}

class TrainingService {
  Future<TrainingServiceResponse> getTrainingPlan(String goal) async {
    try {
      final encodedGoal = Uri.encodeComponent(goal);
      final url = Uri.parse('${ApiConstants.baseUrl}/training/plan?goal=$encodedGoal');
      
      final session = Supabase.instance.client.auth.currentSession;
      final token = session?.accessToken;

      final response = await http.get(url, headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List planList = [];
        String? notice;
        
        if (data['plan'] is List) {
          planList = data['plan'] as List;
        } else if (data['plan'] is Map) {
          planList = data['plan']['workouts'] as List? ?? [];
          notice = data['plan']['goalAdjustmentNotice'] as String?;
        }

        final parsedList = planList.map((e) => TrainingWorkout.fromJson(e)).toList();
        return TrainingServiceResponse(plan: parsedList, adjustmentNotice: notice);
      } else if (response.statusCode == 428) {
        final data = jsonDecode(response.body);
        return TrainingServiceResponse(
          requiresBaseline: true,
          baselineInstruction: data['instruction'],
        );
      } else {
        return TrainingServiceResponse(
            errorMessage: 'Failed to load plan: ${response.statusCode}');
      }
    } catch (e) {
      return TrainingServiceResponse(errorMessage: 'Network error: $e');
    }
  }

  Future<TrainingServiceResponse> adjustTrainingPlan(String feedback) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/training/plan/adjust');
      
      final session = Supabase.instance.client.auth.currentSession;
      final token = session?.accessToken;

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'feedback': feedback}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List planList = [];
        String? notice;
        
        if (data['plan'] is List) {
          planList = data['plan'] as List;
        } else if (data['plan'] is Map) {
          planList = data['plan']['workouts'] as List? ?? [];
          notice = data['plan']['goalAdjustmentNotice'] as String?;
        }

        final parsedList = planList.map((e) => TrainingWorkout.fromJson(e)).toList();
        return TrainingServiceResponse(plan: parsedList, adjustmentNotice: notice);
      } else {
        return TrainingServiceResponse(
            errorMessage: 'Failed to adjust plan: ${response.statusCode}');
      }
    } catch (e) {
      return TrainingServiceResponse(errorMessage: 'Network error: $e');
    }
  }
}
