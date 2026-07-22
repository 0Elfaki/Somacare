import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  /// Create a notification for a doctor
  static Future<void> createNotification({
    required String doctorId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      await Supabase.instance.client.from('notifications').insert({
        'doctor_id': doctorId,
        'title': title,
        'message': message,
        'type': type,
        'data': data ?? {},
      });
    } catch (e) {
      debugPrint('Error creating notification: $e');
    }
  }

  /// Notify doctor of a new booking
  static Future<void> notifyNewBooking({
    required String doctorId,
    required String studentName,
    required String date,
    required String time,
  }) async {
    await createNotification(
      doctorId: doctorId,
      title: 'New Appointment Booking',
      message: '$studentName booked an appointment for $date at $time',
      type: 'booking',
      data: {'student_name': studentName, 'date': date, 'time': time},
    );
  }

  /// Notify doctor of an emergency appointment
  static Future<void> notifyEmergency({
    required String doctorId,
    required String studentName,
    required String reason,
  }) async {
    await createNotification(
      doctorId: doctorId,
      title: '🚨 Emergency Appointment',
      message: '$studentName requires immediate attention: $reason',
      type: 'emergency',
      data: {'student_name': studentName, 'reason': reason},
    );
  }

  /// Notify doctor of student data reset
  static Future<void> notifyDataReset({
    required String doctorId,
    required String studentName,
    required String resetType,
  }) async {
    await createNotification(
      doctorId: doctorId,
      title: 'Student Data Reset',
      message: '$studentName\'s $resetType data has been reset',
      type: 'data_reset',
      data: {'student_name': studentName, 'reset_type': resetType},
    );
  }

  /// Get unread notifications for a doctor
  static Future<List<Map<String, dynamic>>> getUnreadNotifications(
    String doctorId,
  ) async {
    try {
      final response = await Supabase.instance.client
          .from('notifications')
          .select()
          .eq('doctor_id', doctorId)
          .eq('is_read', false)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      return [];
    }
  }

  /// Get all notifications for a doctor
  static Future<List<Map<String, dynamic>>> getAllNotifications(
    String doctorId,
  ) async {
    try {
      final response = await Supabase.instance.client
          .from('notifications')
          .select()
          .eq('doctor_id', doctorId)
          .order('created_at', ascending: false)
          .limit(50);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      return [];
    }
  }

  /// Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  static Future<void> markAllAsRead(String doctorId) async {
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('doctor_id', doctorId)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }
}
