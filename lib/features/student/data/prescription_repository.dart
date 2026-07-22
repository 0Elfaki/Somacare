import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'medication_models.dart';

/// Repository that wraps Supabase calls for prescriptions.
///
/// Features:
/// - In-memory cache with TTL to avoid redundant network hits.
/// - CRUD operations for prescriptions and refill requests.
/// - Integration with existing Prescription and MedicationReminder models.
class PrescriptionRepository {
  PrescriptionRepository._();
  static final instance = PrescriptionRepository._();

  List<Prescription>? _cachedPrescriptions;
  DateTime? _cachedAt;

  /// Cache is valid for 2 minutes.
  static const _ttl = Duration(minutes: 2);

  SupabaseClient get _client => Supabase.instance.client;

  bool get _cacheValid =>
      _cachedPrescriptions != null &&
      _cachedAt != null &&
      DateTime.now().difference(_cachedAt!) < _ttl;

  /// Get the current user ID from Supabase auth
  String? get _userId => _client.auth.currentUser?.id;

  /// Fetch all prescriptions for the current user.
  /// Returns cached copy when still fresh.
  Future<List<Prescription>> fetchPrescriptions({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cacheValid) return _cachedPrescriptions!;

    final userId = _userId;
    if (userId == null) {
      debugPrint(
        '[PrescriptionRepository] No authenticated user, returning empty list',
      );
      _cachedPrescriptions = [];
      _cachedAt = DateTime.now();
      return [];
    }

    try {
      final data = await _client
          .from('prescriptions')
          .select('*')
          .eq('student_id', userId)
          .order('date_prescribed', ascending: false);

      final prescriptions = <Prescription>[];
      for (final item in data) {
        // Fetch reminders for each prescription
        final reminders = await fetchPrescriptionReminders(
          item['id'] as String,
        );

        prescriptions.add(Prescription.fromMap(item, reminders: reminders));
      }

      _cachedPrescriptions = prescriptions;
      _cachedAt = DateTime.now();
      return prescriptions;
    } catch (e, st) {
      debugPrint(
        '[PrescriptionRepository] fetchPrescriptions() error: $e\n$st',
      );
      _cachedPrescriptions = [];
      _cachedAt = DateTime.now();
      return [];
    }
  }

  /// Get a single prescription by ID
  Future<Prescription?> getPrescription(String id) async {
    try {
      final data = await _client
          .from('prescriptions')
          .select('*')
          .eq('id', id)
          .maybeSingle();

      if (data == null) return null;

      // Fetch reminders for the prescription
      final reminders = await fetchPrescriptionReminders(id);

      return Prescription.fromMap(data, reminders: reminders);
    } catch (e, st) {
      debugPrint('[PrescriptionRepository] getPrescription() error: $e\n$st');
      return null;
    }
  }

  /// Fetch reminders for a specific prescription
  Future<List<MedicationReminder>> fetchPrescriptionReminders(
    String prescriptionId,
  ) async {
    try {
      final data = await _client
          .from('prescription_reminders')
          .select('*')
          .eq('prescription_id', prescriptionId)
          .order('scheduled_time', ascending: true);

      return data.map((item) => MedicationReminder.fromMap(item)).toList();
    } catch (e, st) {
      debugPrint(
        '[PrescriptionRepository] fetchPrescriptionReminders() error: $e\n$st',
      );
      return [];
    }
  }

  /// Request a refill for a prescription
  Future<bool> requestRefill(String prescriptionId) async {
    final userId = _userId;
    if (userId == null) {
      debugPrint(
        '[PrescriptionRepository] No authenticated user, cannot request refill',
      );
      return false;
    }

    try {
      final data = {
        'prescription_id': prescriptionId,
        'student_id': userId,
        'status': 'pending',
      };

      await _client.from('prescription_refills').insert(data);

      // Invalidate cache
      _invalidateCache();

      return true;
    } catch (e, st) {
      debugPrint('[PrescriptionRepository] requestRefill() error: $e\n$st');
      return false;
    }
  }

  /// Fetch refill requests for the current user
  Future<List<Map<String, dynamic>>> fetchRefillRequests() async {
    final userId = _userId;
    if (userId == null) {
      debugPrint(
        '[PrescriptionRepository] No authenticated user, returning empty list',
      );
      return [];
    }

    try {
      final data = await _client
          .from('prescription_refills')
          .select('*')
          .eq('student_id', userId)
          .order('requested_at', ascending: false);

      return List<Map<String, dynamic>>.from(data);
    } catch (e, st) {
      debugPrint(
        '[PrescriptionRepository] fetchRefillRequests() error: $e\n$st',
      );
      return [];
    }
  }

  /// Add a new prescription (typically called by doctor)
  Future<Prescription?> addPrescription(Prescription prescription) async {
    final userId = _userId;
    if (userId == null) {
      debugPrint(
        '[PrescriptionRepository] No authenticated user, cannot add prescription',
      );
      return null;
    }

    try {
      final data = prescription.toMap();
      data['student_id'] = userId;
      data.remove('id'); // Let database generate UUID

      final result = await _client
          .from('prescriptions')
          .insert(data)
          .select()
          .single();

      // Invalidate cache
      _invalidateCache();

      return Prescription.fromMap(result);
    } catch (e, st) {
      debugPrint('[PrescriptionRepository] addPrescription() error: $e\n$st');
      return null;
    }
  }

  /// Update an existing prescription
  Future<Prescription?> updatePrescription(Prescription prescription) async {
    try {
      final data = prescription.toMap();
      data['updated_at'] = DateTime.now().toIso8601String();

      final result = await _client
          .from('prescriptions')
          .update(data)
          .eq('id', prescription.id)
          .select()
          .single();

      // Fetch updated reminders
      final reminders = await fetchPrescriptionReminders(prescription.id);

      // Invalidate cache
      _invalidateCache();

      return Prescription.fromMap(result, reminders: reminders);
    } catch (e, st) {
      debugPrint(
        '[PrescriptionRepository] updatePrescription() error: $e\n$st',
      );
      return null;
    }
  }

  /// Delete a prescription
  Future<bool> deletePrescription(String prescriptionId) async {
    try {
      await _client.from('prescriptions').delete().eq('id', prescriptionId);

      // Invalidate cache
      _invalidateCache();

      return true;
    } catch (e, st) {
      debugPrint(
        '[PrescriptionRepository] deletePrescription() error: $e\n$st',
      );
      return false;
    }
  }

  /// Invalidate the cache so the next fetch hits the network
  void _invalidateCache() {
    _cachedPrescriptions = null;
    _cachedAt = null;
  }
}
