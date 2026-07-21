enum LabResultStatus { normal, abnormal, critical }

class LabResult {
  final String id;
  final String studentId;
  final String? doctorId;
  final String testName;
  final double value;
  final String? unit;
  final double? referenceLow;
  final double? referenceHigh;
  final LabResultStatus status;
  final String? notes;
  final DateTime testDate;

  const LabResult({
    required this.id,
    required this.studentId,
    this.doctorId,
    required this.testName,
    required this.value,
    this.unit,
    this.referenceLow,
    this.referenceHigh,
    required this.status,
    this.notes,
    required this.testDate,
  });

  String get rangeLabel {
    if (referenceLow == null || referenceHigh == null) return '';
    final u = unit ?? '';
    return 'Range ${_fmt(referenceLow!)}–${_fmt(referenceHigh!)} $u'.trim();
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  factory LabResult.fromMap(Map<String, dynamic> map) {
    return LabResult(
      id: map['id'] as String? ?? '',
      studentId: map['student_id'] as String? ?? '',
      doctorId: map['doctor_id'] as String?,
      testName: map['test_name'] as String? ?? '',
      value: (map['result_value'] as num?)?.toDouble() ?? 0,
      unit: map['unit'] as String?,
      referenceLow: (map['reference_low'] as num?)?.toDouble(),
      referenceHigh: (map['reference_high'] as num?)?.toDouble(),
      status: _parseStatus(map['status'] as String?),
      notes: map['notes'] as String?,
      testDate: DateTime.tryParse(map['test_date']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'student_id': studentId,
        if (doctorId != null) 'doctor_id': doctorId,
        'test_name': testName,
        'result_value': value,
        'unit': unit,
        'reference_low': referenceLow,
        'reference_high': referenceHigh,
        'status': status.name,
        'notes': notes,
        'test_date': testDate.toIso8601String().split('T').first,
      };

  static LabResultStatus _parseStatus(String? s) {
    switch (s) {
      case 'abnormal':
        return LabResultStatus.abnormal;
      case 'critical':
        return LabResultStatus.critical;
      default:
        return LabResultStatus.normal;
    }
  }
}
