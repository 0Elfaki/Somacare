import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'medication_models.dart';

/// Repository that wraps Supabase calls for medications.
///
/// Features:
/// - In-memory cache with TTL to avoid redundant network hits.
/// - CRUD operations for medications and reminders.
/// - Integration with existing Medication and MedicationReminder models.
class MedicationRepository {
  MedicationRepository._();
  static final instance = MedicationRepository._();

  List<Medication>? _cachedMedications;
  DateTime? _cachedAt;

  /// Cache is valid for 2 minutes.
  static const _ttl = Duration(minutes: 2);

  SupabaseClient get _client => Supabase.instance.client;

  bool get _cacheValid =>
      _cachedMedications != null &&
      _cachedAt != null &&
      DateTime.now().difference(_cachedAt!) < _ttl;

  /// Get the current user ID from Supabase auth
  String? get _userId => _client.auth.currentUser?.id;

  /// Fetch all medications for the current user.
  /// Returns cached copy when still fresh.
  Future<List<Medication>> fetchMedications({bool forceRefresh = false}) async {
    if (!forceRefresh && _cacheValid) return _cachedMedications!;

    final userId = _userId;
    if (userId == null) {
      debugPrint(
        '[MedicationRepository] No authenticated user, returning empty list',
      );
      _cachedMedications = [];
      _cachedAt = DateTime.now();
      return [];
    }

    try {
      final data = await _client
          .from('medications')
          .select('*')
          .eq('student_id', userId)
          .order('created_at', ascending: false);

      final medications = <Medication>[];
      for (final item in data) {
        // Fetch reminders for each medication
        final reminders = await fetchReminders(item['id'] as String);

        medications.add(Medication.fromMap(item, reminders: reminders));
      }

      _cachedMedications = medications;
      _cachedAt = DateTime.now();
      return medications;
    } catch (e, st) {
      debugPrint('[MedicationRepository] fetchMedications() error: $e\n$st');
      _cachedMedications = [];
      _cachedAt = DateTime.now();
      return [];
    }
  }

  /// Fetch reminders for a specific medication
  Future<List<MedicationReminder>> fetchReminders(String medicationId) async {
    try {
      final data = await _client
          .from('medication_reminders')
          .select('*')
          .eq('medication_id', medicationId)
          .order('scheduled_time', ascending: true);

      return data.map((item) => MedicationReminder.fromMap(item)).toList();
    } catch (e, st) {
      debugPrint('[MedicationRepository] fetchReminders() error: $e\n$st');
      return [];
    }
  }

  /// Add a new medication
  Future<Medication?> addMedication(Medication medication) async {
    final userId = _userId;
    if (userId == null) {
      debugPrint(
        '[MedicationRepository] No authenticated user, cannot add medication',
      );
      return null;
    }

    try {
      final data = medication.toMap();
      data['student_id'] = userId;
      data.remove('id'); // Let database generate UUID

      final result = await _client
          .from('medications')
          .insert(data)
          .select()
          .single();

      // Invalidate cache
      _invalidateCache();

      return Medication.fromMap(result);
    } catch (e, st) {
      debugPrint('[MedicationRepository] addMedication() error: $e\n$st');
      return null;
    }
  }

  /// Update an existing medication
  Future<Medication?> updateMedication(Medication medication) async {
    try {
      final data = medication.toMap();
      data['updated_at'] = DateTime.now().toIso8601String();

      final result = await _client
          .from('medications')
          .update(data)
          .eq('id', medication.id)
          .select()
          .single();

      // Fetch updated reminders
      final reminders = await fetchReminders(medication.id);

      // Invalidate cache
      _invalidateCache();

      return Medication.fromMap(result, reminders: reminders);
    } catch (e, st) {
      debugPrint('[MedicationRepository] updateMedication() error: $e\n$st');
      return null;
    }
  }

  /// Delete a medication
  Future<bool> deleteMedication(String medicationId) async {
    try {
      await _client.from('medications').delete().eq('id', medicationId);

      // Invalidate cache
      _invalidateCache();

      return true;
    } catch (e, st) {
      debugPrint('[MedicationRepository] deleteMedication() error: $e\n$st');
      return false;
    }
  }

  /// Toggle is_taken_today for a medication
  Future<Medication?> toggleTakenToday(String medicationId) async {
    try {
      // First get current state
      final current = await _client
          .from('medications')
          .select('is_taken_today')
          .eq('id', medicationId)
          .maybeSingle();

      if (current == null) return null;

      final newValue = !(current['is_taken_today'] as bool? ?? false);

      final result = await _client
          .from('medications')
          .update({
            'is_taken_today': newValue,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', medicationId)
          .select()
          .single();

      // Fetch reminders
      final reminders = await fetchReminders(medicationId);

      // Invalidate cache
      _invalidateCache();

      return Medication.fromMap(result, reminders: reminders);
    } catch (e, st) {
      debugPrint('[MedicationRepository] toggleTakenToday() error: $e\n$st');
      return null;
    }
  }

  /// Add a reminder for a medication
  Future<MedicationReminder?> addReminder(
    String medicationId,
    MedicationReminder reminder,
  ) async {
    final userId = _userId;
    if (userId == null) {
      debugPrint(
        '[MedicationRepository] No authenticated user, cannot add reminder',
      );
      return null;
    }

    try {
      final data = {
        'medication_id': medicationId,
        'student_id': userId,
        'scheduled_time': _timeOfDayToString(
          reminder.time ?? const TimeOfDay(hour: 8, minute: 0),
        ),
        'days': reminder.days,
        'is_enabled': reminder.isEnabled,
      };

      final result = await _client
          .from('medication_reminders')
          .insert(data)
          .select()
          .single();

      return MedicationReminder.fromMap(result);
    } catch (e, st) {
      debugPrint('[MedicationRepository] addReminder() error: $e\n$st');
      return null;
    }
  }

  /// Update a reminder
  Future<MedicationReminder?> updateReminder(
    MedicationReminder reminder,
  ) async {
    try {
      final data = {
        'scheduled_time': _timeOfDayToString(
          reminder.time ?? const TimeOfDay(hour: 8, minute: 0),
        ),
        'days': reminder.days,
        'is_enabled': reminder.isEnabled,
      };

      final result = await _client
          .from('medication_reminders')
          .update(data)
          .eq('id', reminder.id)
          .select()
          .single();

      return MedicationReminder.fromMap(result);
    } catch (e, st) {
      debugPrint('[MedicationRepository] updateReminder() error: $e\n$st');
      return null;
    }
  }

  /// Delete a reminder
  Future<bool> deleteReminder(String reminderId) async {
    try {
      await _client.from('medication_reminders').delete().eq('id', reminderId);

      return true;
    } catch (e, st) {
      debugPrint('[MedicationRepository] deleteReminder() error: $e\n$st');
      return false;
    }
  }

  /// Invalidate the cache so the next fetch hits the network
  void _invalidateCache() {
    _cachedMedications = null;
    _cachedAt = null;
  }

  /// Convert TimeOfDay to HH:MM string for database
  String _timeOfDayToString(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
