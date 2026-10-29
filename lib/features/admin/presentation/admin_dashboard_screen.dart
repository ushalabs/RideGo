import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedNavIndex = 0;

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
      SnackBar(
        content: Text('Operator application rejected.'),
        backgroundColor: AppColors.statusCancelled,
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isDesktop) ...[
                    // Mobile navigation chips
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
                  '18',
                  Icons.business,
                  AppColors.buttonTeal,
                ),
                _buildStatBox(
                  'Pending Applications',
                  '2',
                  Icons.pending_actions,
                  AppColors.statusPending,
                ),
                _buildStatBox(
                  'Total Bookings',
                  '3,942',
                  Icons.confirmation_number,
                  AppColors.statusConfirmed,
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
            children: const [
              Text(
                'Operator Approval Queue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              Text(
                '2 Applications',
                style: TextStyle(
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
          const Text(
            'Authoritative Fare Configuration Matrix',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          DataTable(
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
        children: const [
          Text(
            'Global Booking Audits',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 12),
          Text(
            'All passenger reservations, payments, and trip statuses are monitored in real time.',
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
