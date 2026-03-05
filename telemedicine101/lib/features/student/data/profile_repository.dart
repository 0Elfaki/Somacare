import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'student_profile_model.dart';

/// Repository that wraps Supabase calls for the student profile.
///
/// Features:
/// - In-memory cache with TTL to avoid redundant network hits.
/// - Selective column fetching to minimise payload size.
/// - Optimistic upsert that updates the cache immediately.
class ProfileRepository {
  ProfileRepository._();
  static final instance = ProfileRepository._();

  StudentProfile? _cached;
  DateTime? _cachedAt;

  /// Cache is valid for 2 minutes.
  static const _ttl = Duration(minutes: 2);

  SupabaseClient get _client => Supabase.instance.client;

  bool get _cacheValid =>
      _cached != null &&
      _cachedAt != null &&
      DateTime.now().difference(_cachedAt!) < _ttl;

  /// Fetch profile, returning cached copy when still fresh.
  Future<StudentProfile> fetch({bool forceRefresh = false}) async {
    if (!forceRefresh && _cacheValid) return _cached!;

    final user = _client.auth.currentUser;
    if (user == null) {
      debugPrint(
        '[ProfileRepository] No authenticated user, returning default profile',
      );
      // Return a default profile instead of throwing - allows UI to show placeholder
      final defaultProfile = StudentProfile(
        id: '',
        email: '',
        fullName: 'Student',
        school: '',
      );
      _cached = defaultProfile;
      _cachedAt = DateTime.now();
      return defaultProfile;
    }

    try {
      final data = await _client
          .from('profiles')
          .select(
            'full_name,school,height,weight,blood_type,blood_pressure,allergies',
          )
          .eq('id', user.id)
          .maybeSingle();

      final profile = StudentProfile.fromMap(
        data,
        userId: user.id,
        userEmail: user.email,
      );

      _cached = profile;
      _cachedAt = DateTime.now();
      return profile;
    } catch (e, st) {
      debugPrint('[ProfileRepository] fetch() error: $e\n$st');
      // On DB error, return default profile to avoid crashing the UI
      final defaultProfile = StudentProfile(
        id: user.id,
        email: user.email ?? '',
        fullName: 'Student',
        school: '',
      );
      _cached = defaultProfile;
      _cachedAt = DateTime.now();
      return defaultProfile;
    }
  }

  /// Persist changes and update the local cache optimistically.
  Future<bool> save(StudentProfile profile) async {
    try {
      await _client.from('profiles').upsert(profile.toUpsertMap());
      _cached = profile;
      _cachedAt = DateTime.now();
      return true;
    } catch (e) {
      return false; // Return false instead of crashing
    }
  }

  /// Invalidate the cache so the next [fetch] hits the network.
  void invalidate() {
    _cached = null;
    _cachedAt = null;
  }
}
