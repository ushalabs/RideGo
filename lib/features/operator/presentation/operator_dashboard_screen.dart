import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/custom_button.dart';

class OperatorDashboardScreen extends StatefulWidget {
  const OperatorDashboardScreen({super.key});

  @override
  State<OperatorDashboardScreen> createState() =>
      _OperatorDashboardScreenState();
}

class _OperatorDashboardScreenState extends State<OperatorDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isApproved = true; // Toggleable for demo

  final List<Map<String, dynamic>> _operatorVehicles = [
    {
      'id': 'ov-1',
      'name': 'Toyota HiAce GL Grandia',
      'plate': 'NDX-4821',
      'type': 'Van',
      'capacity': 14,
      'route': 'Catbalogan - Tacloban',
      'status': 'Active',
    },
    {
      'id': 'ov-2',
      'name': 'Nissan NV350 Urvan',
      'plate': 'EVB-8912',
      'type': 'Van',
      'capacity': 15,
      'route': 'Catbalogan - Calbayog',
      'status': 'Active',
    },
  ];

  final List<Map<String, dynamic>> _schedules = [
    {
      'id': 'sch-1',
      'vehicle': 'Toyota HiAce (NDX-4821)',
      'time': 'Tomorrow • 08:30 AM',
      'route': 'Catbalogan → Tacloban',
      'booked': 9,
      'capacity': 14,
    },
    {
      'id': 'sch-2',
      'vehicle': 'Nissan NV350 (EVB-8912)',
      'time': 'Tomorrow • 01:00 PM',
      'route': 'Catbalogan → Calbayog',
      'booked': 12,
      'capacity': 15,
    },
  ];

  final List<Map<String, dynamic>> _incomingBookings = [
    {
      'id': 'b-201',
      'customer': 'Juan Dela Cruz',
      'ref': 'RG-2026-8472',
      'vehicle': 'Toyota HiAce GL Grandia',
      'route': 'Catbalogan → Tacloban',
      'time': 'Oct 30 • 08:30 AM',
      'passengers': 2,
      'amount': 310.0,
      'status': 'Pending',
      'payment': 'Cash at Terminal',
    },
    {
      'id': 'b-202',
      'customer': 'Maria Santos',
      'ref': 'RG-2026-9014',
      'vehicle': 'Nissan NV350 Urvan',
      'route': 'Catbalogan → Calbayog',
      'time': 'Oct 30 • 01:00 PM',
      'passengers': 1,
      'amount': 150.0,
      'status': 'Confirmed',
      'payment': 'Paid (Cash)',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddVehicleModal() {
    final nameController = TextEditingController();
    final plateController = TextEditingController();
    String type = 'Van';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Register New Vehicle',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Vehicle Model / Name',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: plateController,
              decoration: const InputDecoration(
                labelText: 'Plate / Registration Number',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: type,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                'Van',
                'Bus',
                'Car',
                'Motorcycle',
              ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => type = v!,
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Save Vehicle',
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    _operatorVehicles.add({
                      'id': 'ov-${DateTime.now().millisecond}',
                      'name': nameController.text,
                      'plate': plateController.text.isEmpty
                          ? 'TEMP-01'
                          : plateController.text,
                      'type': type,
                      'capacity': type == 'Bus' ? 45 : (type == 'Van' ? 14 : 4),
                      'route': 'Catbalogan - Tacloban Corridor',
                      'status': 'Active',
                    });
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vehicle added to fleet!')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddScheduleModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Create Trip Departure',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            const Text(
              'Route: Catbalogan City → Tacloban City',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text('Departure: Tomorrow at 03:30 PM'),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Publish Schedule',
              onPressed: () {
                setState(() {
                  _schedules.add({
                    'id': 'sch-${DateTime.now().millisecond}',
                    'vehicle': 'Toyota HiAce (NDX-4821)',
                    'time': 'Tomorrow • 03:30 PM',
                    'route': 'Catbalogan → Tacloban',
                    'booked': 0,
                    'capacity': 14,
                  });
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Departure schedule published!'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Operator Portal'),
        backgroundColor: AppColors.headerNavy,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isApproved ? Icons.verified : Icons.hourglass_top,
              color: AppColors.accentCyan,
            ),
            tooltip: _isApproved ? 'Approved Operator' : 'Pending Approval',
            onPressed: () {
              setState(() => _isApproved = !_isApproved);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentCyan,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.textOnNavySubtle,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined), text: 'Overview'),
            Tab(icon: Icon(Icons.airport_shuttle_outlined), text: 'Fleet'),
            Tab(icon: Icon(Icons.book_online_outlined), text: 'Bookings'),
          ],
        ),
      ),
      body: !_isApproved
          ? _buildPendingApprovalState()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildFleetTab(),
                _buildBookingsTab(),
              ],
            ),
    );
  }

  Widget _buildPendingApprovalState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.hourglass_empty,
              size: 80,
              color: AppColors.headerNavy,
            ),
            const SizedBox(height: 16),
            const Text(
              'Application Under Review',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.headerNavy,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your business operator credentials have been submitted to RideGo administration. You will be able to publish vehicle routes and departures once verified.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textPrimary, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => setState(() => _isApproved = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonTeal,
              ),
              child: const Text(
                'Simulate Admin Approval (Demo)',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        // Metrics Summary Cards
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Active Fleet',
                '${_operatorVehicles.length}',
                Icons.directions_car,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Scheduled Trips',
                '${_schedules.length}',
                Icons.schedule,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Today Bookings',
                '${_incomingBookings.length}',
                Icons.confirmation_number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard('Revenue', '₱ 460', Icons.payments),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Upcoming Departures
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Upcoming Departures',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Trip'),
              onPressed: _showAddScheduleModal,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._schedules.map(
          (s) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.buttonTeal,
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
                        s['route'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        s['time'],
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        s['vehicle'],
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardSubtle,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.buttonTeal),
                  ),
                  child: Text(
                    '${s['booked']}/${s['capacity']} Seats',
                    style: const TextStyle(
                      color: AppColors.buttonTeal,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFleetTab() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.buttonTeal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Vehicle',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        onPressed: _showAddVehicleModal,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(18),
        itemCount: _operatorVehicles.length,
        itemBuilder: (context, index) {
          final v = _operatorVehicles[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.headerNavy,
                  child: const Icon(Icons.airport_shuttle, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Plate: ${v['plate']} • ${v['capacity']} Seats',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        'Route: ${v['route']}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.buttonTeal,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.statusConfirmed.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    v['status'],
                    style: const TextStyle(
                      color: AppColors.statusConfirmed,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookingsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(18),
      itemCount: _incomingBookings.length,
      itemBuilder: (context, index) {
        final b = _incomingBookings[index];
        final isPending = b['status'] == 'Pending';

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    b['ref'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.buttonTeal,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isPending
                          ? AppColors.statusPending.withOpacity(0.15)
                          : AppColors.statusConfirmed.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      b['status'],
                      style: TextStyle(
                        color: isPending
                            ? AppColors.statusPending
                            : AppColors.statusConfirmed,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),
              Text(
                'Passenger: ${b['customer']} (${b['passengers']} seat(s))',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Text(
                'Trip: ${b['route']} • ${b['time']}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                'Vehicle: ${b['vehicle']}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    CurrencyFormatter.format(b['amount']),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.buttonTeal,
                    ),
                  ),
                  if (isPending)
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            setState(() => b['status'] = 'Cancelled');
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.statusCancelled,
                            side: const BorderSide(
                              color: AppColors.statusCancelled,
                            ),
                          ),
                          child: const Text('Reject'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              b['status'] = 'Confirmed';
                              b['payment'] = 'Paid (Cash)';
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonTeal,
                          ),
                          child: const Text(
                            'Confirm',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      b['payment'],
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.statusConfirmed,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.buttonTeal, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.headerNavy,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
