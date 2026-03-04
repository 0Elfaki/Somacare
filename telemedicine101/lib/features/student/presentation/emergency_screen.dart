import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────────────
// Emergency Screen — localized for the Uganda health system
// ─────────────────────────────────────────────────────────────────────

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen>
    with SingleTickerProviderStateMixin {
  // ── Animation ───────────────────────────────────────────────────
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  // ── State ───────────────────────────────────────────────────────
  bool _sosActive = false;
  bool _sendingAlert = false;
  String? _schoolName;

  // ── Ugandan emergency contacts ─────────────────────────────────
  static const List<_EmergencyContact> _contacts = [
    _EmergencyContact(
      icon: Icons.local_hospital,
      title: 'Campus Health Center',
      subtitle: 'University / School Clinic',
      phone: '',
      color: Color(0xFF059669),
      isPlaceholder: true,
    ),
    _EmergencyContact(
      icon: Icons.shield_outlined,
      title: 'Uganda Police',
      subtitle: 'National Emergency Line',
      phone: '999',
      color: Color(0xFF2563EB),
    ),
    _EmergencyContact(
      icon: Icons.local_hospital_outlined,
      title: 'KCCA Ambulance',
      subtitle: 'Kampala Ambulance Service',
      phone: '911',
      color: Color(0xFFDC2626),
    ),
    _EmergencyContact(
      icon: Icons.health_and_safety,
      title: 'Uganda Red Cross',
      subtitle: 'Toll-Free Emergency Line',
      phone: '0800100250',
      color: Color(0xFFDC2626),
      displayPhone: '0800 100 250',
    ),
    _EmergencyContact(
      icon: Icons.local_fire_department,
      title: 'Fire Emergency',
      subtitle: 'National Emergency (Fire)',
      phone: '112',
      color: Color(0xFFD97706),
    ),
    _EmergencyContact(
      icon: Icons.science_outlined,
      title: 'Poison Control (NDA)',
      subtitle: 'National Drug Authority',
      phone: '0800101999',
      color: Color(0xFF7C3AED),
      displayPhone: '0800 101 999',
    ),
    _EmergencyContact(
      icon: Icons.people_outline,
      title: 'GBV Hotline (MGLSD)',
      subtitle: 'Gender-Based Violence Support',
      phone: '0800111222',
      color: Color(0xFFDB2777),
      displayPhone: '0800 111 222',
    ),
  ];

  // ── Uganda-specific first aid tips ─────────────────────────────
  static const List<_FirstAidTip> _firstAidTips = [
    _FirstAidTip(
      icon: Icons.bug_report,
      title: 'Malaria Emergency',
      summary: 'High fever, convulsions, confusion — seek care immediately.',
      detail:
          'Cerebral malaria is life-threatening, especially in children under 5. '
          'Signs include high fever (≥ 39 °C), repeated convulsions, unusual '
          'drowsiness or confusion, and inability to eat or drink.\n\n'
          '• Give paracetamol to reduce fever (NOT aspirin for children).\n'
          '• Sponge the body with lukewarm water.\n'
          '• If the person is convulsing, lay them on their side and clear the '
          'airway — do NOT put anything in their mouth.\n'
          '• Rush to the nearest Health Centre IV or Regional Referral Hospital '
          'for IV artesunate treatment.',
      color: Color(0xFFD97706),
    ),
    _FirstAidTip(
      icon: Icons.water_drop,
      title: 'Cholera / Diarrhoea',
      summary:
          'Rehydrate with ORS — 6 teaspoons sugar, ½ teaspoon salt per litre.',
      detail:
          'Acute watery diarrhoea can kill within hours through dehydration.\n\n'
          'Prepare ORS at home:\n'
          '• 1 litre of clean (boiled) water\n'
          '• 6 level teaspoons of sugar\n'
          '• ½ level teaspoon of salt\n'
          '• Stir until dissolved; give frequent small sips.\n\n'
          'Danger signs requiring hospital care:\n'
          '• Sunken eyes, dry mouth, no tears when crying\n'
          '• Very little or no urine\n'
          '• Rapid weak pulse or loss of consciousness\n\n'
          'Go to the nearest Health Centre III or higher immediately.',
      color: Color(0xFF2563EB),
    ),
    _FirstAidTip(
      icon: Icons.pest_control,
      title: 'Snakebite First Aid',
      summary: 'Keep still, immobilise the limb, get to hospital fast.',
      detail:
          'Uganda has several venomous species (black mamba, puff adder, '
          'spitting cobra). Quick action saves lives.\n\n'
          '• Keep the victim calm and still — movement spreads venom faster.\n'
          '• Immobilise the bitten limb with a splint; keep it below heart level.\n'
          '• Remove rings, watches, or tight clothing near the bite.\n'
          '• Do NOT cut the wound, suck the venom, or apply a tourniquet.\n'
          '• Do NOT apply herbs or traditional remedies — they delay treatment.\n'
          '• Transport to a hospital with anti-venom (Regional Referral Hospital '
          'or Mulago National Referral Hospital).\n'
          '• Note the snake\'s appearance if possible to help doctors choose '
          'the correct anti-venom.',
      color: Color(0xFF059669),
    ),
    _FirstAidTip(
      icon: Icons.directions_car,
      title: 'Road Traffic Accident',
      summary: 'Secure the scene, call 911, do not move spinal injuries.',
      detail:
          'Uganda has one of the highest road traffic accident rates in Africa.\n\n'
          '• Ensure your own safety first — move away from traffic.\n'
          '• Call 911 (KCCA Ambulance) or 999 (Police) immediately.\n'
          '• Do NOT move a victim who may have a spinal injury unless they are '
          'in immediate danger (fire, oncoming traffic).\n'
          '• Control bleeding with firm pressure using a clean cloth.\n'
          '• If the person is unconscious but breathing, place them in the '
          'recovery position (on their side).\n'
          '• Keep the victim warm with a blanket or jacket.\n'
          '• Do NOT give food or water to an injured person.',
      color: Color(0xFFDC2626),
    ),
    _FirstAidTip(
      icon: Icons.wb_sunny,
      title: 'Heat & Dehydration',
      summary: 'Move to shade, cool the body, give fluids slowly.',
      detail:
          'Heat exhaustion can progress to heatstroke, which is a medical '
          'emergency.\n\n'
          'Signs: heavy sweating, weakness, nausea, headache, fast pulse.\n\n'
          '• Move the person to a cool, shaded area.\n'
          '• Loosen or remove excess clothing.\n'
          '• Apply cool wet cloths to the neck, armpits, and forehead.\n'
          '• Give small sips of clean water or ORS.\n'
          '• If the person stops sweating, becomes confused, or loses '
          'consciousness — this is heatstroke. Call 911 and cool them '
          'aggressively while waiting for help.',
      color: Color(0xFFD97706),
    ),
    _FirstAidTip(
      icon: Icons.local_hospital,
      title: 'HC II/III/IV vs Hospital',
      summary: 'Know when to visit a health centre vs. a referral hospital.',
      detail:
          'Uganda\'s health system has different facility levels:\n\n'
          '• HC II — Basic outpatient care, first aid, health education. '
          'Visit for minor illnesses, wound dressing, malaria testing.\n\n'
          '• HC III — Has a laboratory and maternity ward. Visit for lab '
          'tests, uncomplicated deliveries, and moderate illness.\n\n'
          '• HC IV — Has a theatre (operating room) and can handle '
          'emergencies, caesarean sections, and blood transfusions.\n\n'
          '• Regional Referral Hospital — Specialist doctors, ICU, '
          'advanced diagnostics. Go here for severe trauma, surgical '
          'emergencies, snakebite anti-venom, and cerebral malaria.\n\n'
          '• National Referral (Mulago / Kiruddu / Kawempe) — Highest '
          'level of care for the most complex cases.',
      color: Color(0xFF7C3AED),
    ),
  ];

  // ── Lifecycle ──────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadSchoolName();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────
  Future<void> _loadSchoolName() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('school_name')
          .eq('id', userId)
          .maybeSingle();
      if (mounted && profile != null) {
        setState(() => _schoolName = profile['school_name'] as String?);
      }
    } catch (_) {
      // School name is a non-critical UI detail.
    }
  }

  Future<void> _dialPhone(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      _showSnackBar('Could not open the phone dialer.', isError: true);
    }
  }

  Future<void> _openNearestHospitalMap() async {
    // Try Google Maps geo search first, fall back to browser.
    final googleMapsUri = Uri.parse(
      'https://www.google.com/maps/search/hospital+near+me',
    );
    if (await canLaunchUrl(googleMapsUri)) {
      await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      _showSnackBar('Could not open maps.', isError: true);
    }
  }

  Future<void> _triggerSOS() async {
    if (_sendingAlert) return;
    setState(() {
      _sosActive = true;
      _sendingAlert = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client.from('emergency_alerts').insert({
          'user_id': user.id,
          'status': 'active',
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      if (mounted) {
        _showSnackBar(
          'Emergency alert sent! Campus health team has been notified.',
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Could not send alert: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _sendingAlert = false);
    }
  }

  void _cancelSOS() {
    setState(() => _sosActive = false);
    _showSnackBar('SOS cancelled.');
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? const Color(0xFFDC2626)
            : const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFDC2626),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Emergency',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildAmbulanceHeader(),
            const SizedBox(height: 16),
            _buildQuickActions(),
            const SizedBox(height: 24),
            _buildSectionTitle('Emergency Contacts'),
            const SizedBox(height: 8),
            ..._contacts.map(_buildContactCard),
            const SizedBox(height: 24),
            _buildSectionTitle('First Aid — Uganda Health Context'),
            const SizedBox(height: 8),
            _buildFirstAidGrid(),
            const SizedBox(height: 24),
            _buildSectionTitle('What To Do In An Emergency'),
            const SizedBox(height: 8),
            _buildEmergencySteps(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Ambulance header with pulsing call button ──────────────────
  Widget _buildAmbulanceHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: Column(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.white,
            size: 36,
          ),
          const SizedBox(height: 6),
          const Text(
            'CALL AN AMBULANCE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'KCCA Ambulance — Dial 911',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),

          // Pulsing ambulance call button
          ScaleTransition(
            scale: _pulseAnimation,
            child: GestureDetector(
              onTap: () => _dialPhone('911'),
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.shade900.withValues(alpha: 0.5),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone, size: 38, color: Color(0xFFDC2626)),
                    SizedBox(height: 4),
                    Text(
                      '911',
                      style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // SOS alert row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeaderPill(
                label: _sosActive ? 'Cancel SOS' : 'Send SOS Alert',
                icon: _sosActive ? Icons.close : Icons.sos,
                color: _sosActive
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.15),
                isLoading: _sendingAlert,
                onTap: _sosActive ? _cancelSOS : _triggerSOS,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderPill({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Quick action buttons (Map + Police) ────────────────────────
  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _QuickActionButton(
              icon: Icons.map_outlined,
              label: 'Find Nearest\nHospital',
              color: const Color(0xFF2563EB),
              onTap: _openNearestHospitalMap,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _QuickActionButton(
              icon: Icons.shield_outlined,
              label: 'Call Uganda\nPolice (999)',
              color: const Color(0xFF1E3A5F),
              onTap: () => _dialPhone('999'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _QuickActionButton(
              icon: Icons.local_fire_department,
              label: 'Fire\nEmergency (112)',
              color: const Color(0xFFD97706),
              onTap: () => _dialPhone('112'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section title ──────────────────────────────────────────────
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
      ),
    );
  }

  // ── Contact card ───────────────────────────────────────────────
  Widget _buildContactCard(_EmergencyContact contact) {
    final subtitle = contact.isPlaceholder && _schoolName != null
        ? '$_schoolName Health Services'
        : contact.subtitle;

    final phoneDisplay = contact.displayPhone ?? contact.phone;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: contact.phone.isNotEmpty
              ? () => _dialPhone(contact.phone)
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon badge
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: contact.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(contact.icon, color: contact.color, size: 24),
                ),
                const SizedBox(width: 14),

                // Title + subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Call pill
                if (contact.phone.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: contact.color,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.phone, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          phoneDisplay,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Check locally',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── First aid grid ─────────────────────────────────────────────
  Widget _buildFirstAidGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.05,
        ),
        itemCount: _firstAidTips.length,
        itemBuilder: (_, index) => _buildFirstAidCard(_firstAidTips[index]),
      ),
    );
  }

  Widget _buildFirstAidCard(_FirstAidTip tip) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showFirstAidDetail(tip),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tip.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(tip.icon, color: tip.color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                tip.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  tip.summary,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.grey.shade600,
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFirstAidDetail(_FirstAidTip tip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title row
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: tip.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(tip.icon, color: tip.color, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      tip.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Detail text
              Text(
                tip.detail,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF475569),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),

              // Warning banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFFDC2626),
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'If the situation is life-threatening, call 911 '
                        '(KCCA Ambulance) or 999 (Police) immediately.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Emergency steps ────────────────────────────────────────────
  Widget _buildEmergencySteps() {
    const steps = [
      _EmergencyStep(
        number: '1',
        title: 'Stay Calm',
        description: 'Take a deep breath. Assess the situation before acting.',
        icon: Icons.self_improvement,
      ),
      _EmergencyStep(
        number: '2',
        title: 'Call For Help',
        description:
            'Tap the 911 button above or call campus security / police (999).',
        icon: Icons.phone_in_talk,
      ),
      _EmergencyStep(
        number: '3',
        title: 'Provide First Aid',
        description:
            'If trained, provide basic first aid while waiting for help.',
        icon: Icons.medical_services_outlined,
      ),
      _EmergencyStep(
        number: '4',
        title: 'Stay With The Person',
        description:
            'Do not leave the person alone. Keep them comfortable and warm.',
        icon: Icons.people_outline,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: steps.map((step) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          step.number,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            step.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(step.icon, color: Colors.grey.shade400, size: 22),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Reusable quick-action button widget
// ─────────────────────────────────────────────────────────────────────
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Data models (private to this file)
// ─────────────────────────────────────────────────────────────────────
class _EmergencyContact {
  final IconData icon;
  final String title;
  final String subtitle;
  final String phone;
  final Color color;
  final String? displayPhone;
  final bool isPlaceholder;

  const _EmergencyContact({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.phone,
    required this.color,
    this.displayPhone,
    this.isPlaceholder = false,
  });
}

class _FirstAidTip {
  final IconData icon;
  final String title;
  final String summary;
  final String detail;
  final Color color;

  const _FirstAidTip({
    required this.icon,
    required this.title,
    required this.summary,
    required this.detail,
    required this.color,
  });
}

class _EmergencyStep {
  final String number;
  final String title;
  final String description;
  final IconData icon;

  const _EmergencyStep({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
  });
}
