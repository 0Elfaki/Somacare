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
  Future<MedicalHistory> fetch({bool forceRefresh = false}) async {
    if (!forceRefresh && _cacheValid) return _cached!;

    final user = _client.auth.currentUser;
    if (user == null) {
      debugPrint(
        '[MedicalHistoryRepository] No authenticated user, returning default history',
      );
      final defaultHistory = MedicalHistory(studentId: '');
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

      final history = MedicalHistory.fromMap(data, userId: user.id);

      _cached = history;
      _cachedAt = DateTime.now();
      return history;
    } catch (e, st) {
      debugPrint('[MedicalHistoryRepository] fetch() error: $e\n$st');
      // On DB error, return default history to avoid crashing the UI
      final defaultHistory = MedicalHistory(studentId: user.id);
      _cached = defaultHistory;
      _cachedAt = DateTime.now();
      return defaultHistory;
    }
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
}
