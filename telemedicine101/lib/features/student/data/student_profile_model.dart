/// Immutable data model for a student profile.
///
/// Keeps all health & identity fields in one place and provides
/// JSON round-tripping for Supabase.
class StudentProfile {
  final String id;
  final String fullName;
  final String email;
  final String school;
  final int height; // cm
  final int weight; // kg
  final String bloodType;
  final int systolic;
  final int diastolic;
  final String allergies;

  const StudentProfile({
    required this.id,
    this.fullName = '',
    this.email = '',
    this.school = '',
    this.height = 170,
    this.weight = 70,
    this.bloodType = 'A+',
    this.systolic = 120,
    this.diastolic = 80,
    this.allergies = '',
  });

  double get bmi {
    if (height <= 0) return 0;
    final h = height / 100;
    return weight / (h * h);
  }

  String get bmiCategory {
    final v = bmi;
    if (v < 18.5) return 'Underweight';
    if (v < 25) return 'Normal';
    if (v < 30) return 'Overweight';
    return 'Obese';
  }

  String get bloodPressureLabel => '$systolic/$diastolic';

  String get bpStatus {
    if (systolic < 120 && diastolic < 80) return 'Normal';
    if (systolic < 130 && diastolic < 80) return 'Elevated';
    if (systolic < 140 || diastolic < 90) return 'High – Stage 1';
    return 'High – Stage 2';
  }

  /// Parse from Supabase row + auth user info.
  factory StudentProfile.fromMap(
    Map<String, dynamic>? data, {
    required String userId,
    String? userEmail,
  }) {
    if (data == null) {
      return StudentProfile(id: userId, email: userEmail ?? '');
    }
    final bp = (data['blood_pressure'] ?? '120/80').toString();
    final parts = bp.split('/');
    return StudentProfile(
      id: userId,
      fullName: data['full_name'] ?? '',
      email: userEmail ?? '',
      school: data['school'] ?? '',
      height: int.tryParse(data['height']?.toString() ?? '') ?? 170,
      weight: int.tryParse(data['weight']?.toString() ?? '') ?? 70,
      bloodType: data['blood_type'] ?? 'A+',
      systolic: int.tryParse(parts.isNotEmpty ? parts[0] : '120') ?? 120,
      diastolic: int.tryParse(parts.length > 1 ? parts[1] : '80') ?? 80,
      allergies: data['allergies'] ?? '',
    );
  }

  /// Serialise only the mutable health fields for upsert.
  Map<String, dynamic> toUpsertMap() => {
    'id': id,
    'height': height.toString(),
    'weight': weight.toString(),
    'blood_type': bloodType,
    'blood_pressure': '$systolic/$diastolic',
    'allergies': allergies,
  };

  StudentProfile copyWith({
    String? fullName,
    String? email,
    String? school,
    int? height,
    int? weight,
    String? bloodType,
    int? systolic,
    int? diastolic,
    String? allergies,
  }) => StudentProfile(
    id: id,
    fullName: fullName ?? this.fullName,
    email: email ?? this.email,
    school: school ?? this.school,
    height: height ?? this.height,
    weight: weight ?? this.weight,
    bloodType: bloodType ?? this.bloodType,
    systolic: systolic ?? this.systolic,
    diastolic: diastolic ?? this.diastolic,
    allergies: allergies ?? this.allergies,
  );
}
