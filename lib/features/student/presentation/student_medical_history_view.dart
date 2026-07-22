import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/medical_history_repository.dart';

/// Simplified Medical History View for Students
///
/// Shows medical history in a clean, read-only format without input fields.
/// Doctors can edit through the full medical history screen.

class StudentMedicalHistoryView extends ConsumerStatefulWidget {
  const StudentMedicalHistoryView({super.key});

  @override
  ConsumerState<StudentMedicalHistoryView> createState() =>
      _StudentMedicalHistoryViewState();
}

class _StudentMedicalHistoryViewState
    extends ConsumerState<StudentMedicalHistoryView> {
  bool _isLoading = true;
  MedicalHistoryData? _history;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Use the repository which has mock data support
      final repo = MedicalHistoryRepository.instance;
      final history = await repo.fetch();

      if (history.id.isNotEmpty) {
        _history = MedicalHistoryData(
          id: history.id,
          studentId: history.studentId,
          chronicConditions: history.chronicConditions,
          pastIllnesses: history.pastIllnesses,
          hospitalizations: history.hospitalizations,
          familyConditions: history.familyConditions,
          surgicalHistory: history.surgicalHistory,
          allergies: history.allergies,
          immunizations: history.immunizations,
          socialHistory: history.socialHistory,
          reviewOfSystems: history.reviewOfSystems,
          currentMedications: history.currentMedications,
          isApproved: history.isApproved,
          denialReason: history.denialReason,
        );
      }
    } catch (e) {
      _error = 'Failed to load medical history';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'My Medical History',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF3A86FF),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: const Row(
              children: [
                Icon(Icons.visibility, size: 16),
                SizedBox(width: 4),
                Text(
                  'View Only',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF3A86FF)),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (_history == null) {
      return _buildEmptyState();
    }

    return _buildContent();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medical_information_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Medical History Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A doctor or school staff member will add your medical history.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => context.push('/lab-results'),
              icon: const Icon(Icons.science_outlined),
              label: const Text('View Lab Results'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF3A86FF),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Approval Status
          _buildStatusCard(),
          const SizedBox(height: 16),

          // Lab Results link
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => context.push('/lab-results'),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.science_outlined, color: Color(0xFF3A86FF)),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'View Lab Results',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.grey.shade400),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Personal Medical History
          _buildSection('Personal Medical History', Icons.medical_services, [
            _buildField('Chronic Conditions', _history!.chronicConditions),
            _buildField('Past Illnesses', _history!.pastIllnesses),
            _buildField('Hospitalizations', _history!.hospitalizations),
          ]),
          const SizedBox(height: 16),

          // Family Medical History
          _buildSection('Family Medical History', Icons.family_restroom, [
            _buildField(
              'Parents Health Conditions',
              _history!.familyConditions,
            ),
          ]),
          const SizedBox(height: 16),

          // Surgical History
          _buildSection('Surgical History', Icons.local_hospital, [
            _buildField('Surgical Procedures', _history!.surgicalHistory),
          ]),
          const SizedBox(height: 16),

          // Medications & Allergies
          _buildSection('Medications & Allergies', Icons.medication, [
            _buildField('Current Medications', _history!.currentMedications),
            _buildField('Allergies', _history!.allergies),
          ]),
          const SizedBox(height: 16),

          // Immunizations
          _buildSection('Immunizations', Icons.vaccines, [
            _buildField('Immunization Records', _history!.immunizations),
          ]),
          const SizedBox(height: 16),

          // Social History
          _buildSection('Social History', Icons.person, [
            _buildField('Lifestyle & Habits', _history!.socialHistory),
          ]),
          const SizedBox(height: 16),

          // Review of Systems
          _buildSection('Review of Systems', Icons.assignment, [
            _buildField('Current Symptoms', _history!.reviewOfSystems),
          ]),
          const SizedBox(height: 24),

          // PDF Download Button
          _buildPDFButton(),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final isApproved = _history!.isApproved;
    final denialReason = _history!.denialReason;
    final hasDenial = denialReason != null && denialReason.isNotEmpty;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: isApproved
                ? [const Color(0xFF059669).withValues(alpha: 0.1), Colors.white]
                : hasDenial
                ? [const Color(0xFFDC2626).withValues(alpha: 0.1), Colors.white]
                : [
                    const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    Colors.white,
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isApproved
                        ? const Color(0xFF059669).withValues(alpha: 0.2)
                        : hasDenial
                        ? const Color(0xFFDC2626).withValues(alpha: 0.2)
                        : const Color(0xFFF59E0B).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isApproved
                        ? Icons.verified
                        : hasDenial
                        ? Icons.cancel
                        : Icons.pending,
                    color: isApproved
                        ? const Color(0xFF059669)
                        : hasDenial
                        ? const Color(0xFFDC2626)
                        : const Color(0xFFF59E0B),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isApproved
                            ? 'Approved'
                            : hasDenial
                            ? 'Denied'
                            : 'Pending Approval',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isApproved
                              ? const Color(0xFF059669)
                              : hasDenial
                              ? const Color(0xFFDC2626)
                              : const Color(0xFFF59E0B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isApproved
                            ? 'Your medical history has been reviewed by a healthcare provider.'
                            : hasDenial
                            ? 'Your medical history was not approved. Please check the comments below.'
                            : 'Waiting for review by doctor or school staff.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Show denial reason if denied
            if (hasDenial) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.comment, size: 16, color: Color(0xFFDC2626)),
                        SizedBox(width: 4),
                        Text(
                          'Feedback from Doctor:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      denialReason,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF3A86FF), size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3A86FF),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, String value) {
    if (value.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Not recorded',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPDFButton() {
    if (!_history!.isApproved) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.grey.shade500),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'PDF available after doctor approval',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: _exportPDF,
      icon: const Icon(Icons.download),
      label: const Text('Download PDF'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3A86FF),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _exportPDF() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preparing PDF...'),
        backgroundColor: Color(0xFF3A86FF),
      ),
    );
  }
}

/// Simple data class for medical history
class MedicalHistoryData {
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
  final String currentMedications;
  final bool isApproved;
  final String? denialReason;

  MedicalHistoryData({
    required this.id,
    required this.studentId,
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
    this.isApproved = false,
    this.denialReason,
  });

  factory MedicalHistoryData.fromMap(Map<String, dynamic> data) {
    return MedicalHistoryData(
      id: data['id'] as String? ?? '',
      studentId: data['student_id'] as String? ?? '',
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
      denialReason: data['denial_reason'] as String?,
    );
  }
}
