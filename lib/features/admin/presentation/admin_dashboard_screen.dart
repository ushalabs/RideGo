import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../bookings/data/booking_repository.dart';
import '../../bookings/models/booking_model.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedNavIndex = 0;
  final _bookingRepo = BookingRepository();

  List<BookingModel> _bookings = [];
  bool _isLoading = true;

  final List<Map<String, dynamic>> _pendingOperators = [
    {
      'id': 'op-app-1',
      'ownerName': 'Eduardo Tan',
      'businessName': 'GrandTours Samar Inc.',
      'email': 'eduardo@grandtours.ph',
      'phone': '+63 917 555 4321',
      'location': 'Catbalogan Terminal, Samar',
      'vehicles': 6,
      'status': 'Pending Review',
    },
    {
      'id': 'op-app-2',
      'ownerName': 'Rosario Mendoza',
      'businessName': 'Leyte Coastal Transit',
      'email': 'rosario@leytecoastal.ph',
      'phone': '+63 918 888 1234',
      'location': 'Tacloban Bus Terminal, Leyte',
      'vehicles': 4,
      'status': 'Pending Review',
    },
  ];

  final List<Map<String, dynamic>> _fareRules = [
    {
      'corridor': 'Catbalogan - Tacloban',
      'category': 'Van',
      'base': 150.0,
      'status': 'Active',
    },
    {
      'corridor': 'Catbalogan - Calbayog',
      'category': 'Van',
      'base': 140.0,
      'status': 'Active',
    },
    {
      'corridor': 'Catbalogan - Tacloban',
      'category': 'Bus',
      'base': 200.0,
      'status': 'Active',
    },
    {
      'corridor': 'Tacloban - Ormoc',
      'category': 'Van',
      'base': 200.0,
      'status': 'Active',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadLiveAdminData();
    _bookingRepo.subscribeToRealtimeBookings(() {
      if (mounted) _loadLiveAdminData();
    });
  }

  @override
  void dispose() {
    _bookingRepo.unsubscribeRealtime();
    super.dispose();
  }

  Future<void> _loadLiveAdminData() async {
    final bList = await _bookingRepo.getBookings();
    if (mounted) {
      setState(() {
        _bookings = bList;
        _isLoading = false;
      });
    }
  }

  double get _totalBookedValue {
    return _bookings
        .where((b) => b.status != BookingStatus.cancelled)
        .fold(0.0, (sum, b) => sum + b.totalFare);
  }

  double get _actualCollectedCash {
    return _bookings
        .where((b) => b.paymentStatus == 'Paid (Cash)')
        .fold(0.0, (sum, b) => sum + b.totalFare);
  }

  void _approveOperator(int index) {
    setState(() {
      _pendingOperators[index]['status'] = 'Approved';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Operator ${_pendingOperators[index]['businessName']} approved!',
        ),
        backgroundColor: AppColors.statusConfirmed,
      ),
    );
  }

  void _rejectOperator(int index) {
    setState(() {
      _pendingOperators[index]['status'] = 'Rejected';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Operator application rejected.'),
        backgroundColor: AppColors.statusCancelled,
      ),
    );
  }

  void _showAddFareRuleModal() {
    final corridorCtrl = TextEditingController();
    final baseCtrl = TextEditingController();
    String cat = 'Van';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Authoritative Fare Rule'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: corridorCtrl,
              decoration: const InputDecoration(labelText: 'Corridor Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: baseCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Base Fare (PHP ₱)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: cat,
              decoration: const InputDecoration(labelText: 'Vehicle Category'),
              items: [
                'Van',
                'Bus',
                'Motor',
                'Car',
              ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => cat = v!,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonTeal,
            ),
            onPressed: () {
              if (corridorCtrl.text.isNotEmpty && baseCtrl.text.isNotEmpty) {
                setState(() {
                  _fareRules.add({
                    'corridor': corridorCtrl.text.trim(),
                    'category': cat,
                    'base': double.tryParse(baseCtrl.text) ?? 150.0,
                    'status': 'Active',
                  });
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text(
              'Save Rule',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('RideGo Admin Console (Samar & Leyte)'),
        backgroundColor: AppColors.headerNavy,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Row(
        children: [
          // Sidebar on desktop
          if (isDesktop)
            Container(
              width: 240,
              color: AppColors.headerNavy,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.admin_panel_settings,
                          color: AppColors.accentCyan,
                          size: 28,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'System Admin',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 32),
                  _buildSidebarItem(0, Icons.dashboard_outlined, 'Overview'),
                  _buildSidebarItem(
                    1,
                    Icons.business_outlined,
                    'Operator Approvals',
                  ),
                  _buildSidebarItem(2, Icons.alt_route, 'Routes & Corridors'),
                  _buildSidebarItem(3, Icons.payments_outlined, 'Fare Matrix'),
                  _buildSidebarItem(
                    4,
                    Icons.confirmation_number_outlined,
                    'All Bookings',
                  ),
                  const Spacer(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.white70),
                    title: const Text(
                      'Exit to App',
                      style: TextStyle(color: Colors.white70),
                    ),
                    onTap: () => context.go('/home'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

          // Main Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.headerNavy,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isDesktop) ...[
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildMobileNavChip(0, 'Overview'),
                                _buildMobileNavChip(1, 'Approvals'),
                                _buildMobileNavChip(2, 'Routes'),
                                _buildMobileNavChip(3, 'Fares'),
                                _buildMobileNavChip(4, 'Bookings'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        if (_selectedNavIndex == 0) _buildOverviewSection(),
                        if (_selectedNavIndex == 1) _buildApprovalsSection(),
                        if (_selectedNavIndex == 2) _buildRoutesSection(),
                        if (_selectedNavIndex == 3) _buildFareSection(),
                        if (_selectedNavIndex == 4) _buildBookingsSection(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String label) {
    final isSelected = _selectedNavIndex == index;
    return ListTile(
      selected: isSelected,
      selectedTileColor: AppColors.buttonTeal.withOpacity(0.3),
      leading: Icon(
        icon,
        color: isSelected ? AppColors.accentCyan : Colors.white70,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      onTap: () => setState(() => _selectedNavIndex = index),
    );
  }

  Widget _buildMobileNavChip(int index, String label) {
    final isSelected = _selectedNavIndex == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.buttonTeal,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.headerNavy,
          fontWeight: FontWeight.w700,
        ),
        onSelected: (val) {
          if (val) setState(() => _selectedNavIndex = index);
        },
      ),
    );
  }

  Widget _buildOverviewSection() {
    final pendingOps = _pendingOperators
        .where((o) => o['status'] == 'Pending Review')
        .length;
    final approvedOps = _pendingOperators
        .where((o) => o['status'] == 'Approved')
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'System Metrics & Transport Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.headerNavy,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth > 900
                ? 4
                : (constraints.maxWidth > 500 ? 2 : 1);
            return GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildStatBox(
                  'Registered Customers',
                  '1,428',
                  Icons.people,
                  AppColors.headerNavy,
                ),
                _buildStatBox(
                  'Approved Operators',
                  '$approvedOps',
                  Icons.business,
                  AppColors.buttonTeal,
                ),
                _buildStatBox(
                  'Pending Applications',
                  '$pendingOps',
                  Icons.pending_actions,
                  AppColors.statusPending,
                ),
                _buildStatBox(
                  'Total Bookings',
                  '${_bookings.length}',
                  Icons.confirmation_number,
                  AppColors.statusConfirmed,
                ),
                _buildStatBox(
                  'Booked Value',
                  CurrencyFormatter.format(_totalBookedValue),
                  Icons.request_quote,
                  AppColors.headerNavy,
                ),
                _buildStatBox(
                  'Collected Cash',
                  CurrencyFormatter.format(_actualCollectedCash),
                  Icons.payments,
                  AppColors.statusConfirmed,
                ),
                _buildStatBox(
                  'Active Corridors',
                  '2',
                  Icons.alt_route,
                  AppColors.buttonTeal,
                ),
                _buildStatBox(
                  'Coverage Hubs',
                  '18',
                  Icons.place,
                  AppColors.headerNavy,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        _buildApprovalsSection(),
      ],
    );
  }

  Widget _buildApprovalsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Operator Approval Queue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              Text(
                '${_pendingOperators.length} Applications',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _pendingOperators.length,
            separatorBuilder: (_, __) => const Divider(height: 20),
            itemBuilder: (context, index) {
              final op = _pendingOperators[index];
              final isApproved = op['status'] == 'Approved';
              final isRejected = op['status'] == 'Rejected';

              return Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.headerNavy,
                    child: const Icon(
                      Icons.directions_bus,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          op['businessName'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Owner: ${op['ownerName']} • Phone: ${op['phone']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          'Terminal: ${op['location']} • Fleet: ${op['vehicles']} units',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isApproved && !isRejected) ...[
                    OutlinedButton(
                      onPressed: () => _rejectOperator(index),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.statusCancelled,
                      ),
                      child: const Text('Reject'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _approveOperator(index),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonTeal,
                      ),
                      child: const Text(
                        'Approve',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (isApproved
                                    ? AppColors.statusConfirmed
                                    : AppColors.statusCancelled)
                                .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        op['status'],
                        style: TextStyle(
                          color: isApproved
                              ? AppColors.statusConfirmed
                              : AppColors.statusCancelled,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRoutesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Supported Corridors & Service Networks',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 12),
          Text(
            '1. Southbound Corridor: Catbalogan City → Paranas → Motiong → Jiabong → Villareal → Calbiga → Basey → Marabut → Santa Rita → San Juanico Bridge → Tacloban City, Leyte',
          ),
          SizedBox(height: 8),
          Text(
            '2. Northbound Corridor: Catbalogan City → Jiabong → Motiong → San Jorge → Gandara → Pagsanghan → Tarangnan → Santa Margarita → Calbayog City',
          ),
        ],
      ),
    );
  }

  Widget _buildFareSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Authoritative Fare Configuration Matrix',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: const Text(
                  'Add Rule',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonTeal,
                ),
                onPressed: _showAddFareRuleModal,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Corridor')),
                DataColumn(label: Text('Category')),
                DataColumn(label: Text('Base Fare')),
                DataColumn(label: Text('Status')),
              ],
              rows: _fareRules.map((f) {
                return DataRow(
                  cells: [
                    DataCell(Text(f['corridor'])),
                    DataCell(Text(f['category'])),
                    DataCell(Text(CurrencyFormatter.format(f['base']))),
                    DataCell(Text(f['status'])),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Global Booking Oversight',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Ref')),
                DataColumn(label: Text('Operator')),
                DataColumn(label: Text('Trip')),
                DataColumn(label: Text('Departure')),
                DataColumn(label: Text('Fare')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Payment')),
              ],
              rows: _bookings.map((b) {
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        b.reference,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.buttonTeal,
                        ),
                      ),
                    ),
                    DataCell(Text(b.operatorName)),
                    DataCell(
                      Text('${b.pickupLocation} → ${b.dropoffLocation}'),
                    ),
                    DataCell(
                      Text(DateFormatter.formatShortDate(b.departureTime)),
                    ),
                    DataCell(Text(CurrencyFormatter.format(b.totalFare))),
                    DataCell(Text(b.status.displayName)),
                    DataCell(Text(b.paymentStatus)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
