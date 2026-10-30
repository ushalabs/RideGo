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

  final List<String> _samarLeyteTerminals = [
    'Catbalogan Central Terminal',
    'Tacloban Abucay Terminal',
    'Calbayog Central Terminal',
    'Basey Terminal',
    'Jiabong Station',
    'Pinabacdao Terminal',
    'Paranas (Wright) Terminal',
    'Calbiga Town Stop',
    'Gandara Terminal',
    'Santa Rita Junction',
  ];

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
    final priceController = TextEditingController(text: '150');
    final capacityController = TextEditingController(text: '14');
    VehicleType type = VehicleType.van;
    String selectedTerminal = _samarLeyteTerminals.first;

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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Register New Vehicle',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle Model / Name',
                    hintText: 'e.g. Toyota HiAce Commuter',
                    prefixIcon: Icon(Icons.airport_shuttle),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: plateController,
                  decoration: const InputDecoration(
                    labelText: 'Plate / Registration Number',
                    hintText: 'e.g. NDX-4821',
                    prefixIcon: Icon(Icons.tag),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<VehicleType>(
                        value: type,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                        items: VehicleType.values
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(c.displayName),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setModalState(() {
                              type = v;
                              if (v == VehicleType.bus) {
                                capacityController.text = '45';
                                priceController.text = '120';
                              } else if (v == VehicleType.van) {
                                capacityController.text = '14';
                                priceController.text = '150';
                              } else if (v == VehicleType.motorcycle) {
                                capacityController.text = '1';
                                priceController.text = '60';
                              } else {
                                capacityController.text = '4';
                                priceController.text = '250';
                              }
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: capacityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Seating Capacity',
                          prefixIcon: Icon(Icons.airline_seat_recline_normal),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedTerminal,
                  decoration: const InputDecoration(
                    labelText: 'Base Terminal / Location',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  items: _samarLeyteTerminals
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setModalState(() => selectedTerminal = v);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Standard Base Price / Fare (₱)',
                    hintText: 'e.g. 150.00',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                ),
                const SizedBox(height: 20),
                CustomButton(
                  text: 'Save Vehicle to Fleet',
                  onPressed: () async {
                    if (nameController.text.isNotEmpty) {
                      final name = nameController.text.trim();
                      final plate = plateController.text.isEmpty
                          ? 'TEMP-${DateTime.now().millisecond}'
                          : plateController.text.trim();
                      final cap = int.tryParse(capacityController.text) ?? 14;
                      final price =
                          double.tryParse(priceController.text) ?? 150.0;
                      Navigator.pop(ctx);

                      await _vehicleRepo.addVehicle(
                        operatorId: 'mock-op-1',
                        name: name,
                        category: type,
                        plateNumber: plate,
                        capacity: cap,
                        baseLocation: selectedTerminal,
                        basePrice: price,
                      );
                      await _loadAllOperatorData();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$name added to fleet at ₱$price!'),
                            backgroundColor: AppColors.statusConfirmed,
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
      ),
    );
  }

  void _showEditVehicleLocationModal(VehicleModel vehicle) {
    String chosenLocation = _samarLeyteTerminals.contains(vehicle.baseLocation)
        ? vehicle.baseLocation
        : _samarLeyteTerminals.first;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (sbContext, setModalState) => Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Manage Location: ${vehicle.name}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Current Terminal: ${vehicle.baseLocation}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: chosenLocation,
                decoration: const InputDecoration(
                  labelText: 'Select New Operational Terminal',
                  prefixIcon: Icon(Icons.location_on),
                ),
                items: _samarLeyteTerminals
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setModalState(() => chosenLocation = v);
                },
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: 'Update Location',
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _vehicleRepo.updateVehicleLocation(
                    vehicle.id,
                    chosenLocation,
                  );
                  await _loadAllOperatorData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${vehicle.name} relocated to $chosenLocation',
                        ),
                        backgroundColor: AppColors.statusConfirmed,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditVehiclePriceModal(VehicleModel vehicle) {
    final fareController = TextEditingController(
      text: vehicle.basePrice.toStringAsFixed(0),
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 22,
          right: 22,
          top: 22,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 22,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Price Management: ${vehicle.name}',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Plate: ${vehicle.plateNumber} • ${vehicle.category.displayName}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: fareController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Standard Base Price / Fare (₱)',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Save Updated Price',
              onPressed: () async {
                final newPrice = double.tryParse(fareController.text);
                if (newPrice != null && newPrice > 0) {
                  Navigator.pop(ctx);
                  await _vehicleRepo.updateVehiclePrice(vehicle.id, newPrice);
                  await _loadAllOperatorData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Price for ${vehicle.name} updated to ₱${newPrice.toStringAsFixed(2)}',
                        ),
                        backgroundColor: AppColors.statusConfirmed,
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

  void _showEditScheduleFareModal(ScheduleModel schedule) {
    final fareController = TextEditingController(
      text: schedule.fare.toStringAsFixed(0),
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 22,
          right: 22,
          top: 22,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 22,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Trip Price Management: ${schedule.routeName}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Vehicle: ${schedule.vehicleName}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: fareController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Seat Fare / Passenger Price (₱)',
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Update Departure Fare',
              onPressed: () async {
                final newFare = double.tryParse(fareController.text);
                if (newFare != null && newFare > 0) {
                  Navigator.pop(ctx);
                  await _scheduleRepo.updateScheduleFare(schedule.id, newFare);
                  await _loadAllOperatorData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Trip fare updated to ₱${newFare.toStringAsFixed(2)}',
                        ),
                        backgroundColor: AppColors.statusConfirmed,
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

  void _showAddScheduleModal() {
    String origin = 'Catbalogan Central Terminal';
    String destination = 'Tacloban Abucay Terminal';
    String selectedVehicleId = _vehicles.isNotEmpty
        ? _vehicles.first.id
        : 'v-local-1';
    final fareController = TextEditingController(text: '150');
    int hoursFromNow = 3;

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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Create Trip & Manage Price',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_vehicles.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: selectedVehicleId,
                    decoration: const InputDecoration(
                      labelText: 'Select Vehicle from Fleet',
                      prefixIcon: Icon(Icons.airport_shuttle),
                    ),
                    items: _vehicles
                        .map(
                          (v) => DropdownMenuItem(
                            value: v.id,
                            child: Text(
                              '${v.name} (${v.plateNumber}) • ${v.passengerCapacity} Seats',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setModalState(() {
                          selectedVehicleId = v;
                          final chosenV = _vehicles.firstWhere(
                            (e) => e.id == v,
                          );
                          fareController.text = chosenV.basePrice
                              .toStringAsFixed(0);
                        });
                      }
                    },
                  ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: origin,
                  decoration: const InputDecoration(
                    labelText: 'Departure Location / Terminal',
                    prefixIcon: Icon(Icons.trip_origin),
                  ),
                  items: _samarLeyteTerminals
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setModalState(() => origin = v);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: destination,
                  decoration: const InputDecoration(
                    labelText: 'Destination Location / Terminal',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  items: _samarLeyteTerminals
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setModalState(() => destination = v);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: hoursFromNow,
                        decoration: const InputDecoration(
                          labelText: 'Departure Window',
                          prefixIcon: Icon(Icons.schedule),
                        ),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('In 1 hour')),
                          DropdownMenuItem(value: 3, child: Text('In 3 hours')),
                          DropdownMenuItem(value: 6, child: Text('In 6 hours')),
                          DropdownMenuItem(
                            value: 12,
                            child: Text('In 12 hours'),
                          ),
                          DropdownMenuItem(value: 24, child: Text('Tomorrow')),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setModalState(() => hoursFromNow = v);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: fareController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Fare Price (₱)',
                          prefixIcon: Icon(Icons.payments_outlined),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                CustomButton(
                  text: 'Publish Departure Schedule',
                  onPressed: () async {
                    final vehicle = _vehicles.firstWhere(
                      (v) => v.id == selectedVehicleId,
                      orElse: () => _vehicles.isNotEmpty
                          ? _vehicles.first
                          : VehicleModel(
                              id: 'v-local-1',
                              operatorId: 'mock-op-1',
                              name: 'Toyota HiAce GL Grandia',
                              category: VehicleType.van,
                              plateNumber: 'NDX-4821',
                              passengerCapacity: 14,
                              createdAt: DateTime.now(),
                            ),
                    );
                    final fare = double.tryParse(fareController.text) ?? 150.0;
                    final depTime = DateTime.now().add(
                      Duration(hours: hoursFromNow),
                    );
                    final routeName =
                        '${origin.replaceAll(" Terminal", "")} → ${destination.replaceAll(" Terminal", "")}';
                    Navigator.pop(ctx);

                    try {
                      await _scheduleRepo.createSchedule(
                        operatorId: 'mock-op-1',
                        operatorName: 'Van-Vans Samar',
                        vehicleId: vehicle.id,
                        vehicleName: vehicle.name,
                        routeVariantId:
                            'rv-custom-${DateTime.now().millisecondsSinceEpoch}',
                        routeName: routeName,
                        departureTime: depTime,
                        capacity: vehicle.passengerCapacity,
                        fare: fare,
                      );
                      await _loadAllOperatorData();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Published: $routeName at ₱${fare.toStringAsFixed(2)}!',
                            ),
                            backgroundColor: AppColors.statusConfirmed,
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Operator & Fleet Portal'),
        backgroundColor: AppColors.headerNavy,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.go('/login'),
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
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 16, color: Colors.white),
              label: const Text(
                'Add Trip',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonTeal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
              ),
              onPressed: _showAddScheduleModal,
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._schedules.map(
          (s) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
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
                              fontSize: 14,
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₱${s.fare.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.headerNavy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.cardSubtle,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.buttonTeal),
                          ),
                          child: Text(
                            '${s.availableCapacity}/${s.totalCapacity} Seats',
                            style: const TextStyle(
                              color: AppColors.buttonTeal,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.edit, size: 14),
                      label: const Text('Manage Trip Price'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.buttonTeal,
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () => _showEditScheduleFareModal(s),
                    ),
                  ],
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.headerNavy,
                      child: Icon(
                        v.category == VehicleType.bus
                            ? Icons.directions_bus
                            : (v.category == VehicleType.motorcycle
                                  ? Icons.two_wheeler
                                  : Icons.airport_shuttle),
                        color: Colors.white,
                      ),
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
                              fontSize: 15,
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
                              fontWeight: FontWeight.w600,
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
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),

                // Location and Price Management Tags
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        v.baseLocation,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      'Base Fare: ₱${v.basePrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.headerNavy,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Operator Action Controls for Location & Price Management
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.edit_location_alt, size: 14),
                      label: const Text('Location'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.headerNavy,
                        side: const BorderSide(color: AppColors.headerNavy),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () => _showEditVehicleLocationModal(v),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(
                        Icons.payments,
                        size: 14,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Manage Price',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonTeal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                      onPressed: () => _showEditVehiclePriceModal(v),
                    ),
                  ],
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
