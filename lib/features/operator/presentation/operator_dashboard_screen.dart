import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/custom_button.dart';
import '../../bookings/data/booking_repository.dart';
import '../../bookings/models/booking_model.dart';
import '../../schedules/data/schedule_repository.dart';
import '../../schedules/models/schedule_model.dart';
import '../../vehicles/data/vehicle_repository.dart';
import '../../vehicles/models/vehicle_model.dart';

class OperatorDashboardScreen extends StatefulWidget {
  const OperatorDashboardScreen({super.key});

  @override
  State<OperatorDashboardScreen> createState() =>
      _OperatorDashboardScreenState();
}

class _OperatorDashboardScreenState extends State<OperatorDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _vehicleRepo = VehicleRepository();
  final _scheduleRepo = ScheduleRepository();
  final _bookingRepo = BookingRepository();

  bool _isApproved = true;
  bool _isLoading = true;

  List<VehicleModel> _vehicles = [];
  List<ScheduleModel> _schedules = [];
  List<BookingModel> _bookings = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllOperatorData();
    _bookingRepo.subscribeToRealtimeBookings(() {
      if (mounted) _loadAllOperatorData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bookingRepo.unsubscribeRealtime();
    super.dispose();
  }

  Future<void> _loadAllOperatorData() async {
    final vList = await _vehicleRepo.getVehiclesByOperator('mock-op-1');
    final sList = await _scheduleRepo.getSchedules();
    final bList = await _bookingRepo.getBookings();

    if (mounted) {
      setState(() {
        _vehicles = vList;
        _schedules = sList;
        _bookings = bList;
        _isLoading = false;
      });
    }
  }

  double get _totalCollectedRevenue {
    return _bookings
        .where((b) => b.paymentStatus == 'Paid (Cash)')
        .fold(0.0, (sum, b) => sum + b.totalFare);
  }

  void _showAddVehicleModal() {
    final nameController = TextEditingController();
    final plateController = TextEditingController();
    VehicleType type = VehicleType.van;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (sbContext, setModalState) => Padding(
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
              DropdownButtonFormField<VehicleType>(
                value: type,
                decoration: const InputDecoration(labelText: 'Category'),
                items: VehicleType.values
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(c.displayName),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setModalState(() => type = v!),
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: 'Save Vehicle',
                onPressed: () async {
                  if (nameController.text.isNotEmpty) {
                    final name = nameController.text.trim();
                    final plate = plateController.text.isEmpty
                        ? 'TEMP-${DateTime.now().millisecond}'
                        : plateController.text.trim();
                    final cap = type == VehicleType.bus
                        ? 45
                        : (type == VehicleType.van ? 14 : 4);
                    Navigator.pop(ctx);

                    await _vehicleRepo.addVehicle(
                      operatorId: 'mock-op-1',
                      name: name,
                      category: type,
                      plateNumber: plate,
                      capacity: cap,
                    );
                    await _loadAllOperatorData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vehicle added to fleet!'),
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
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
            const Text('Departure: Today at 04:30 PM (Asia/Manila)'),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Publish Departure Schedule',
              onPressed: () async {
                final vId = _vehicles.isNotEmpty
                    ? _vehicles.first.id
                    : 'v-local-1';
                final vName = _vehicles.isNotEmpty
                    ? _vehicles.first.name
                    : 'Toyota HiAce GL Grandia';
                Navigator.pop(ctx);

                try {
                  await _scheduleRepo.createSchedule(
                    operatorId: 'mock-op-1',
                    operatorName: 'Van-Vans Samar',
                    vehicleId: vId,
                    vehicleName: vName,
                    routeVariantId: 'rv-sb-main',
                    routeName: 'Catbalogan to Tacloban Express',
                    departureTime: DateTime.now().add(const Duration(hours: 4)),
                    capacity: 14,
                    fare: 150.0,
                  );
                  await _loadAllOperatorData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Departure schedule published!'),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: AppColors.statusCancelled,
                      ),
                    );
                  }
                }
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
          : _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.headerNavy),
              ),
            )
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
                '${_vehicles.length}',
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
                'Bookings',
                '${_bookings.length}',
                Icons.confirmation_number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Collected Cash',
                CurrencyFormatter.format(_totalCollectedRevenue),
                Icons.payments,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

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
                        s.routeName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        DateFormatter.formatDateTime(s.departureTime),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        s.vehicleName,
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
                    '${s.availableCapacity}/${s.totalCapacity} Seats',
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
        itemCount: _vehicles.length,
        itemBuilder: (context, index) {
          final v = _vehicles[index];
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
                        v.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Plate: ${v.plateNumber} • ${v.passengerCapacity} Seats',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        'Category: ${v.category.displayName}',
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
                    v.status,
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
      itemCount: _bookings.length,
      itemBuilder: (context, index) {
        final b = _bookings[index];
        final isPending = b.status == BookingStatus.pending;
        final isPaid = b.paymentStatus == 'Paid (Cash)';

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
                    b.reference,
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
                      color:
                          (b.status == BookingStatus.confirmed
                                  ? AppColors.statusConfirmed
                                  : (b.status == BookingStatus.cancelled
                                        ? AppColors.statusCancelled
                                        : AppColors.statusPending))
                              .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      b.status.displayName,
                      style: TextStyle(
                        color: b.status == BookingStatus.confirmed
                            ? AppColors.statusConfirmed
                            : (b.status == BookingStatus.cancelled
                                  ? AppColors.statusCancelled
                                  : AppColors.statusPending),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),
              Text(
                'Passenger Seats: ${b.passengerCount} seat(s)',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Text(
                'Trip: ${b.pickupLocation} → ${b.dropoffLocation}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                'Time: ${DateFormatter.formatDateTime(b.departureTime)}',
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
                    CurrencyFormatter.format(b.totalFare),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.buttonTeal,
                    ),
                  ),
                  if (isPending || !isPaid)
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () async {
                            await _bookingRepo.cancelBooking(
                              b.id,
                              reason: 'Operator rejected reservation',
                            );
                            await _loadAllOperatorData();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.statusCancelled,
                            side: const BorderSide(
                              color: AppColors.statusCancelled,
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            await _bookingRepo.confirmPayment(
                              b.id,
                              'mock-operator-staff',
                            );
                            await _loadAllOperatorData();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonTeal,
                          ),
                          child: const Text(
                            'Confirm Cash',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      b.paymentStatus,
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
