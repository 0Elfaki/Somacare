import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'message_model.dart';

/// Repository that wraps Supabase calls for the student <-> doctor
/// messaging thread (see `create_messages.sql` for the table + RLS).
///
/// A thread is identified by the (studentId, doctorId) pair. Call
/// [fetchThread] once to load history, then [subscribe] to receive new
/// rows in realtime.
class MessageRepository {
  MessageRepository._();
  static final instance = MessageRepository._();

  SupabaseClient get _client => Supabase.instance.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  /// Loads the full message history for a student/doctor thread, oldest
  /// first. Returns an empty list (rather than throwing) when there's no
  /// authenticated user or the request fails, so the UI can fall back to
  /// a friendly empty state instead of crashing.
  Future<List<ChatMessageModel>> fetchThread({
    required String studentId,
    required String doctorId,
  }) async {
    try {
      final rows = await _client
          .from('messages')
          .select('*')
          .eq('student_id', studentId)
          .eq('doctor_id', doctorId)
          .order('created_at');

      return (rows as List)
          .map((r) => ChatMessageModel.fromMap(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[MessageRepository] fetchThread failed: $e');
      return [];
    }
  }

  /// Sends a new message and returns the inserted row, or null on failure.
  Future<ChatMessageModel?> sendMessage({
    required String studentId,
    required String doctorId,
    required String senderId,
    MessageType type = MessageType.text,
    String? body,
    String? attachmentUrl,
    int? voiceDurationSeconds,
    String? appointmentId,
  }) async {
    try {
      final draft = ChatMessageModel(
        id: '',
        studentId: studentId,
        doctorId: doctorId,
        senderId: senderId,
        appointmentId: appointmentId,
        type: type,
        body: body,
        attachmentUrl: attachmentUrl,
        voiceDurationSeconds: voiceDurationSeconds,
        createdAt: DateTime.now(),
      );
      final row = await _client
          .from('messages')
          .insert(draft.toInsertMap())
          .select()
          .single();
      return ChatMessageModel.fromMap(row);
    } catch (e) {
      debugPrint('[MessageRepository] sendMessage failed: $e');
      return null;
    }
  }

  /// Marks every message in the thread sent *to* [readerId] as read.
  Future<void> markThreadRead({
    required String studentId,
    required String doctorId,
    required String readerId,
  }) async {
    try {
      await _client
          .from('messages')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('student_id', studentId)
          .eq('doctor_id', doctorId)
          .neq('sender_id', readerId)
          .filter('read_at', 'is', null);
    } catch (e) {
      debugPrint('[MessageRepository] markThreadRead failed: $e');
    }
  }

  /// Subscribes to new messages inserted into this thread. Returns the
  /// [RealtimeChannel] so the caller can `unsubscribe()` in `dispose()`.
  RealtimeChannel subscribe({
    required String studentId,
    required String doctorId,
    required void Function(ChatMessageModel message) onInsert,
  }) {
    final channelName = 'messages_${studentId}_$doctorId';
    return _client
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'student_id',
            value: studentId,
          ),
          callback: (payload) {
            final row = payload.newRecord;
            if (row['doctor_id'] != doctorId) return;
            onInsert(ChatMessageModel.fromMap(row));
          },
        )
        .subscribe();
  }
}
