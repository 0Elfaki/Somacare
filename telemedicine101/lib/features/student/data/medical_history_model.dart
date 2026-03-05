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
      id: data['id'] ?? '',
      studentId: data['student_id'] ?? userId,
      chronicConditions: data['chronic_conditions'] ?? '',
      pastIllnesses: data['past_illnesses'] ?? '',
      hospitalizations: data['hospitalizations'] ?? '',
      familyConditions: data['family_conditions'] ?? '',
      surgicalHistory: data['surgical_history'] ?? '',
      allergies: data['allergies'] ?? '',
      immunizations: data['immunizations'] ?? '',
      socialHistory: data['social_history'] ?? '',
      reviewOfSystems: data['review_of_systems'] ?? '',
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
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
