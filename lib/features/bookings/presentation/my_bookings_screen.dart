import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_header.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  String _selectedTab = 'Upcoming';

  final List<Map<String, dynamic>> _allBookings = [
    {
      'id': 'b-101',
      'reference': 'RG-2026-8472',
      'operatorName': 'Van-Vans Samar',
      'vehicleName': 'Toyota HiAce GL Grandia',
      'category': 'Van',
      'origin': 'Catbalogan City',
      'destination': 'Tacloban City',
      'departureDate': 'Oct 30, 2026 • 08:30 AM',
      'passengers': 2,
      'fare': 310.0,
      'status': 'Upcoming',
      'paymentStatus': 'Cash at Terminal',
    },
    {
      'id': 'b-102',
      'reference': 'RG-2026-8190',
      'operatorName': 'GrandTours Leyte',
      'vehicleName': 'Nissan NV350 Premium',
      'category': 'Van',
      'origin': 'Tacloban City',
      'destination': 'Calbayog City',
      'departureDate': 'Oct 31, 2026 • 01:00 PM',
      'passengers': 1,
      'fare': 190.0,
      'status': 'Upcoming',
      'paymentStatus': 'Cash at Terminal',
    },
    {
      'id': 'b-103',
      'reference': 'RG-2026-7241',
      'operatorName': 'City Tours Express',
      'vehicleName': 'Hino Grand Express Bus',
      'category': 'Bus',
      'origin': 'Catbalogan City',
      'destination': 'Tacloban City',
      'departureDate': 'Oct 24, 2026 • 06:00 AM',
      'passengers': 1,
      'fare': 200.0,
      'status': 'Completed',
      'paymentStatus': 'Paid (Cash)',
    },
    {
      'id': 'b-104',
      'reference': 'RG-2026-6812',
      'operatorName': 'Duptours Samar',
      'vehicleName': 'Toyota Commuter Van',
      'category': 'Van',
      'origin': 'Catbalogan City',
      'destination': 'Catarman',
      'departureDate': 'Oct 18, 2026 • 10:30 AM',
      'passengers': 1,
      'fare': 250.0,
      'status': 'Cancelled',
      'paymentStatus': 'Cancelled',
    },
  ];

  void _cancelBooking(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: const Text(
          'Are you sure you want to cancel this booking? This will release your seat reservation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No, Keep Booking'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusCancelled,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                final idx = _allBookings.indexWhere((b) => b['id'] == id);
                if (idx != -1) {
                  _allBookings[idx]['status'] = 'Cancelled';
                  _allBookings[idx]['paymentStatus'] = 'Cancelled';
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Booking cancelled successfully.'),
                  backgroundColor: AppColors.statusCancelled,
                ),
              );
            },
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _allBookings
        .where((b) => b['status'] == _selectedTab)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Navy Header matching Figma
          AppHeader(
            title: 'My Bookings',
            subtitle: 'Manage your trips',
            actions: [
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: () => context.push('/booking/new'),
              ),
            ],
            bottomChild: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: ['Upcoming', 'Completed', 'Cancelled'].map((tab) {
                final isSelected = _selectedTab == tab;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = tab),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.buttonTeal
                            : Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.buttonTeal
                              : Colors.white24,
                        ),
                      ),
                      child: Text(
                        tab,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Bookings List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.confirmation_number_outlined,
                          size: 64,
                          color: AppColors.headerNavy,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No $_selectedTab Bookings',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.headerNavy,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.push('/home'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonTeal,
                          ),
                          child: const Text(
                            'Book a Ride',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(18),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final b = filtered[index];
                      return _buildBookingCard(b);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> b) {
    final statusColor = b['status'] == 'Upcoming'
        ? AppColors.statusConfirmed
        : b['status'] == 'Completed'
        ? AppColors.statusCompleted
        : AppColors.statusCancelled;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Ref & Status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  b['reference'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.buttonTeal,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    b['status'],
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 18),

            // Operator and Vehicle
            Text(
              b['operatorName'],
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            Text(
              b['vehicleName'],
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),

            // Route & Departure
            Row(
              children: [
                const Icon(
                  Icons.trip_origin,
                  size: 14,
                  color: AppColors.buttonTeal,
                ),
                const SizedBox(width: 6),
                Text(
                  b['origin'],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_forward,
                  size: 12,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.location_on,
                  size: 14,
                  color: AppColors.statusCancelled,
                ),
                const SizedBox(width: 4),
                Text(
                  b['destination'],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 14,
                  color: AppColors.headerNavy,
                ),
                const SizedBox(width: 6),
                Text(
                  b['departureDate'],
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Fare and actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CurrencyFormatter.format(b['fare']),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.buttonTeal,
                      ),
                    ),
                    Text(
                      '${b['passengers']} Passenger(s) • ${b['paymentStatus']}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (b['status'] == 'Upcoming')
                  OutlinedButton(
                    onPressed: () => _cancelBooking(b['id']),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.statusCancelled,
                      side: const BorderSide(color: AppColors.statusCancelled),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
