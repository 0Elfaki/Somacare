import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/student_profile_model.dart';
import '../data/profile_repository.dart';

// ── State ────────────────────────────────────────────────────────────────────

enum ProfileStatus { idle, loading, saving, error }

class ProfileState {
  final StudentProfile? profile;
  final ProfileStatus status;
  final String? errorMessage;
  final bool isEditing;

  const ProfileState({
    this.profile,
    this.status = ProfileStatus.idle,
    this.errorMessage,
    this.isEditing = false,
  });

  bool get isLoading => status == ProfileStatus.loading;
  bool get isSaving => status == ProfileStatus.saving;

  ProfileState copyWith({
    StudentProfile? profile,
    ProfileStatus? status,
    String? errorMessage,
    bool? isEditing,
  }) => ProfileState(
    profile: profile ?? this.profile,
    status: status ?? this.status,
    errorMessage: errorMessage,
    isEditing: isEditing ?? this.isEditing,
  );
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier() : super(const ProfileState(status: ProfileStatus.loading)) {
    _load();
  }

  final _repo = ProfileRepository.instance;
  Timer? _debounce;

  /// Initial async load – uses cached data when available.
  Future<void> _load() async {
    try {
      debugPrint('[ProfileNotifier] _load() starting…');
      final profile = await _repo.fetch();
      debugPrint('[ProfileNotifier] _load() success: ${profile.fullName}');
      state = state.copyWith(profile: profile, status: ProfileStatus.idle);
    } catch (e, st) {
      debugPrint('[ProfileNotifier] _load() error: $e\n$st');
      state = state.copyWith(
        status: ProfileStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Pull-to-refresh – forces a network call.
  Future<void> refresh() async {
    state = state.copyWith(status: ProfileStatus.loading);
    try {
      final profile = await _repo.fetch(forceRefresh: true);
      state = state.copyWith(profile: profile, status: ProfileStatus.idle);
    } catch (e) {
      state = state.copyWith(
        status: ProfileStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void toggleEditing() {
    state = state.copyWith(isEditing: !state.isEditing);
  }

  void cancelEditing() {
    state = state.copyWith(isEditing: false);
    // Reload to discard unsaved changes.
    _load();
  }

  /// Update a field locally (optimistic). Debounces auto-save.
  void updateField(StudentProfile Function(StudentProfile) updater) {
    if (state.profile == null) return;
    state = state.copyWith(profile: updater(state.profile!));
  }

  /// Debounced save – waits 600 ms of inactivity before persisting.
  void debouncedSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () => save());
  }

  /// Immediate save.
  Future<bool> save() async {
    if (state.profile == null) return false;
    state = state.copyWith(status: ProfileStatus.saving);
    try {
      await _repo.save(state.profile!);
      state = state.copyWith(status: ProfileStatus.idle, isEditing: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: ProfileStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Change password via Supabase Auth.
  Future<bool> changePassword(String newPassword) async {
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Sign out.
  Future<void> signOut() async {
    _repo.invalidate();
    await Supabase.instance.client.auth.signOut();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

final profileProvider =
    StateNotifierProvider.autoDispose<ProfileNotifier, ProfileState>(
      (ref) => ProfileNotifier(),
    );
