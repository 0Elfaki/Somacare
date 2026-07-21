import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'lab_result_model.dart';

/// Repository for the `lab_results` table.
///
/// Requires the `lab_results` table to exist (see
/// `create_lab_results.sql`). If the table is missing (migration not yet
/// run), every method fails soft and returns an empty list rather than
/// throwing, matching the pattern used by [MedicalHistoryRepository].
class LabResultRepository {
  LabResultRepository._();
  static final instance = LabResultRepository._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<LabResult>> fetchForStudent(String studentId) async {
    try {
      final data = await _client
          .from('lab_results')
          .select()
          .eq('student_id', studentId)
          .order('test_date', ascending: false);
      return List<Map<String, dynamic>>.from(data)
          .map(LabResult.fromMap)
          .toList();
    } catch (e) {
      debugPrint('[LabResultRepository] fetchForStudent() error: $e');
      return [];
    }
  }

  Future<List<LabResult>> fetchMine() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    return fetchForStudent(userId);
  }

  Future<bool> add(LabResult result) async {
    try {
      await _client.from('lab_results').insert(result.toMap());
      return true;
    } catch (e) {
      debugPrint('[LabResultRepository] add() error: $e');
      return false;
    }
  }
}
