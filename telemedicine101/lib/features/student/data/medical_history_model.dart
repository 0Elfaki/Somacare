/// Immutable data model for medical history.
///
/// Stores all medical history fields and provides JSON
/// round-tripping for Supabase.
class MedicalHistory {
  final String id;
  final String studentId;
  final String chronicConditions;
  final String pastIllnesses;
  final String hospitalizations;
  final String familyConditions;
  final String surgicalHistory;
  final String allergies;
  final String immunizations;
  final String socialHistory;
  final String reviewOfSystems;
  final String currentMedications; // NEW: Track prescribed medications
  final bool isApproved; // NEW: Doctor approval status
  final String? approvedBy; // NEW: Doctor who approved
  final DateTime? approvedAt; // NEW: When it was approved
  final String? denialReason; // NEW: Reason if denied
  final String? deniedBy; // NEW: Doctor who denied
  final DateTime? deniedAt; // NEW: When it was denied
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MedicalHistory({
    this.id = '',
    this.studentId = '',
    this.chronicConditions = '',
    this.pastIllnesses = '',
    this.hospitalizations = '',
    this.familyConditions = '',
    this.surgicalHistory = '',
    this.allergies = '',
    this.immunizations = '',
    this.socialHistory = '',
    this.reviewOfSystems = '',
    this.currentMedications = '',
    this.isApproved = false, // Default to not approved
    this.approvedBy,
    this.approvedAt,
    this.denialReason,
    this.deniedBy,
    this.deniedAt,
    this.createdAt,
    this.updatedAt,
  });

  /// Parse from Supabase row + user info.
  factory MedicalHistory.fromMap(
    Map<String, dynamic>? data, {
    required String userId,
  }) {
    if (data == null) {
      return MedicalHistory(studentId: userId);
    }
    return MedicalHistory(
      id: data['id'] as String? ?? '',
      studentId: data['student_id'] as String? ?? userId,
      chronicConditions: data['chronic_conditions'] as String? ?? '',
      pastIllnesses: data['past_illnesses'] as String? ?? '',
      hospitalizations: data['hospitalizations'] as String? ?? '',
      familyConditions: data['family_conditions'] as String? ?? '',
      surgicalHistory: data['surgical_history'] as String? ?? '',
      allergies: data['allergies'] as String? ?? '',
      immunizations: data['immunizations'] as String? ?? '',
      socialHistory: data['social_history'] as String? ?? '',
      reviewOfSystems: data['review_of_systems'] as String? ?? '',
      currentMedications: data['current_medications'] as String? ?? '',
      isApproved: data['is_approved'] as bool? ?? false,
      approvedBy: data['approved_by'] as String?,
      approvedAt: data['approved_at'] != null
          ? DateTime.tryParse(data['approved_at'].toString())
          : null,
      denialReason: data['denial_reason'] as String?,
      deniedBy: data['denied_by'] as String?,
      deniedAt: data['denied_at'] != null
          ? DateTime.tryParse(data['denied_at'].toString())
          : null,
      createdAt: data['created_at'] != null
          ? DateTime.tryParse(data['created_at'].toString())
          : null,
      updatedAt: data['updated_at'] != null
          ? DateTime.tryParse(data['updated_at'].toString())
          : null,
    );
  }

  /// Convert to map for Supabase upsert.
  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty) 'id': id,
      'student_id': studentId,
      'chronic_conditions': chronicConditions,
      'past_illnesses': pastIllnesses,
      'hospitalizations': hospitalizations,
      'family_conditions': familyConditions,
      'surgical_history': surgicalHistory,
      'allergies': allergies,
      'immunizations': immunizations,
      'social_history': socialHistory,
      'review_of_systems': reviewOfSystems,
      'current_medications': currentMedications,
      'is_approved': isApproved,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'denial_reason': denialReason,
      'denied_by': deniedBy,
      'denied_at': deniedAt?.toIso8601String(),
    };
  }

  /// Create a copy with updated fields.
  MedicalHistory copyWith({
    String? id,
    String? studentId,
    String? chronicConditions,
    String? pastIllnesses,
    String? hospitalizations,
    String? familyConditions,
    String? surgicalHistory,
    String? allergies,
    String? immunizations,
    String? socialHistory,
    String? reviewOfSystems,
    String? currentMedications,
    bool? isApproved,
    String? approvedBy,
    DateTime? approvedAt,
    String? denialReason,
    String? deniedBy,
    DateTime? deniedAt,
  }) {
    return MedicalHistory(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      pastIllnesses: pastIllnesses ?? this.pastIllnesses,
      hospitalizations: hospitalizations ?? this.hospitalizations,
      familyConditions: familyConditions ?? this.familyConditions,
      surgicalHistory: surgicalHistory ?? this.surgicalHistory,
      allergies: allergies ?? this.allergies,
      immunizations: immunizations ?? this.immunizations,
      socialHistory: socialHistory ?? this.socialHistory,
      reviewOfSystems: reviewOfSystems ?? this.reviewOfSystems,
      currentMedications: currentMedications ?? this.currentMedications,
      isApproved: isApproved ?? this.isApproved,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      denialReason: denialReason ?? this.denialReason,
      deniedBy: deniedBy ?? this.deniedBy,
      deniedAt: deniedAt ?? this.deniedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
