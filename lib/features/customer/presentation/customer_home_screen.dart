import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/category_pill.dart';
import '../../../core/widgets/search_field.dart';
import '../../../core/widgets/vehicle_card.dart';
import '../../auth/presentation/auth_providers.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  String _selectedCategory = 'Van';

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Van', 'icon': Icons.airport_shuttle},
    {'name': 'Bus', 'icon': Icons.directions_bus},
    {'name': 'Motor', 'icon': Icons.two_wheeler},
    {'name': 'Car', 'icon': Icons.directions_car},
  ];

  final List<Map<String, dynamic>> _featuredVehicles = [
    {
      'id': 'v-001',
      'name': 'Toyota HiAce GL Grandia',
      'operatorName': 'Van-Vans',
      'category': 'Van',
      'routeName': 'Calbayog - Catbalogan',
      'fare': 150.0,
      'rating': 5.0,
      'capacity': 14,
      'icon': Icons.airport_shuttle,
    },
    {
      'id': 'v-002',
      'name': 'Nissan NV350 Premium',
      'operatorName': 'GrandTours',
      'category': 'Van',
      'routeName': 'Calbayog - Tacloban',
      'fare': 180.0,
      'rating': 5.0,
      'capacity': 14,
      'icon': Icons.airport_shuttle,
    },
    {
      'id': 'v-003',
      'name': 'Hino Grand Express Bus',
      'operatorName': 'City Tours Express',
      'category': 'Bus',
      'routeName': 'Catbalogan - Tacloban',
      'fare': 200.0,
      'rating': 5.0,
      'capacity': 45,
      'icon': Icons.directions_bus,
    },
    {
      'id': 'v-004',
      'name': 'Toyota Commuter Van',
      'operatorName': 'Duptours Samar',
      'category': 'Van',
      'routeName': 'Catbalogan - Catarman',
      'fare': 250.0,
      'rating': 5.0,
      'capacity': 15,
      'icon': Icons.airport_shuttle,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(currentUserProfileProvider);
    final displayName =
        (userProfile?.fullName != null &&
            userProfile!.fullName.trim().isNotEmpty)
        ? userProfile.fullName.trim().split(' ').first
        : 'Traveler';

    final filteredVehicles = _featuredVehicles.where((v) {
      return _selectedCategory == 'All' || v['category'] == _selectedCategory;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Navy Header with dynamic greeting
          AppHeader(
            title: 'Hello, $displayName',
            subtitle: 'Where are you headed today',
            leading: CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.buttonTeal,
              child: const Icon(Icons.person, color: Colors.white, size: 26),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.white),
                onPressed: () => context.push('/notifications'),
              ),
            ],
            bottomChild: SearchField(
              hintText: 'Search for destination, city or veh...',
              readOnly: true,
              onTap: () => context.push('/search'),
              onFilterTap: () => _showFilterModal(context),
            ),
          ),

          // Scrollable Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              children: [
                // Category Pills Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat['name'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: CategoryPill(
                          label: cat['name'] as String,
                          icon: cat['icon'] as IconData,
                          isSelected: isSelected,
                          onTap: () {
                            setState(
                              () => _selectedCategory = cat['name'] as String,
                            );
                            context.push('/category/${cat['name']}');
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 18),

                // Featured Booking Banner
                _buildFeaturedBanner(context),
                const SizedBox(height: 22),

                // Section Header: Available Trips
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Available Trips & Vehicles',
                      style: AppTextStyles.sectionTitle,
                    ),
                    TextButton(
                      onPressed: () =>
                          context.push('/category/$_selectedCategory'),
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          color: AppColors.headerNavy,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Vehicle Grid / List
                if (filteredVehicles.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 48,
                          color: AppColors.headerNavy,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No vehicles found for $_selectedCategory',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 0.76,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                        ),
                        itemCount: filteredVehicles.length,
                        itemBuilder: (context, index) {
                          final v = filteredVehicles[index];
                          return VehicleCard(
                            name: v['name'],
                            operatorName: v['operatorName'],
                            routeName: v['routeName'],
                            fare: v['fare'],
                            rating: v['rating'],
                            capacity: v['capacity'],
                            vehicleIcon: v['icon'],
                            onTap: () => context.push('/vehicle/${v['id']}'),
                            onBook: () => context.push(
                              '/booking/new?vehicleId=${v['id']}&operator=${v['operatorName']}&fare=${v['fare']}&route=${v['routeName']}',
                            ),
                          );
                        },
                      );
                    },
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.headerNavy, AppColors.buttonTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.headerNavy.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentCyan.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Samar & Leyte Corridor',
                    style: TextStyle(
                      color: AppColors.accentCyan,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Book a Vehicle Today',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Guaranteed seats • Catbalogan, Tacloban & Calbayog',
                  style: TextStyle(
                    color: AppColors.textOnNavySubtle,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => context.push('/booking/new'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.buttonTeal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Book Now',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.directions_bus_filled_rounded,
            size: 72,
            color: Colors.white70,
          ),
        ],
      ),
    );
  }

  void _showFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Vehicles & Trips',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: ['All', 'Van', 'Bus', 'Motor', 'Car'].map((cat) {
                return ChoiceChip(
                  label: Text(cat),
                  selected: _selectedCategory == cat,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedCategory = cat);
                      Navigator.pop(ctx);
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
