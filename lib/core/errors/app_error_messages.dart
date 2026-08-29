import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Turns a thrown object into something a student should actually read.
///
/// Screens used to render `e.toString()` straight into a snack bar, so a
/// failure surfaced as:
///
///     PostgrestException(message: infinite recursion detected in policy for
///     relation "profiles", code: 42P17, details: , hint: null)
///
/// That tells the user nothing, and it leaks the schema — table names, policy
/// names and error codes — to anyone who can trigger it.
///
/// The full exception is still written to the debug console, so the detail is
/// there when you are looking for it.
String friendlyErrorMessage(
  Object error, {
  String fallback = 'Something went wrong. Please check your connection and try again.',
  String? context,
}) {
  // Always keep the real thing where a developer can find it.
  debugPrint(
    context == null ? 'Error: $error' : 'Error [$context]: $error',
  );

  if (error is PostgrestException) {
    debugPrint('  PostgrestException code=${error.code} message=${error.message}');
    return switch (error.code) {
      // Row-level security refused the read, or recursed. Either way the user
      // cannot act on it, and the detail is not theirs to see.
      '42P17' || '42501' || 'PGRST301' =>
        'We could not load this right now. Please try again in a moment.',
      // Unique violation — the row is already there.
      '23505' => 'That has already been saved.',
      // Foreign key violation — a referenced record is missing.
      '23503' => 'Some of the details are no longer available. Please refresh and try again.',
      // Not-null violation.
      '23502' => 'Some required details are missing. Please fill in every field.',
      // No rows where exactly one was expected.
      'PGRST116' => 'We could not find that record.',
      _ => fallback,
    };
  }

  if (error is AuthException) {
    // Auth messages are written for end users already.
    return error.message;
  }

  if (error is StorageException) {
    return 'We could not upload that file. Please try again.';
  }

  if (error is TimeoutException || _looksLikeNetworkFailure(error)) {
    return 'You appear to be offline. Check your connection and try again.';
  }

  return fallback;
}

/// The copy the appointment screens show when their list fails to load.
///
/// Kept as a constant so Book Appointment and My Appointments cannot drift
/// apart, and so the pull-to-refresh instruction stays accurate.
const String kAppointmentsLoadError =
    'Unable to load appointments right now. Please pull down to refresh.';

/// Whether a thrown object is a transport failure.
///
/// Matched by type name rather than by importing `dart:io`: this app also
/// builds for web, where `dart:io` does not exist and importing it fails the
/// compile. `SocketException`, `HttpException` and `http`'s `ClientException`
/// have no common supertype we can catch instead.
bool _looksLikeNetworkFailure(Object error) {
  const networkTypes = {
    'SocketException',
    'HttpException',
    'ClientException',
    'HandshakeException',
    'ConnectionException',
  };
  return networkTypes.contains(error.runtimeType.toString());
}
