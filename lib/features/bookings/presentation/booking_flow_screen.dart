import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/custom_button.dart';

class BookingFlowScreen extends StatefulWidget {
  final String? vehicleId;
  final String? operatorName;
  final double? initialFare;
  final String? initialRoute;

  const BookingFlowScreen({
    super.key,
    this.vehicleId,
    this.operatorName,
    this.initialFare,
    this.initialRoute,
  });

  @override
  State<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends State<BookingFlowScreen> {
  String _pickupLocation = 'Catbalogan City';
  String _dropoffLocation = 'Tacloban City';
  DateTime _travelDate = DateTime.now().add(const Duration(days: 1));
  String _selectedDeparture = '08:30 AM';
  int _passengers = 1;
  bool _isLoading = false;

  final List<String> _stops = [
    'Catbalogan City',
    'Jiabong',
    'Motiong',
    'Paranas (Wright)',
    'San Jorge',
    'Gandara',
    'Calbayog City',
    'Pinabacdao',
    'Calbiga',
    'Villareal',
    'Santa Rita',
    'Basey',
    'Marabut',
    'San Juanico Bridge',
    'Tacloban City',
  ];

  final List<String> _departureTimes = [
    '06:00 AM',
    '08:30 AM',
    '10:30 AM',
    '01:00 PM',
    '03:30 PM',
    '05:30 PM',
  ];

  double get _baseFare => widget.initialFare ?? 150.0;
  double get _terminalFee => 10.0;
  double get _totalFare => (_baseFare * _passengers) + _terminalFee;

  void _confirmBooking() {
    if (_pickupLocation == _dropoffLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pickup and Drop-off locations cannot be the same!'),
          backgroundColor: AppColors.statusCancelled,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() => _isLoading = false);
        final bookingRef =
            'RG-2026-${(1000 + DateTime.now().millisecond * 7).toString().padLeft(4, '0')}';
        _showSuccessDialog(bookingRef);
      }
    });
  }

  void _showSuccessDialog(String reference) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(
              Icons.check_circle,
              color: AppColors.statusConfirmed,
              size: 28,
            ),
            SizedBox(width: 8),
            Text(
              'Booking Confirmed!',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your trip reservation has been recorded.'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardSubtle,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Booking Reference:',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    reference,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppColors.buttonTeal,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const Divider(height: 16),
                  Text(
                    'Route: $_pickupLocation → $_dropoffLocation',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Departure: ${DateFormat('MMM d, yyyy').format(_travelDate)} • $_selectedDeparture',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    'Passengers: $_passengers',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    'Total: ${CurrencyFormatter.format(_totalFare)} (Cash at Terminal)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.buttonTeal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonTeal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/bookings');
            },
            child: const Text(
              'View My Bookings',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Book Your Trip'),
        backgroundColor: AppColors.headerNavy,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Operator / Vehicle info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.headerNavy,
                    child: const Icon(
                      Icons.airport_shuttle,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.operatorName ?? 'Van-Vans Samar',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Route: ${widget.initialRoute ?? 'Samar - Leyte Express'}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Pickup & Dropoff selection
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Stops',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  // Pickup Dropdown
                  DropdownButtonFormField<String>(
                    value: _pickupLocation,
                    decoration: const InputDecoration(
                      labelText: 'Pickup Location',
                      prefixIcon: Icon(
                        Icons.trip_origin,
                        color: AppColors.buttonTeal,
                        size: 20,
                      ),
                    ),
                    items: _stops
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setState(() => _pickupLocation = v!),
                  ),
                  const SizedBox(height: 14),
                  // Dropoff Dropdown
                  DropdownButtonFormField<String>(
                    value: _dropoffLocation,
                    decoration: const InputDecoration(
                      labelText: 'Drop-off Destination',
                      prefixIcon: Icon(
                        Icons.location_on,
                        color: AppColors.statusCancelled,
                        size: 20,
                      ),
                    ),
                    items: _stops
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setState(() => _dropoffLocation = v!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Date & Departure Time
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Travel Date & Time',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  // Date Picker button
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _travelDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (picked != null) {
                        setState(() => _travelDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cardSubtle,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.inputBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_month,
                            color: AppColors.buttonTeal,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            DateFormat('EEEE, MMMM d, yyyy')
                                .format(_travelDate),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.edit,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Available Departure Slot:',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _departureTimes.map((t) {
                      final isSelected = _selectedDeparture == t;
                      return ChoiceChip(
                        label: Text(t),
                        selected: isSelected,
                        selectedColor: AppColors.buttonTeal,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.headerNavy,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        backgroundColor: Colors.white,
                        onSelected: (val) {
                          if (val) setState(() => _selectedDeparture = t);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Passengers & Fare Breakdown
            Container(
              padding: const EdgeInsets.all(16),
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
                        'Passenger Count',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: AppColors.buttonTeal,
                            ),
                            onPressed: _passengers > 1
                                ? () => setState(() => _passengers--)
                                : null,
                          ),
                          Text(
                            '$_passengers',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle_outline,
                              color: AppColors.buttonTeal,
                            ),
                            onPressed: _passengers < 6
                                ? () => setState(() => _passengers++)
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  const Text(
                    'Fare Breakdown',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Base Fare (x$_passengers)',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(_baseFare * _passengers),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Terminal & Service Fee',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(_terminalFee),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Fare',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(_totalFare),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.buttonTeal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.cardSubtle,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.headerNavy,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Payment Mode: Cash / Pay-at-Terminal upon vehicle boarding.',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.headerNavy,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Confirm Button
            CustomButton(
              text: 'CONFIRM RESERVATION',
              isLoading: _isLoading,
              onPressed: _confirmBooking,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
