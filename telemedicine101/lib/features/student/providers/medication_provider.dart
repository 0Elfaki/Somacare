import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/medication_models.dart';
import '../data/medication_repository.dart';

// Separate enum for provider state (loading, saving, error, idle)
enum MedicationLoadingStatus { idle, loading, saving, error }

// Using MedicationStatus from medication_models.dart (active, completed, paused)
// Using Medication from medication_models.dart

class MedicationState {
  final List<Medication> medications;
  final MedicationLoadingStatus status;
  final String? errorMessage;

  const MedicationState({
    this.medications = const [],
    this.status = MedicationLoadingStatus.idle,
    this.errorMessage,
  });

  bool get isLoading => status == MedicationLoadingStatus.loading;
  bool get isSaving => status == MedicationLoadingStatus.saving;

  List<Medication> get activeMedications =>
      medications.where((m) => m.status == MedicationStatus.active).toList();

  List<Medication> get completedMedications =>
      medications.where((m) => m.status == MedicationStatus.completed).toList();

  List<MedicationReminder> get todayReminders {
    final reminders = <MedicationReminder>[];
    for (final med in activeMedications) {
      for (final reminder in med.reminders) {
        if (reminder.isEnabled) {
          reminders.add(reminder);
        }
      }
    }
    reminders.sort((a, b) {
      final aMinutes = (a.time?.hour ?? 0) * 60 + (a.time?.minute ?? 0);
      final bMinutes = (b.time?.hour ?? 0) * 60 + (b.time?.minute ?? 0);
      return aMinutes.compareTo(bMinutes);
    });
    return reminders;
  }

  MedicationState copyWith({
    List<Medication>? medications,
    MedicationLoadingStatus? status,
    String? errorMessage,
  }) {
    return MedicationState(
      medications: medications ?? this.medications,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class MedicationNotifier extends StateNotifier<MedicationState> {
  MedicationNotifier()
    : super(const MedicationState(status: MedicationLoadingStatus.loading)) {
    loadMedications();
  }

  final _repo = MedicationRepository.instance;

  /// Load all medications for the current user
  Future<void> loadMedications({bool forceRefresh = false}) async {
    state = state.copyWith(status: MedicationLoadingStatus.loading);
    try {
      debugPrint('[MedicationNotifier] loadMedications() starting…');
      final medications = await _repo.fetchMedications(
        forceRefresh: forceRefresh,
      );
      debugPrint(
        '[MedicationNotifier] loadMedications() success: ${medications.length} medications',
      );
      state = state.copyWith(
        medications: medications,
        status: MedicationLoadingStatus.idle,
      );
    } catch (e, st) {
      debugPrint('[MedicationNotifier] loadMedications() error: $e\n$st');
      state = state.copyWith(
        status: MedicationLoadingStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Refresh medications (force network call)
  Future<void> refresh() async {
    await loadMedications(forceRefresh: true);
  }

  /// Add a new medication
  Future<bool> addMedication(Medication medication) async {
    state = state.copyWith(status: MedicationLoadingStatus.saving);
    try {
      final newMedication = await _repo.addMedication(medication);
      if (newMedication != null) {
        state = state.copyWith(
          medications: [...state.medications, newMedication],
          status: MedicationLoadingStatus.idle,
        );
        return true;
      }
      state = state.copyWith(
        status: MedicationLoadingStatus.error,
        errorMessage: 'Failed to add medication',
      );
      return false;
    } catch (e, st) {
      debugPrint('[MedicationNotifier] addMedication() error: $e\n$st');
      state = state.copyWith(
        status: MedicationLoadingStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Update an existing medication
  Future<bool> updateMedication(Medication medication) async {
    state = state.copyWith(status: MedicationLoadingStatus.saving);
    try {
      final updatedMedication = await _repo.updateMedication(medication);
      if (updatedMedication != null) {
        final updatedList = state.medications.map((m) {
          return m.id == medication.id ? updatedMedication : m;
        }).toList();
        state = state.copyWith(
          medications: updatedList,
          status: MedicationLoadingStatus.idle,
        );
        return true;
      }
      state = state.copyWith(
        status: MedicationLoadingStatus.error,
        errorMessage: 'Failed to update medication',
      );
      return false;
    } catch (e, st) {
      debugPrint('[MedicationNotifier] updateMedication() error: $e\n$st');
      state = state.copyWith(
        status: MedicationLoadingStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Delete a medication
  Future<bool> deleteMedication(String medicationId) async {
    state = state.copyWith(status: MedicationLoadingStatus.saving);
    try {
      final success = await _repo.deleteMedication(medicationId);
      if (success) {
        final updatedList = state.medications
            .where((m) => m.id != medicationId)
            .toList();
        state = state.copyWith(
          medications: updatedList,
          status: MedicationLoadingStatus.idle,
        );
        return true;
      }
      state = state.copyWith(
        status: MedicationLoadingStatus.error,
        errorMessage: 'Failed to delete medication',
      );
      return false;
    } catch (e, st) {
      debugPrint('[MedicationNotifier] deleteMedication() error: $e\n$st');
      state = state.copyWith(
        status: MedicationLoadingStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Toggle is_taken_today for a medication
  Future<bool> toggleTaken(String medicationId) async {
    try {
      final updatedMedication = await _repo.toggleTakenToday(medicationId);
      if (updatedMedication != null) {
        final updatedList = state.medications.map((m) {
          return m.id == medicationId ? updatedMedication : m;
        }).toList();
        state = state.copyWith(medications: updatedList);
        return true;
      }
      return false;
    } catch (e, st) {
      debugPrint('[MedicationNotifier] toggleTaken() error: $e\n$st');
      return false;
    }
  }

  /// Add a reminder for a medication
  Future<bool> addReminder(
    String medicationId,
    MedicationReminder reminder,
  ) async {
    try {
      final newReminder = await _repo.addReminder(medicationId, reminder);
      if (newReminder != null) {
        // Reload medications to get updated reminders
        await loadMedications(forceRefresh: true);
        return true;
      }
      return false;
    } catch (e, st) {
      debugPrint('[MedicationNotifier] addReminder() error: $e\n$st');
      return false;
    }
  }

  /// Update a reminder
  Future<bool> updateReminder(MedicationReminder reminder) async {
    try {
      final updatedReminder = await _repo.updateReminder(reminder);
      if (updatedReminder != null) {
        // Reload medications to get updated reminders
        await loadMedications(forceRefresh: true);
        return true;
      }
      return false;
    } catch (e, st) {
      debugPrint('[MedicationNotifier] updateReminder() error: $e\n$st');
      return false;
    }
  }

  /// Delete a reminder
  Future<bool> deleteReminder(String reminderId) async {
    try {
      final success = await _repo.deleteReminder(reminderId);
      if (success) {
        // Reload medications to get updated reminders
        await loadMedications(forceRefresh: true);
        return true;
      }
      return false;
    } catch (e, st) {
      debugPrint('[MedicationNotifier] deleteReminder() error: $e\n$st');
      return false;
    }
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

final medicationProvider =
    StateNotifierProvider.autoDispose<MedicationNotifier, MedicationState>(
      (ref) => MedicationNotifier(),
    );
