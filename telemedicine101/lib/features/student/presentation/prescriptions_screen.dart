import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/medication_models.dart';
import '../providers/prescription_provider.dart';

// Empty list - will be populated from provider
final List<Prescription> _mockPrescriptions = [];

// Empty reminders - will be populated from provider
final List<MedicationReminder> _upcomingReminders = [];

class PrescriptionsScreen extends ConsumerStatefulWidget {
  const PrescriptionsScreen({super.key});

  @override
  ConsumerState<PrescriptionsScreen> createState() =>
      _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends ConsumerState<PrescriptionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  PrescriptionStatus? _selectedFilter;
  DateTime? _historyStartDate;
  DateTime? _historyEndDate;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Filter prescriptions based on search and status (from provider)
  List<Prescription> get _filteredPrescriptions {
    final prescriptionState = ref.watch(prescriptionProvider);
    final prescriptions = prescriptionState.prescriptions;

    return prescriptions.where((prescription) {
      // Search filter
      final matchesSearch =
          _searchQuery.isEmpty ||
          prescription.medicationName.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          prescription.prescribingDoctor.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          prescription.pharmacy.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );

      // Status filter
      final matchesStatus =
          _selectedFilter == null || prescription.status == _selectedFilter;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  // Get metrics from provider
  int get _activeCount {
    final prescriptionState = ref.watch(prescriptionProvider);
    return prescriptionState.activePrescriptions.length;
  }

  int get _pendingRefills {
    final prescriptionState = ref.watch(prescriptionProvider);
    return prescriptionState.pendingPrescriptions.length;
  }

  int get _expiringSoon {
    final prescriptionState = ref.watch(prescriptionProvider);
    return prescriptionState.expiringSoonPrescriptions.length;
  }

  Color _getStatusColor(PrescriptionStatus status) {
    switch (status) {
      case PrescriptionStatus.active:
        return const Color(0xFF22C55E);
      case PrescriptionStatus.pending:
        return const Color(0xFFF59E0B);
      case PrescriptionStatus.completed:
        return const Color(0xFF3B82F6);
      case PrescriptionStatus.expired:
        return const Color(0xFFEF4444);
    }
  }

  String _getStatusLabel(PrescriptionStatus status) {
    switch (status) {
      case PrescriptionStatus.active:
        return 'Active';
      case PrescriptionStatus.pending:
        return 'Pending';
      case PrescriptionStatus.completed:
        return 'Completed';
      case PrescriptionStatus.expired:
        return 'Expired';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: const Color(0xFF5B8CFF),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            title: const Text(
              'Prescriptions',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notifications coming soon!')),
                  );
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'Active'),
                Tab(text: 'History'),
                Tab(text: 'Reminders'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildActiveTab(),
            _buildHistoryTab(),
            _buildRemindersTab(),
          ],
        ),
      ),
    );
  }

  // Active Tab with prescriptions list
  Widget _buildActiveTab() {
    return CustomScrollView(
      slivers: [
        // Summary Dashboard
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildSummaryDashboard(),
          ),
        ),

        // Search Bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSearchBar(),
          ),
        ),

        // Filter Chips
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildFilterChips(),
          ),
        ),

        // Prescription Cards
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: _filteredPrescriptions.isEmpty
              ? SliverToBoxAdapter(child: _buildEmptyState())
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _buildPrescriptionCard(_filteredPrescriptions[index]),
                    childCount: _filteredPrescriptions.length,
                  ),
                ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  // History Tab with date filtering
  Widget _buildHistoryTab() {
    return CustomScrollView(
      slivers: [
        // Date Filter
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildDateFilter(),
          ),
        ),

        // History List
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final prescriptionState = ref.watch(prescriptionProvider);
                final historyPrescriptions =
                    prescriptionState.historyPrescriptions;
                if (index >= historyPrescriptions.length) return null;
                return _buildPrescriptionCard(historyPrescriptions[index]);
              },
              childCount: ref
                  .watch(prescriptionProvider)
                  .historyPrescriptions
                  .length,
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  // Reminders Tab
  Widget _buildRemindersTab() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Upcoming Medication Reminders',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your scheduled medication times for today',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final prescriptionState = ref.watch(prescriptionProvider);
              final reminders = prescriptionState.reminders;
              if (index >= reminders.length) return null;
              return _buildReminderCard(reminders[index]);
            }, childCount: ref.watch(prescriptionProvider).reminders.length),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  // Summary Dashboard Widget
  Widget _buildSummaryDashboard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B8CFF), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B8CFF).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Prescription Overview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.medication,
                  label: 'Active',
                  value: _activeCount.toString(),
                  color: const Color(0xFF22C55E),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.pending_actions,
                  label: 'Pending',
                  value: _pendingRefills.toString(),
                  color: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.warning_amber,
                  label: 'Expiring',
                  value: _expiringSoon.toString(),
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Search Bar Widget
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search prescriptions...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF5B8CFF)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  // Filter Chips Widget
  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(null, 'All'),
          const SizedBox(width: 8),
          _buildFilterChip(PrescriptionStatus.active, 'Active'),
          const SizedBox(width: 8),
          _buildFilterChip(PrescriptionStatus.pending, 'Pending'),
          const SizedBox(width: 8),
          _buildFilterChip(PrescriptionStatus.completed, 'Completed'),
          const SizedBox(width: 8),
          _buildFilterChip(PrescriptionStatus.expired, 'Expired'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(PrescriptionStatus? status, String label) {
    final isSelected = _selectedFilter == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = selected ? status : null;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF5B8CFF).withValues(alpha: 0.2),
      checkmarkColor: const Color(0xFF5B8CFF),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF5B8CFF) : const Color(0xFF64748B),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFF5B8CFF) : const Color(0xFFE2E8F0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  // Date Filter Widget
  Widget _buildDateFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter by Date',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDatePicker(
                  label: 'From',
                  date: _historyStartDate,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _historyStartDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _historyStartDate = date;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDatePicker(
                  label: 'To',
                  date: _historyEndDate,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _historyEndDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _historyEndDate = date;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          if (_historyStartDate != null || _historyEndDate != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                setState(() {
                  _historyStartDate = null;
                  _historyEndDate = null;
                });
              },
              child: const Text('Clear Filters'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today,
              size: 18,
              color: Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date != null ? DateFormat('MMM dd, yyyy').format(date) : label,
                style: TextStyle(
                  color: date != null
                      ? const Color(0xFF1E293B)
                      : const Color(0xFF94A3B8),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Prescription Card Widget
  Widget _buildPrescriptionCard(Prescription prescription) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(
                prescription.status,
              ).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.medication,
                      color: _getStatusColor(prescription.status),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      prescription.medicationName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(prescription.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusLabel(prescription.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Dosage and Frequency
                Row(
                  children: [
                    _buildInfoChip(
                      icon: Icons.science,
                      label: prescription.dosage,
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      icon: Icons.schedule,
                      label: prescription.frequency,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Doctor and Pharmacy
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailRow(
                        icon: Icons.person,
                        label: 'Dr.',
                        value: prescription.prescribingDoctor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailRow(
                        icon: Icons.local_pharmacy,
                        label: 'Pharmacy',
                        value: prescription.pharmacy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  icon: Icons.calendar_today,
                  label: 'Prescribed',
                  value: DateFormat(
                    'MMM dd, yyyy',
                  ).format(prescription.datePrescribed),
                ),
                if (prescription.expiryDate != null) ...[
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    icon: Icons.event_busy,
                    label: 'Expires',
                    value: DateFormat(
                      'MMM dd, yyyy',
                    ).format(prescription.expiryDate!),
                    valueColor:
                        prescription.expiryDate!
                                .difference(DateTime.now())
                                .inDays <=
                            7
                        ? const Color(0xFFEF4444)
                        : null,
                  ),
                ],

                // Refill Status
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.refresh,
                            size: 20,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Refills: ${prescription.refillsRemaining} of ${prescription.refillsTotal}',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (prescription.refillsRemaining > 0)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: prescription.refillsRemaining > 1
                                ? const Color(0xFF22C55E)
                                : const Color(0xFFF59E0B),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),

                // Instructions
                if (prescription.instructions != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Color(0xFFD97706),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            prescription.instructions!,
                            style: const TextStyle(
                              color: Color(0xFF92400E),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              children: [
                // Order Now Button (links to medical store)
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.push('/medical-store');
                    },
                    icon: const Icon(Icons.shopping_cart, size: 18),
                    label: const Text('Order Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B8CFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Request Refill Button
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: prescription.refillsRemaining > 0
                        ? () async {
                            final notifier = ref.read(
                              prescriptionProvider.notifier,
                            );
                            final success = await notifier.requestRefill(
                              prescription.id,
                            );
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Refill request submitted for ${prescription.medicationName}',
                                  ),
                                  backgroundColor: const Color(0xFF22C55E),
                                ),
                              );
                            }
                          }
                        : null,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Refill'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF5B8CFF),
                      side: const BorderSide(color: Color(0xFF5B8CFF)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // View Details Button
                Expanded(
                  child: IconButton(
                    onPressed: () {
                      _showPrescriptionDetails(prescription);
                    },
                    icon: const Icon(Icons.visibility),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      foregroundColor: const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? const Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // Reminder Card Widget
  Widget _buildReminderCard(MedicationReminder reminder) {
    final timeDiff = reminder.scheduledTime!.difference(DateTime.now());
    final hours = timeDiff.inHours;
    final minutes = timeDiff.inMinutes % 60;

    String timeText;
    if (hours > 0) {
      timeText = 'In $hours hr ${minutes > 0 ? '$minutes min' : ''}';
    } else if (minutes > 0) {
      timeText = 'In $minutes minutes';
    } else {
      timeText = 'Now';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF5B8CFF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.alarm, color: Color(0xFF5B8CFF), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.medicationName ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('h:mm a').format(reminder.scheduledTime!),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  timeText,
                  style: const TextStyle(
                    color: Color(0xFFD97706),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Marked as taken!'),
                      backgroundColor: Color(0xFF22C55E),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Take'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Empty State Widget
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.search_off,
              size: 48,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No prescriptions found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // Show Prescription Details Modal
  void _showPrescriptionDetails(Prescription prescription) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        prescription.status,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.medication,
                      color: _getStatusColor(prescription.status),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prescription.medicationName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          prescription.dosage,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            const Divider(),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildDetailItem(
                      icon: Icons.person,
                      title: 'Prescribing Doctor',
                      value: prescription.prescribingDoctor,
                    ),
                    _buildDetailItem(
                      icon: Icons.local_pharmacy,
                      title: 'Pharmacy',
                      value: prescription.pharmacy,
                    ),
                    _buildDetailItem(
                      icon: Icons.schedule,
                      title: 'Frequency',
                      value: prescription.frequency,
                    ),
                    _buildDetailItem(
                      icon: Icons.calendar_today,
                      title: 'Date Prescribed',
                      value: DateFormat(
                        'MMMM dd, yyyy',
                      ).format(prescription.datePrescribed),
                    ),
                    if (prescription.expiryDate != null)
                      _buildDetailItem(
                        icon: Icons.event_busy,
                        title: 'Expiry Date',
                        value: DateFormat(
                          'MMMM dd, yyyy',
                        ).format(prescription.expiryDate!),
                      ),
                    _buildDetailItem(
                      icon: Icons.refresh,
                      title: 'Refills Remaining',
                      value:
                          '${prescription.refillsRemaining} of ${prescription.refillsTotal}',
                    ),
                    _buildDetailItem(
                      icon: Icons.tag,
                      title: 'Prescription ID',
                      value: prescription.id,
                    ),
                    if (prescription.instructions != null)
                      _buildDetailItem(
                        icon: Icons.info,
                        title: 'Instructions',
                        value: prescription.instructions!,
                      ),
                  ],
                ),
              ),
            ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/medical-store');
                      },
                      icon: const Icon(Icons.shopping_cart),
                      label: const Text('Order Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B8CFF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        if (prescription.refillsRemaining > 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Refill request submitted for ${prescription.medicationName}',
                              ),
                              backgroundColor: const Color(0xFF22C55E),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Request Refill'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF5B8CFF),
                        side: const BorderSide(color: Color(0xFF5B8CFF)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF64748B)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
