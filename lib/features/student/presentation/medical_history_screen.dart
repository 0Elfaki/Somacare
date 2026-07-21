import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/medical_history_repository.dart';
import '../data/medical_history_model.dart';
import '../providers/medical_history_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Comprehensive Medical History Template
///
/// This screen provides a detailed medical history form with sections for:
/// - Personal Medical History
/// - Family Medical History
/// - Surgical History
/// - Current Medications
/// - Allergies
/// - Immunizations
/// - Social History
/// - Review of Systems
///
/// Each section includes:
/// - Detailed prompts and examples
/// - Follow-up questions guidance
/// - Warning signs to watch for
/// - Best practices for organization

class MedicalHistoryScreen extends ConsumerStatefulWidget {
  const MedicalHistoryScreen({super.key});

  @override
  ConsumerState<MedicalHistoryScreen> createState() =>
      _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends ConsumerState<MedicalHistoryScreen> {
  // Form Key
  final _formKey = GlobalKey<FormState>();

  // Text Controllers for form fields
  final _chronicConditionsController = TextEditingController();
  final _pastIllnessesController = TextEditingController();
  final _hospitalizationsController = TextEditingController();
  final _familyConditionsController = TextEditingController();
  final _surgicalHistoryController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _immunizationsController = TextEditingController();
  final _socialHistoryController = TextEditingController();
  final _reviewOfSystemsController = TextEditingController();

  // Section Expansion State
  final Map<String, bool> _sectionExpanded = {};

  // Track whether controllers have been initialized from state
  bool _controllersInitialized = false;

  // Check if user can edit (doctor or school staff)
  bool get _canEdit {
    // Student view is read-only
    return false;
  }

  // Initialize all sections as expanded
  @override
  void initState() {
    super.initState();
    _sectionExpanded['personal'] = true;
    _sectionExpanded['family'] = false;
    _sectionExpanded['surgical'] = false;
    _sectionExpanded['medications'] = false;
    _sectionExpanded['allergies'] = false;
    _sectionExpanded['immunizations'] = false;
    _sectionExpanded['social'] = false;
    _sectionExpanded['ros'] = false;
  }

  @override
  void dispose() {
    _chronicConditionsController.dispose();
    _pastIllnessesController.dispose();
    _hospitalizationsController.dispose();
    _familyConditionsController.dispose();
    _surgicalHistoryController.dispose();
    _allergiesController.dispose();
    _immunizationsController.dispose();
    _socialHistoryController.dispose();
    _reviewOfSystemsController.dispose();
    super.dispose();
  }

  // Initialize controllers from provider state
  void _initializeControllers(MedicalHistoryState state) {
    // Only initialize once when history data is available
    if (state.history != null && !_controllersInitialized) {
      final history = state.history!;
      _chronicConditionsController.text = history.chronicConditions;
      _pastIllnessesController.text = history.pastIllnesses;
      _hospitalizationsController.text = history.hospitalizations;
      _familyConditionsController.text = history.familyConditions;
      _surgicalHistoryController.text = history.surgicalHistory;
      _allergiesController.text = history.allergies;
      _immunizationsController.text = history.immunizations;
      _socialHistoryController.text = history.socialHistory;
      _reviewOfSystemsController.text = history.reviewOfSystems;
      _controllersInitialized = true;
    }
  }

  void _toggleSection(String section) {
    setState(() {
      _sectionExpanded[section] = !(_sectionExpanded[section] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(medicalHistoryProvider);

    // Initialize controllers when data loads
    if (state.history != null && !state.isLoading) {
      _initializeControllers(state);
    }

    if (state.isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Medical History'),
          backgroundColor: const Color(0xFF3A86FF),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF3A86FF)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Medical History',
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
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showHelpDialog(context),
            tooltip: 'Help & Guide',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Introduction Card
            _buildInfoCard(
              context,
              title: 'Medical History Guide',
              content:
                  'Please provide comprehensive information about your medical background. '
                  'This information helps healthcare providers deliver better care. '
                  'Fields marked with * are required.',
              icon: Icons.medical_information,
              color: const Color(0xFF3A86FF),
            ),

            const SizedBox(height: 16),

            // Section 1: Personal Medical History
            _MedicalHistorySection(
              title: 'Personal Medical History',
              sectionKey: 'personal',
              icon: Icons.medical_services,
              isExpanded: _sectionExpanded['personal'] ?? false,
              onToggle: () => _toggleSection('personal'),
              children: [
                _buildTextField(
                  label: 'Chronic Conditions*',
                  hint: 'e.g., Asthma, Diabetes, Hypertension',
                  helperText:
                      'List any ongoing health conditions you have been diagnosed with.',
                  example:
                      'Example: Asthma diagnosed at age 12, currently managed with inhaler',
                  followUp: const [
                    'When were you diagnosed?',
                    'What treatments are you currently using?',
                    'How often do you experience symptoms?',
                  ],
                  warningSigns: const [
                    'Worsening symptoms despite treatment',
                    'New symptoms developing',
                    'Frequent hospitalizations',
                  ],
                  controller: _chronicConditionsController,
                  onChanged: (value) {
                    ref
                        .read(medicalHistoryProvider.notifier)
                        .updateField(
                          (h) => h.copyWith(chronicConditions: value),
                        );
                  },
                ),
                _buildTextField(
                  label: 'Past Illnesses',
                  hint: 'e.g., Chickenpox, Pneumonia, COVID-19',
                  helperText:
                      'List any significant past illnesses, even if resolved.',
                  example:
                      'Example: Had pneumonia in 2020, required hospitalization for 5 days',
                  followUp: const [
                    'When did the illness occur?',
                    'Were there any complications?',
                    'What treatment did you receive?',
                  ],
                  controller: _pastIllnessesController,
                  onChanged: (value) {
                    ref
                        .read(medicalHistoryProvider.notifier)
                        .updateField((h) => h.copyWith(pastIllnesses: value));
                  },
                ),
                _buildTextField(
                  label: 'Hospitalizations',
                  hint: 'e.g., Surgery, Emergency visits',
                  helperText:
                      'Record any hospital admissions or emergency room visits.',
                  example: 'Example: Appendectomy in 2019 at City Hospital',
                  followUp: const [
                    'What was the reason for hospitalization?',
                    'How long were you admitted?',
                    'Did you receive any blood products?',
                  ],
                  controller: _hospitalizationsController,
                  onChanged: (value) {
                    ref
                        .read(medicalHistoryProvider.notifier)
                        .updateField(
                          (h) => h.copyWith(hospitalizations: value),
                        );
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Section 2: Family Medical History
            _MedicalHistorySection(
              title: 'Family Medical History',
              sectionKey: 'family',
              icon: Icons.family_restroom,
              isExpanded: _sectionExpanded['family'] ?? false,
              onToggle: () => _toggleSection('family'),
              children: [
                _buildTextField(
                  label: 'Parents Health Conditions',
                  hint: 'e.g., Heart Disease, Diabetes, Cancer',
                  helperText:
                      'Record health conditions affecting your parents (biological).',
                  example:
                      'Example: Father - Hypertension (diagnosed age 50), Mother - Type 2 Diabetes (diagnosed age 55)',
                  followUp: const [
                    'At what age were they diagnosed?',
                    'Are there any complications?',
                    'What medications do they take?',
                  ],
                  warningSigns: const [
                    'Early onset of chronic diseases (before age 50)',
                    'Multiple family members with same condition',
                    'Known genetic conditions in family',
                  ],
                  controller: _familyConditionsController,
                  onChanged: (value) {
                    ref
                        .read(medicalHistoryProvider.notifier)
                        .updateField(
                          (h) => h.copyWith(familyConditions: value),
                        );
                  },
                ),
                _buildTextField(
                  label: 'Grandparents Health Conditions',
                  hint: 'e.g., Heart Disease, Stroke, Cancer',
                  helperText:
                      'Health conditions in grandparents (maternal and paternal).',
                  example:
                      'Example: Maternal grandmother - Breast cancer (age 60), Paternal grandfather - Heart attack (age 65)',
                  followUp: const [
                    'What was their age at diagnosis?',
                    'Did they have any recurring conditions?',
                    'Any known hereditary diseases?',
                  ],
                ),
                _buildTextField(
                  label: 'Siblings Health Conditions',
                  hint: 'Health conditions affecting siblings',
                  helperText: 'Include full and half-siblings.',
                  example:
                      'Example: Brother - Astigmatism, Sister - No known conditions',
                  followUp: const [
                    'Any chronic conditions?',
                    'Same biological parents?',
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Section 3: Surgical History
            _MedicalHistorySection(
              title: 'Surgical History',
              sectionKey: 'surgical',
              icon: Icons.local_hospital,
              isExpanded: _sectionExpanded['surgical'] ?? false,
              onToggle: () => _toggleSection('surgical'),
              children: [
                _buildSurgeryField(
                  label: 'Past Surgeries',
                  hint: 'e.g., Appendectomy, Tonsillectomy',
                  helperText: 'List all surgical procedures you have had.',
                  example:
                      'Example: Appendectomy - 2019, City General Hospital, Dr. Smith',
                  followUp: const [
                    'When was the surgery performed?',
                    'Were there any complications?',
                    'What type of anesthesia was used?',
                  ],
                  warningSigns: const [
                    'Adverse reactions to anesthesia',
                    'Complications during recovery',
                    'Need for blood transfusions',
                  ],
                  controller: _surgicalHistoryController,
                  onChanged: (value) {
                    ref
                        .read(medicalHistoryProvider.notifier)
                        .updateField((h) => h.copyWith(surgicalHistory: value));
                  },
                ),
                _buildTextField(
                  label: 'Any Current Surgical Needs',
                  hint: 'e.g., Scheduled procedures, Recommendations',
                  helperText:
                      'Any upcoming surgeries or procedures recommended by doctors.',
                  example:
                      'Example: Orthodontist recommended wisdom tooth extraction',
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Section 4: Current Medications
            _MedicalHistorySection(
              title: 'Current Medications',
              sectionKey: 'medications',
              icon: Icons.medication,
              isExpanded: _sectionExpanded['medications'] ?? false,
              onToggle: () => _toggleSection('medications'),
              children: [
                _buildMedicationField(
                  label: 'Prescription Medications',
                  hint: 'e.g., Lisinopril 10mg once daily',
                  helperText:
                      'Include all prescription medications with dosage and frequency.',
                  example:
                      'Example: Metformin 500mg twice daily for diabetes management',
                  followUp: const [
                    'When did you start this medication?',
                    'Who prescribed it?',
                    'How do you take it (with food, etc.)?',
                  ],
                  warningSigns: const [
                    'Missed doses frequently',
                    'Experiencing new side effects',
                    'Difficulty affording medications',
                  ],
                ),
                _buildTextField(
                  label: 'Over-the-Counter Medications',
                  hint: 'e.g., Ibuprofen, Antacids, Vitamins',
                  helperText: 'Include supplements and vitamins.',
                  example:
                      'Example: Vitamin D 1000IU daily, Calcium supplement daily',
                  followUp: const [
                    'How often do you take them?',
                    'Any side effects noticed?',
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Section 5: Allergies
            _MedicalHistorySection(
              title: 'Allergies',
              sectionKey: 'allergies',
              icon: Icons.warning_amber,
              isExpanded: _sectionExpanded['allergies'] ?? false,
              onToggle: () => _toggleSection('allergies'),
              color: const Color(0xFFFF4D4F),
              children: [
                _buildAllergyField(
                  label: 'Drug Allergies',
                  hint: 'e.g., Penicillin, Aspirin',
                  helperText:
                      'List any drug allergies and the type of reaction.',
                  example:
                      'Example: Penicillin - Rash and hives, experienced at age 10',
                  followUp: const [
                    'What type of reaction did you experience?',
                    'How severe was the reaction?',
                    'When did this allergy first appear?',
                  ],
                  warningSigns: const [
                    'Anaphylactic reactions',
                    'Difficulty breathing',
                    'Severe skin reactions (Stevens-Johnson syndrome)',
                  ],
                  controller: _allergiesController,
                  onChanged: (value) {
                    ref
                        .read(medicalHistoryProvider.notifier)
                        .updateField((h) => h.copyWith(allergies: value));
                  },
                ),
                _buildAllergyField(
                  label: 'Food Allergies',
                  hint: 'e.g., Peanuts, Shellfish, Dairy',
                  helperText: 'Include food allergies and intolerances.',
                  example: 'Example: Peanut allergy - Severe, carry EpiPen',
                  followUp: const [
                    'What happens when you consume this food?',
                    'Have you been to ER due to this allergy?',
                  ],
                  warningSigns: const [
                    'Anaphylaxis requiring emergency care',
                    'Cross-contamination concerns',
                  ],
                ),
                _buildAllergyField(
                  label: 'Environmental Allergies',
                  hint: 'e.g., Pollen, Dust, Pet dander',
                  helperText: 'Seasonal or environmental allergens.',
                  example:
                      'Example: Pollen allergies - Seasonal rhinitis, use antihistamines',
                  followUp: const [
                    'What are your triggers?',
                    'What medications help?',
                    'Any associated conditions like asthma?',
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Section 6: Immunizations
            _MedicalHistorySection(
              title: 'Immunizations',
              sectionKey: 'immunizations',
              icon: Icons.vaccines,
              isExpanded: _sectionExpanded['immunizations'] ?? false,
              onToggle: () => _toggleSection('immunizations'),
              children: [
                _buildTextField(
                  label: 'Childhood Vaccinations',
                  hint: 'e.g., MMR, DPT, Polio',
                  helperText: 'List your childhood vaccination history.',
                  example:
                      'Example: All standard vaccinations completed per country schedule',
                  followUp: const [
                    'Do you have your vaccination records?',
                    'Any reactions to vaccines?',
                  ],
                  controller: _immunizationsController,
                  onChanged: (value) {
                    ref
                        .read(medicalHistoryProvider.notifier)
                        .updateField((h) => h.copyWith(immunizations: value));
                  },
                ),
                _buildTextField(
                  label: 'Recent Vaccinations',
                  hint: 'e.g., COVID-19, Flu shot, Tetanus',
                  helperText: 'Include any recent vaccines.',
                  example:
                      'Example: COVID-19 Booster - January 2026, Flu shot - October 2025',
                  followUp: const [
                    'When was your last flu shot?',
                    'Are you up to date with COVID-19 vaccinations?',
                  ],
                ),
                _buildTextField(
                  label: 'Travel Vaccinations',
                  hint: 'e.g., Yellow fever, Typhoid',
                  helperText: 'Any vaccinations required for travel.',
                  example: 'Example: Typhoid - 2022 before trip to India',
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Section 7: Social History
            _MedicalHistorySection(
              title: 'Social History',
              sectionKey: 'social',
              icon: Icons.people,
              isExpanded: _sectionExpanded['social'] ?? false,
              onToggle: () => _toggleSection('social'),
              children: [
                _buildTextField(
                  label: 'Tobacco Use',
                  hint: 'e.g., Never smoked, Former smoker, Current smoker',
                  helperText: 'Current and past tobacco use including vaping.',
                  example:
                      'Example: Never smoked cigarettes. Tried vaping once in college but never continued.',
                  followUp: const [
                    'How many packs per day?',
                    'How long have you smoked?',
                    'Have you tried to quit?',
                  ],
                  warningSigns: const [
                    'Coughing up blood',
                    'Shortness of breath',
                    'Frequent respiratory infections',
                  ],
                  controller: _socialHistoryController,
                  onChanged: (value) {
                    ref
                        .read(medicalHistoryProvider.notifier)
                        .updateField((h) => h.copyWith(socialHistory: value));
                  },
                ),
                _buildTextField(
                  label: 'Alcohol Use',
                  hint: 'e.g., Never, Social drinker, Daily drinker',
                  helperText: 'Frequency and amount of alcohol consumption.',
                  example:
                      'Example: Social drinker - 1-2 drinks per week on weekends',
                  followUp: const [
                    'What type of alcohol do you drink?',
                    'Have you ever felt you needed to cut down?',
                    'Any blackouts or memory loss?',
                  ],
                  warningSigns: const [
                    'Drinking to cope with stress',
                    'Increased tolerance',
                    'Relationship problems due to drinking',
                  ],
                ),
                _buildTextField(
                  label: 'Exercise and Physical Activity',
                  hint: 'e.g., Daily, Weekly, Rarely',
                  helperText: 'Describe your typical physical activity level.',
                  example:
                      'Example: Exercise 3-4 times per week - running and weight training',
                  followUp: const [
                    'What type of exercise do you do?',
                    'Any injuries during exercise?',
                  ],
                ),
                _buildTextField(
                  label: 'Dietary Habits',
                  hint: 'e.g., Balanced diet, Vegetarian, Fast food frequent',
                  helperText: 'Describe your typical eating patterns.',
                  example:
                      'Example: Mostly balanced diet with vegetables, occasional fast food 1-2 times per month',
                  followUp: const [
                    'Any specific diet restrictions?',
                    'Do you take any supplements?',
                  ],
                ),
                _buildTextField(
                  label: 'Occupation/Student Status',
                  hint: 'e.g., Student, Part-time job',
                  helperText: 'Current occupation or student status.',
                  example:
                      'Example: Full-time university student, studying Computer Science',
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Section 8: Review of Systems
            _MedicalHistorySection(
              title: 'Review of Systems',
              sectionKey: 'ros',
              icon: Icons.checklist,
              isExpanded: _sectionExpanded['ros'] ?? false,
              onToggle: () => _toggleSection('ros'),
              children: [
                _buildSystemCategory(
                  category: 'General',
                  symptoms: const [
                    'Fever or chills',
                    'Fatigue or weakness',
                    'Unexplained weight changes',
                    'Night sweats',
                  ],
                ),
                _buildSystemCategory(
                  category: 'Cardiovascular',
                  symptoms: const [
                    'Chest pain or discomfort',
                    'Shortness of breath',
                    'Palpitations',
                    'Swelling in legs',
                  ],
                ),
                _buildSystemCategory(
                  category: 'Respiratory',
                  symptoms: const [
                    'Chronic cough',
                    'Wheezing',
                    'Difficulty breathing',
                    'Sputum production',
                  ],
                ),
                _buildSystemCategory(
                  category: 'Gastrointestinal',
                  symptoms: const [
                    'Abdominal pain',
                    'Nausea or vomiting',
                    'Diarrhea or constipation',
                    'Blood in stool',
                  ],
                ),
                _buildSystemCategory(
                  category: 'Neurological',
                  symptoms: const [
                    'Headaches',
                    'Dizziness',
                    'Numbness or tingling',
                    'Memory problems',
                  ],
                ),
                _buildSystemCategory(
                  category: 'Musculoskeletal',
                  symptoms: const [
                    'Joint pain or swelling',
                    'Muscle pain',
                    'Back pain',
                    'Stiffness',
                  ],
                ),
                _buildSystemCategory(
                  category: 'Psychological',
                  symptoms: const [
                    'Anxiety or depression',
                    'Sleep problems',
                    'Mood changes',
                    'Stress level concerns',
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Submit Button - hidden for student
            if (_canEdit)
              ElevatedButton(
                onPressed: _saveMedicalHistory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3A86FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 32,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Save Medical History',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),

            const SizedBox(height: 16),

            // Approve/Revoke Button (only for doctors/school staff)
            if (_canEdit) _buildApprovalButtons(),

            const SizedBox(height: 16),

            // Export/Print Option - only shown if approved
            if (state.history?.isApproved == true)
              OutlinedButton.icon(
                onPressed: () => _exportHistory(state.history!),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Download Approved PDF'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF3A86FF),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 24,
                  ),
                  side: const BorderSide(color: Color(0xFF3A86FF)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            
            if (state.history?.isApproved == false && !_canEdit)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Your medical history is pending doctor approval to be downloaded as a PDF.',
                    style: TextStyle(color: Colors.orange, fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // Helper Methods

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required String helperText,
    String? example,
    List<String>? followUp,
    List<String>? warningSigns,
    TextEditingController? controller,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            onChanged: onChanged,
            readOnly: !_canEdit,
            maxLines: example != null ? 3 : 2,
            decoration: InputDecoration(
              hintText: hint,
              helperText: helperText,
              filled: true,
              fillColor: !_canEdit ? Colors.grey.shade100 : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF3A86FF),
                  width: 2,
                ),
              ),
            ),
          ),
          if (example != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF3A86FF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF3A86FF).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    size: 18,
                    color: Color(0xFF3A86FF),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      example,
                      style: const TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF3A86FF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (followUp != null) ...[
            const SizedBox(height: 12),
            _buildGuidanceSection(
              title: 'Follow-up Questions to Consider',
              items: followUp,
              icon: Icons.help_outline,
              color: Colors.blue,
            ),
          ],
          if (warningSigns != null) ...[
            const SizedBox(height: 12),
            _buildGuidanceSection(
              title: 'Warning Signs to Watch For',
              items: warningSigns,
              icon: Icons.warning_amber,
              color: Colors.orange,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGuidanceSection({
    required String title,
    required List<String> items,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(left: 26, bottom: 4),
              child: Text(
                '• $item',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Specialized field types
  Widget _buildSurgeryField({
    required String label,
    required String hint,
    required String helperText,
    String? example,
    List<String>? followUp,
    List<String>? warningSigns,
    TextEditingController? controller,
    ValueChanged<String>? onChanged,
  }) {
    return _buildTextField(
      label: label,
      hint: hint,
      helperText: helperText,
      example: example,
      followUp: followUp,
      warningSigns: warningSigns,
      controller: controller,
      onChanged: onChanged,
    );
  }

  Widget _buildMedicationField({
    required String label,
    required String hint,
    required String helperText,
    String? example,
    List<String>? followUp,
    List<String>? warningSigns,
    TextEditingController? controller,
    ValueChanged<String>? onChanged,
  }) {
    return _buildTextField(
      label: label,
      hint: hint,
      helperText: helperText,
      example: example,
      followUp: followUp,
      warningSigns: warningSigns,
      controller: controller,
      onChanged: onChanged,
    );
  }

  Widget _buildAllergyField({
    required String label,
    required String hint,
    required String helperText,
    String? example,
    List<String>? followUp,
    List<String>? warningSigns,
    TextEditingController? controller,
    ValueChanged<String>? onChanged,
  }) {
    return _buildTextField(
      label: label,
      hint: hint,
      helperText: helperText,
      example: example,
      followUp: followUp,
      warningSigns: warningSigns,
      controller: controller,
      onChanged: onChanged,
    );
  }

  Widget _buildSystemCategory({
    required String category,
    required List<String> symptoms,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: symptoms.map((symptom) {
              return FilterChip(
                label: Text(symptom),
                selected: false,
                onSelected: (selected) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Marked: $symptom'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                backgroundColor: Colors.white,
                selectedColor: const Color(0xFF3A86FF).withValues(alpha: 0.2),
                checkmarkColor: const Color(0xFF3A86FF),
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          TextFormField(
            maxLines: 1,
            readOnly: !_canEdit,
            decoration: InputDecoration(
              hintText: 'Add any other $category symptoms...',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveMedicalHistory() async {
    if (_formKey.currentState?.validate() ?? false) {
      final notifier = ref.read(medicalHistoryProvider.notifier);

      // Build updated history from controllers
      final state = ref.read(medicalHistoryProvider);
      final currentHistory = state.history;

      final updatedHistory =
          currentHistory?.copyWith(
            chronicConditions: _chronicConditionsController.text,
            pastIllnesses: _pastIllnessesController.text,
            hospitalizations: _hospitalizationsController.text,
            familyConditions: _familyConditionsController.text,
            surgicalHistory: _surgicalHistoryController.text,
            allergies: _allergiesController.text,
            immunizations: _immunizationsController.text,
            socialHistory: _socialHistoryController.text,
            reviewOfSystems: _reviewOfSystemsController.text,
          ) ??
          ref.read(medicalHistoryProvider).history;

      // Update the provider
      if (updatedHistory != null) {
        notifier.updateField(
          (h) => h.copyWith(
            chronicConditions: _chronicConditionsController.text,
            pastIllnesses: _pastIllnessesController.text,
            hospitalizations: _hospitalizationsController.text,
            familyConditions: _familyConditionsController.text,
            surgicalHistory: _surgicalHistoryController.text,
            allergies: _allergiesController.text,
            immunizations: _immunizationsController.text,
            socialHistory: _socialHistoryController.text,
            reviewOfSystems: _reviewOfSystemsController.text,
          ),
        );

        // Save to database
        final success = await notifier.save();

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Medical history saved successfully!'),
              backgroundColor: Color(0xFF2ECC71),
            ),
          );
          context.pop();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Failed to save medical history. Please try again.',
              ),
              backgroundColor: Color(0xFFE74C3C),
            ),
          );
        }
      }
    }
  }

  void _exportHistory(MedicalHistory history) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating Approved PDF...'),
        backgroundColor: Color(0xFF3A86FF),
      ),
    );

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Approved Medical History', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                _buildPdfSection('Chronic Conditions', history.chronicConditions),
                _buildPdfSection('Past Illnesses', history.pastIllnesses),
                _buildPdfSection('Hospitalizations', history.hospitalizations),
                _buildPdfSection('Family Medical Conditions', history.familyConditions),
                _buildPdfSection('Surgical History', history.surgicalHistory),
                _buildPdfSection('Allergies', history.allergies),
                _buildPdfSection('Immunizations', history.immunizations),
                _buildPdfSection('Social History', history.socialHistory),
                _buildPdfSection('Review of Systems', history.reviewOfSystems),
                pw.SizedBox(height: 30),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.green),
                  ),
                  child: pw.Text('VERIFIED & APPROVED BY DOCTOR', style: pw.TextStyle(color: PdfColors.green, fontWeight: pw.FontWeight.bold)),
                )
              ],
            )
          );
        },
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }

  pw.Widget _buildPdfSection(String title, String content) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
          pw.SizedBox(height: 4),
          pw.Text(content.isEmpty ? 'None reported' : content, style: const pw.TextStyle(fontSize: 12)),
        ]
      )
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Color(0xFF3A86FF)),
            SizedBox(width: 8),
            Text('How to Use This Form'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Complete All Sections',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 4),
              Text('Fill in as much information as possible for each section.'),
              SizedBox(height: 12),
              Text(
                '2. Use Examples as Guides',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 4),
              Text(
                'The blue example boxes show how to properly format your information.',
              ),
              SizedBox(height: 12),
              Text(
                '3. Review Warning Signs',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 4),
              Text(
                'Pay attention to warning signs - they indicate when to seek medical attention.',
              ),
              SizedBox(height: 12),
              Text(
                '4. Update Regularly',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 4),
              Text(
                'Keep this information current by updating after any new diagnoses or treatments.',
              ),
              SizedBox(height: 12),
              Text(
                '5. Share with Healthcare Providers',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 4),
              Text(
                'This information helps your healthcare team provide better care.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  // Build approval buttons for doctors/school staff
  Widget _buildApprovalButtons() {
    final state = ref.read(medicalHistoryProvider);
    final history = state.history;

    if (history == null) {
      return const SizedBox.shrink();
    }

    final isApproved = history.isApproved;

    if (isApproved) {
      // Show Revoke button
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2ECC71).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF2ECC71).withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified, color: Color(0xFF2ECC71), size: 20),
                SizedBox(width: 8),
                Text(
                  'Approved',
                  style: TextStyle(
                    color: Color(0xFF2ECC71),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Revoke Approval?'),
                  content: const Text(
                    'Are you sure you want to revoke approval? '
                    'The student will no longer be able to download the PDF until approved again.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Revoke'),
                    ),
                  ],
                ),
              );

              if (confirm == true && mounted) {
                await MedicalHistoryRepository.instance.revokeApproval(
                  history.id,
                );
                ref.invalidate(medicalHistoryProvider);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Approval revoked'),
                      backgroundColor: Color(0xFFE74C3C),
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.cancel, size: 18),
            label: const Text('Revoke Approval'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      );
    } else {
      // Show Approve button
      return ElevatedButton.icon(
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Approve Medical History?'),
              content: const Text(
                'By approving, you confirm that the medical information is accurate '
                'and the student will be able to download the PDF.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2ECC71),
                  ),
                  child: const Text('Approve'),
                ),
              ],
            ),
          );

          if (confirm == true && mounted) {
            await MedicalHistoryRepository.instance.approve(history.id);
            ref.invalidate(medicalHistoryProvider);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Medical history approved!'),
                  backgroundColor: Color(0xFF2ECC71),
                ),
              );
            }
          }
        },
        icon: const Icon(Icons.verified, size: 20),
        label: const Text('Approve Medical History'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2ECC71),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}

/// Reusable Section Widget with Expansion
class _MedicalHistorySection extends StatelessWidget {
  final String title;
  final String sectionKey;
  final IconData icon;
  final bool isExpanded;
  final VoidCallback onToggle;
  final List<Widget> children;
  final Color? color;

  const _MedicalHistorySection({
    required this.title,
    required this.sectionKey,
    required this.icon,
    required this.isExpanded,
    required this.onToggle,
    required this.children,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final sectionColor = color ?? const Color(0xFF3A86FF);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // Section Header
          InkWell(
            onTap: onToggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isExpanded
                    ? sectionColor.withValues(alpha: 0.1)
                    : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: sectionColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: sectionColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: sectionColor,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down, color: sectionColor),
                  ),
                ],
              ),
            ),
          ),
          // Section Content
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
