import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'medical_history_model.dart';

/// Repository that wraps Supabase calls for medical history.
///
/// Features:
/// - In-memory cache with TTL to avoid redundant network hits.
/// - Fetch returns existing record or creates new one.
/// - Save performs upsert to create/update record.
class MedicalHistoryRepository {
  MedicalHistoryRepository._();
  static final instance = MedicalHistoryRepository._();

  MedicalHistory? _cached;
  DateTime? _cachedAt;

  /// Cache is valid for 2 minutes.
  static const _ttl = Duration(minutes: 2);

  SupabaseClient get _client => Supabase.instance.client;

  bool get _cacheValid =>
      _cached != null &&
      _cachedAt != null &&
      DateTime.now().difference(_cachedAt!) < _ttl;

  /// Fetch medical history, returning cached copy when still fresh.
  /// If no record exists, returns a new empty record with user ID.
  ///
  /// For testing/demo purposes, returns mock data if no record exists.
  Future<MedicalHistory> fetch({bool forceRefresh = false}) async {
    if (!forceRefresh && _cacheValid) return _cached!;

    final user = _client.auth.currentUser;
    if (user == null) {
      debugPrint(
        '[MedicalHistoryRepository] No authenticated user, returning default history',
      );
      const defaultHistory = MedicalHistory(studentId: '');
      _cached = defaultHistory;
      _cachedAt = DateTime.now();
      return defaultHistory;
    }

    try {
      final data = await _client
          .from('medical_histories')
          .select('*')
          .eq('student_id', user.id)
          .maybeSingle();

      // If no data exists, return mock data for demo/testing
      if (data == null) {
        debugPrint(
          '[MedicalHistoryRepository] No data found, returning mock data for demo',
        );
        final mockHistory = _getMockData(user.id);
        _cached = mockHistory;
        _cachedAt = DateTime.now();
        return mockHistory;
      }

      final history = MedicalHistory.fromMap(data, userId: user.id);

      _cached = history;
      _cachedAt = DateTime.now();
      return history;
    } catch (e, st) {
      debugPrint('[MedicalHistoryRepository] fetch() error: $e\n$st');
      // On DB error, return mock data for demo
      final mockHistory = _getMockData(user.id);
      _cached = mockHistory;
      _cachedAt = DateTime.now();
      return mockHistory;
    }
  }

  /// Get mock medical history data for demo/testing
  MedicalHistory _getMockData(String userId) {
    return MedicalHistory(
      id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
      studentId: userId,
      chronicConditions:
          'Asthma (diagnosed at age 8), managed with daily inhaler',
      pastIllnesses: 'COVID-19 (2022, mild symptoms), Chickenpox (2015)',
      hospitalizations: 'Appendectomy - 2018 at City Hospital',
      familyConditions:
          'Father: Hypertension (age 50), Mother: Type 2 Diabetes (age 55)',
      surgicalHistory: 'Appendectomy (2018)',
      allergies: 'Penicillin (rash), Pollen (seasonal allergies)',
      immunizations:
          'All childhood vaccinations up to date. Last flu shot: 2025',
      socialHistory:
          'Non-smoker, occasional alcohol (social events), exercises 3x weekly',
      reviewOfSystems: 'No current complaints. Occasional seasonal allergies.',
      currentMedications: 'Albuterol inhaler (as needed), Vitamin D supplement',
      isApproved:
          false, // Default to NOT approved - must wait for doctor approval
    );
  }

  /// Persist changes and update the local cache optimistically.
  /// Uses upsert to handle both insert (new record) and update (existing record).
  Future<void> save(MedicalHistory history) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      debugPrint(
        '[MedicalHistoryRepository] No authenticated user, cannot save',
      );
      return;
    }

    // Ensure student_id is set
    final historyToSave = history.studentId.isEmpty
        ? history.copyWith(studentId: user.id)
        : history;

    await _client.from('medical_histories').upsert(historyToSave.toMap());
    _cached = historyToSave;
    _cachedAt = DateTime.now();
  }

  /// Invalidate the cache so the next [fetch] hits the network.
  void invalidate() {
    _cached = null;
    _cachedAt = null;
  }

  /// Fetch medical history for a specific student (by doctor)
  Future<MedicalHistory> fetchForStudent(String studentId) async {
    try {
      final data = await _client
          .from('medical_histories')
          .select('*')
          .eq('student_id', studentId)
          .maybeSingle();

      if (data == null) {
        // Return empty history for new students
        return MedicalHistory(studentId: studentId);
      }

      return MedicalHistory.fromMap(data, userId: studentId);
    } catch (e) {
      debugPrint('[MedicalHistoryRepository] fetchForStudent() error: $e');
      return MedicalHistory(studentId: studentId);
    }
  }

  /// Revoke approval (for doctors to cancel approval)
  Future<void> revokeApproval(String historyId) async {
    await _client
        .from('medical_histories')
        .update({
          'is_approved': false,
          'approved_by': null,
          'approved_at': null,
        })
        .eq('id', historyId);
    invalidate();
  }

  /// Approve medical history (for doctors)
  Future<void> approve(String historyId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client
        .from('medical_histories')
        .update({
          'is_approved': true,
          'approved_by': user.id,
          'approved_at': DateTime.now().toIso8601String(),
        })
        .eq('id', historyId);
    invalidate();
  }

  /// Deny medical history with comment (for doctors)
  Future<void> deny(String historyId, String reason) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client
        .from('medical_histories')
        .update({
          'is_approved': false,
          'denial_reason': reason,
          'denied_by': user.id,
          'denied_at': DateTime.now().toIso8601String(),
          // Clear approval fields if previously approved
          'approved_by': null,
          'approved_at': null,
        })
        .eq('id', historyId);
    invalidate();
  }
}
