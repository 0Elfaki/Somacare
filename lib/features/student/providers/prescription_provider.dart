import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/medication_models.dart';
import '../data/prescription_repository.dart';

// ── State ────────────────────────────────────────────────────────────────────

enum PrescriptionLoadingStatus { idle, loading, saving, error }

class PrescriptionState {
  final List<Prescription> prescriptions;
  final List<MedicationReminder> reminders;
  final List<Map<String, dynamic>> refillRequests;
  final PrescriptionLoadingStatus status;
  final String? errorMessage;

  const PrescriptionState({
    this.prescriptions = const [],
    this.reminders = const [],
    this.refillRequests = const [],
    this.status = PrescriptionLoadingStatus.idle,
    this.errorMessage,
  });

  bool get isLoading => status == PrescriptionLoadingStatus.loading;
  bool get isSaving => status == PrescriptionLoadingStatus.saving;

  /// Get active prescriptions
  List<Prescription> get activePrescriptions => prescriptions
      .where((p) => p.status == PrescriptionStatus.active)
      .toList();

  /// Get pending prescriptions
  List<Prescription> get pendingPrescriptions => prescriptions
      .where((p) => p.status == PrescriptionStatus.pending)
      .toList();

  /// Get completed/expired prescriptions
  List<Prescription> get historyPrescriptions => prescriptions
      .where(
        (p) =>
            p.status == PrescriptionStatus.completed ||
            p.status == PrescriptionStatus.expired,
      )
      .toList();

  /// Get prescriptions expiring soon (within 7 days)
  List<Prescription> get expiringSoonPrescriptions => prescriptions
      .where(
        (p) =>
            p.status == PrescriptionStatus.active &&
            p.expiryDate != null &&
            p.expiryDate!.difference(DateTime.now()).inDays <= 7,
      )
      .toList();

  PrescriptionState copyWith({
    List<Prescription>? prescriptions,
    List<MedicationReminder>? reminders,
    List<Map<String, dynamic>>? refillRequests,
    PrescriptionLoadingStatus? status,
    String? errorMessage,
  }) {
    return PrescriptionState(
      prescriptions: prescriptions ?? this.prescriptions,
      reminders: reminders ?? this.reminders,
      refillRequests: refillRequests ?? this.refillRequests,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class PrescriptionNotifier extends StateNotifier<PrescriptionState> {
  PrescriptionNotifier()
    : super(
        const PrescriptionState(status: PrescriptionLoadingStatus.loading),
      ) {
    loadPrescriptions();
  }

  final _repo = PrescriptionRepository.instance;

  /// Load all prescriptions for the current user
  Future<void> loadPrescriptions({bool forceRefresh = false}) async {
    state = state.copyWith(status: PrescriptionLoadingStatus.loading);
    try {
      debugPrint('[PrescriptionNotifier] loadPrescriptions() starting…');
      final prescriptions = await _repo.fetchPrescriptions(
        forceRefresh: forceRefresh,
      );

      // Collect all reminders from prescriptions
      final allReminders = <MedicationReminder>[];
      for (final prescription in prescriptions) {
        allReminders.addAll(prescription.reminders);
      }

      // Sort reminders by scheduled time
      allReminders.sort((a, b) {
        if (a.scheduledTime == null && b.scheduledTime == null) return 0;
        if (a.scheduledTime == null) return 1;
        if (b.scheduledTime == null) return -1;
        return a.scheduledTime!.compareTo(b.scheduledTime!);
      });

      debugPrint('[PrescriptionNotifier] loadPrescriptions() success');
      state = state.copyWith(
        prescriptions: prescriptions,
        reminders: allReminders,
        status: PrescriptionLoadingStatus.idle,
      );
    } catch (e, st) {
      debugPrint('[PrescriptionNotifier] loadPrescriptions() error: $e\n$st');
      state = state.copyWith(
        status: PrescriptionLoadingStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Request a refill for a prescription
  Future<bool> requestRefill(String prescriptionId) async {
    state = state.copyWith(status: PrescriptionLoadingStatus.saving);
    try {
      debugPrint('[PrescriptionNotifier] requestRefill() starting…');
      final success = await _repo.requestRefill(prescriptionId);

      if (success) {
        // Reload prescriptions and refill requests
        await loadPrescriptions(forceRefresh: true);
        await loadRefillRequests();
      }

      state = state.copyWith(status: PrescriptionLoadingStatus.idle);
      return success;
    } catch (e, st) {
      debugPrint('[PrescriptionNotifier] requestRefill() error: $e\n$st');
      state = state.copyWith(
        status: PrescriptionLoadingStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Load refill requests for the current user
  Future<void> loadRefillRequests() async {
    try {
      final requests = await _repo.fetchRefillRequests();
      state = state.copyWith(refillRequests: requests);
    } catch (e, st) {
      debugPrint('[PrescriptionNotifier] loadRefillRequests() error: $e\n$st');
    }
  }

  /// Refresh prescriptions (pull-to-refresh)
  Future<void> refresh() async {
    await loadPrescriptions(forceRefresh: true);
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

final prescriptionProvider =
    StateNotifierProvider.autoDispose<PrescriptionNotifier, PrescriptionState>(
      (ref) => PrescriptionNotifier(),
    );
