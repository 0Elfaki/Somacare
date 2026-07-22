import 'package:flutter/material.dart';

/// Helper function to parse DateTime from string with null safety
DateTime _parseDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return DateTime.now();
    }
  }
  return DateTime.now();
}

/// Helper function to parse nullable DateTime from string with null safety
DateTime? _parseDateTimeNullable(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }
  return null;
}

// Medication Status
enum MedicationStatus { active, completed, paused }

// Prescription Status Enum
enum PrescriptionStatus { active, pending, completed, expired }

// Unified Reminder Model (for medications and prescriptions)
class MedicationReminder {
  final String id;
  final TimeOfDay? time; // For medication reminders (time of day)
  final DateTime?
  scheduledTime; // For prescription reminders (specific datetime)
  final bool isEnabled;
  final List<String> days;
  final String? medicationName;
  final bool isTaken;

  const MedicationReminder({
    required this.id,
    this.time,
    this.scheduledTime,
    this.isEnabled = true,
    this.days = const ['Everyday'],
    this.medicationName,
    this.isTaken = false,
  });

  MedicationReminder copyWith({
    String? id,
    TimeOfDay? time,
    DateTime? scheduledTime,
    bool? isEnabled,
    List<String>? days,
    String? medicationName,
    bool? isTaken,
  }) {
    return MedicationReminder(
      id: id ?? this.id,
      time: time ?? this.time,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isEnabled: isEnabled ?? this.isEnabled,
      days: days ?? this.days,
      medicationName: medicationName ?? this.medicationName,
      isTaken: isTaken ?? this.isTaken,
    );
  }

  /// Convert to map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'scheduled_time': time != null
          ? '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}'
          : null,
      'is_enabled': isEnabled,
      'days': days,
    };
  }

  /// Create from database map
  factory MedicationReminder.fromMap(Map<String, dynamic> map) {
    final timeStr = map['scheduled_time'] as String?;
    TimeOfDay? time;
    if (timeStr != null) {
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        time = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 8,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }
    return MedicationReminder(
      id: map['id'] as String? ?? '',
      time: time,
      isEnabled: map['is_enabled'] as bool? ?? true,
      days:
          (map['days'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          ['Everyday'],
    );
  }
}

// Medication Model
class Medication {
  final String id;
  final String name;
  final String dosage;
  final String frequency;
  final String prescribedBy;
  final DateTime startDate;
  final DateTime? endDate;
  final MedicationStatus status;
  final int refillsRemaining;
  final int refillsTotal;
  final String? instructions;
  final String? notes;
  final List<MedicationReminder> reminders;
  final bool isTakenToday;

  const Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.prescribedBy,
    required this.startDate,
    this.endDate,
    required this.status,
    required this.refillsRemaining,
    required this.refillsTotal,
    this.instructions,
    this.notes,
    this.reminders = const [],
    this.isTakenToday = false,
  });

  Medication copyWith({
    String? id,
    String? name,
    String? dosage,
    String? frequency,
    String? prescribedBy,
    DateTime? startDate,
    DateTime? endDate,
    MedicationStatus? status,
    int? refillsRemaining,
    int? refillsTotal,
    String? instructions,
    String? notes,
    List<MedicationReminder>? reminders,
    bool? isTakenToday,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      prescribedBy: prescribedBy ?? this.prescribedBy,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      refillsRemaining: refillsRemaining ?? this.refillsRemaining,
      refillsTotal: refillsTotal ?? this.refillsTotal,
      instructions: instructions ?? this.instructions,
      notes: notes ?? this.notes,
      reminders: reminders ?? this.reminders,
      isTakenToday: isTakenToday ?? this.isTakenToday,
    );
  }

  /// Convert to map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'prescribed_by': prescribedBy,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'status': status.name,
      'refills_remaining': refillsRemaining,
      'refills_total': refillsTotal,
      'instructions': instructions,
      'notes': notes,
      'is_taken_today': isTakenToday,
    };
  }

  /// Create from database map
  factory Medication.fromMap(
    Map<String, dynamic> map, {
    List<MedicationReminder>? reminders,
  }) {
    return Medication(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      dosage: map['dosage'] as String? ?? '',
      frequency: map['frequency'] as String? ?? '',
      prescribedBy: map['prescribed_by'] as String? ?? '',
      startDate: _parseDateTime(map['start_date']),
      endDate: _parseDateTimeNullable(map['end_date']),
      status: _parseMedicationStatus(map['status'] as String?),
      refillsRemaining: map['refills_remaining'] as int? ?? 0,
      refillsTotal: map['refills_total'] as int? ?? 0,
      instructions: map['instructions'] as String?,
      notes: map['notes'] as String?,
      reminders: reminders ?? [],
      isTakenToday: map['is_taken_today'] as bool? ?? false,
    );
  }

  static MedicationStatus _parseMedicationStatus(String? status) {
    switch (status) {
      case 'active':
        return MedicationStatus.active;
      case 'completed':
        return MedicationStatus.completed;
      case 'paused':
        return MedicationStatus.paused;
      default:
        return MedicationStatus.active;
    }
  }
}

// Prescription Model
class Prescription {
  final String id;
  final String studentId;
  final String? doctorId;
  final String medicationName;
  final String dosage;
  final String frequency;
  final String prescribingDoctor;
  final String pharmacy;
  final DateTime datePrescribed;
  final DateTime? expiryDate;
  final PrescriptionStatus status;
  final int refillsRemaining;
  final int refillsTotal;
  final String? instructions;
  final List<MedicationReminder> reminders;

  const Prescription({
    required this.id,
    this.studentId = '',
    this.doctorId,
    required this.medicationName,
    required this.dosage,
    required this.frequency,
    required this.prescribingDoctor,
    required this.pharmacy,
    required this.datePrescribed,
    this.expiryDate,
    required this.status,
    required this.refillsRemaining,
    required this.refillsTotal,
    this.instructions,
    this.reminders = const [],
  });

  Prescription copyWith({
    String? id,
    String? studentId,
    String? doctorId,
    String? medicationName,
    String? dosage,
    String? frequency,
    String? prescribingDoctor,
    String? pharmacy,
    DateTime? datePrescribed,
    DateTime? expiryDate,
    PrescriptionStatus? status,
    int? refillsRemaining,
    int? refillsTotal,
    String? instructions,
    List<MedicationReminder>? reminders,
  }) {
    return Prescription(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      doctorId: doctorId ?? this.doctorId,
      medicationName: medicationName ?? this.medicationName,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      prescribingDoctor: prescribingDoctor ?? this.prescribingDoctor,
      pharmacy: pharmacy ?? this.pharmacy,
      datePrescribed: datePrescribed ?? this.datePrescribed,
      expiryDate: expiryDate ?? this.expiryDate,
      status: status ?? this.status,
      refillsRemaining: refillsRemaining ?? this.refillsRemaining,
      refillsTotal: refillsTotal ?? this.refillsTotal,
      instructions: instructions ?? this.instructions,
      reminders: reminders ?? this.reminders,
    );
  }

  /// Convert to map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'doctor_id': doctorId,
      'medication_name': medicationName,
      'dosage': dosage,
      'frequency': frequency,
      'pharmacy': pharmacy,
      'date_prescribed': datePrescribed.toIso8601String().split('T')[0],
      'expiry_date': expiryDate?.toIso8601String().split('T')[0],
      'status': status.name,
      'refills_remaining': refillsRemaining,
      'refills_total': refillsTotal,
      'instructions': instructions,
    };
  }

  /// Create from database map
  factory Prescription.fromMap(
    Map<String, dynamic> map, {
    List<MedicationReminder>? reminders,
  }) {
    return Prescription(
      id: map['id'] as String? ?? '',
      studentId: map['student_id'] as String? ?? '',
      doctorId: map['doctor_id'] as String?,
      medicationName: map['medication_name'] as String? ?? '',
      dosage: map['dosage'] as String? ?? '',
      frequency: map['frequency'] as String? ?? '',
      prescribingDoctor: map['prescribing_doctor'] as String? ?? '',
      pharmacy: map['pharmacy'] as String? ?? '',
      datePrescribed: _parseDateTime(map['date_prescribed']),
      expiryDate: _parseDateTimeNullable(map['expiry_date']),
      status: _parsePrescriptionStatus(map['status'] as String?),
      refillsRemaining: map['refills_remaining'] as int? ?? 0,
      refillsTotal: map['refills_total'] as int? ?? 0,
      instructions: map['instructions'] as String?,
      reminders: reminders ?? [],
    );
  }

  static PrescriptionStatus _parsePrescriptionStatus(String? status) {
    switch (status) {
      case 'active':
        return PrescriptionStatus.active;
      case 'pending':
        return PrescriptionStatus.pending;
      case 'completed':
        return PrescriptionStatus.completed;
      case 'expired':
        return PrescriptionStatus.expired;
      default:
        return PrescriptionStatus.active;
    }
  }
}
