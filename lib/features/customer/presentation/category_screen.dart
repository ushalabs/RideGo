import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/search_field.dart';
import '../../../core/widgets/vehicle_card.dart';

class CategoryScreen extends StatefulWidget {
  final String categoryName;

  const CategoryScreen({super.key, required this.categoryName});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  String _selectedTier = 'All';
  String _searchQuery = '';

  String get _subtitle {
    switch (widget.categoryName.toLowerCase()) {
      case 'van':
        return 'Comfort for groups and family trips';
      case 'bus':
        return 'Affordable and safe for long trips';
      case 'motor':
      case 'motorcycle':
        return 'Fast, flexible and affordable';
      case 'car':
        return 'Private and personalized journey';
      default:
        return 'Reliable transport services';
    }
  }

  IconData get _categoryIcon {
    switch (widget.categoryName.toLowerCase()) {
      case 'van':
        return Icons.airport_shuttle;
      case 'bus':
        return Icons.directions_bus;
      case 'motor':
      case 'motorcycle':
        return Icons.two_wheeler;
      case 'car':
        return Icons.directions_car;
      default:
        return Icons.commute;
    }
  }

  List<Map<String, dynamic>> get _vehicles {
    final cat = widget.categoryName;
    return [
      {
        'id': 'v-1',
        'name': '$cat Express Special',
        'operatorName': 'Van-Vans Samar',
        'category': cat,
        'tier': 'Regular',
        'routeName': 'Calbayog - Catbalogan',
        'fare': 150.0,
        'rating': 5.0,
        'capacity': 14,
      },
      {
        'id': 'v-2',
        'name': '$cat Executive Class',
        'operatorName': 'GrandTours Leyte',
        'category': cat,
        'tier': 'Premium',
        'routeName': 'Catbalogan - Tacloban',
        'fare': 180.0,
        'rating': 5.0,
        'capacity': 14,
      },
      {
        'id': 'v-3',
        'name': '$cat City Shuttle',
        'operatorName': 'City Tours Express',
        'category': cat,
        'tier': 'Regular',
        'routeName': 'Tacloban - Ormoc',
        'fare': 200.0,
        'rating': 4.8,
        'capacity': 16,
      },
      {
        'id': 'v-4',
        'name': '$cat Samar Cruiser',
        'operatorName': 'Duptours Samar',
        'category': cat,
        'tier': 'Premium',
        'routeName': 'Catbalogan - Catarman',
        'fare': 250.0,
        'rating': 5.0,
        'capacity': 12,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _vehicles.where((v) {
      final matchesTier = _selectedTier == 'All' || v['tier'] == _selectedTier;
      final matchesSearch =
          _searchQuery.isEmpty ||
          v['name'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          v['operatorName'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          v['routeName'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
      return matchesTier && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header with category icon, title, subtitle & search field
          AppHeader(
            title: widget.categoryName,
            subtitle: _subtitle,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
              Icon(_categoryIcon, color: AppColors.accentCyan, size: 28),
            ],
            bottomChild: SearchField(
              hintText: 'Search ${widget.categoryName} routes or operators...',
              onChanged: (q) => setState(() => _searchQuery = q),
            ),
          ),

          // Tiers & Results
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              children: [
                // Filter chips: All, Regular, Premium
                Row(
                  children: ['All', 'Regular', 'Premium'].map((tier) {
                    final isSelected = _selectedTier == tier;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(tier),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.buttonTeal
                                : AppColors.inputBorder,
                          ),
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _selectedTier = tier);
                        },
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Vehicle Grid
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
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final v = filtered[index];
                        return VehicleCard(
                          name: v['name'],
                          operatorName: v['operatorName'],
                          routeName: v['routeName'],
                          fare: v['fare'],
                          rating: v['rating'],
                          capacity: v['capacity'],
                          vehicleIcon: _categoryIcon,
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
}
