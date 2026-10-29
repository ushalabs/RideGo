import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/search_field.dart';
import '../data/search_repository.dart';
import '../models/search_result_item.dart';

class SearchResultsScreen extends StatefulWidget {
  final String? initialQuery;
  final String? initialCategory;

  const SearchResultsScreen({
    super.key,
    this.initialQuery,
    this.initialCategory,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final _searchRepo = SearchRepository();
  late TextEditingController _searchController;
  String _selectedCategory = 'All';
  String _sortBy = 'departure_asc';
  bool _availableOnly = true;
  bool _isLoading = false;
  List<SearchResultItem> _results = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    _selectedCategory = widget.initialCategory ?? 'All';
    _performSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    setState(() => _isLoading = true);
    final items = await _searchRepo.searchTrips(
      origin: _searchController.text.trim(),
      category: _selectedCategory,
      availableOnly: _availableOnly,
      sortBy: _sortBy,
    );
    if (mounted) {
      setState(() {
        _results = items;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AppHeader(
            title: 'Search Results',
            subtitle: 'Find rides across Samar & Leyte',
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => context.pop(),
            ),
            bottomChild: SearchField(
              controller: _searchController,
              hintText: 'Search city, terminal or vehicle...',
              onChanged: (_) => _performSearch(),
            ),
          ),

          // Filters Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...['All', 'Van', 'Bus', 'Motor', 'Car'].map((cat) {
                    final isSel = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSel,
                        selectedColor: AppColors.buttonTeal,
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : AppColors.headerNavy,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        backgroundColor: Colors.white,
                        onSelected: (val) {
                          if (val) {
                            setState(() => _selectedCategory = cat);
                            _performSearch();
                          }
                        },
                      ),
                    );
                  }),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Available Only'),
                    selected: _availableOnly,
                    selectedColor: AppColors.statusConfirmed.withOpacity(0.2),
                    checkmarkColor: AppColors.statusConfirmed,
                    labelStyle: TextStyle(
                      color: _availableOnly
                          ? AppColors.statusConfirmed
                          : AppColors.headerNavy,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    backgroundColor: Colors.white,
                    onSelected: (val) {
                      setState(() => _availableOnly = val);
                      _performSearch();
                    },
                  ),
                  const SizedBox(width: 8),
                  // Sort dropdown chip
                  PopupMenuButton<String>(
                    onSelected: (val) {
                      setState(() => _sortBy = val);
                      _performSearch();
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'departure_asc',
                        child: Text('Earliest Departure'),
                      ),
                      const PopupMenuItem(
                        value: 'price_asc',
                        child: Text('Price: Low to High'),
                      ),
                      const PopupMenuItem(
                        value: 'price_desc',
                        child: Text('Price: High to Low'),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.inputBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.sort,
                            size: 16,
                            color: AppColors.buttonTeal,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _sortBy == 'price_asc'
                                ? 'Price: Low-High'
                                : (_sortBy == 'price_desc'
                                      ? 'Price: High-Low'
                                      : 'Earliest'),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.headerNavy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Results List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.headerNavy,
                      ),
                    ),
                  )
                : _results.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.search_off,
                          size: 56,
                          color: AppColors.headerNavy,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No matching trips or vehicles found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.headerNavy,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final item = _results[index];
                      return _buildResultCard(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(SearchResultItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.operatorName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.buttonTeal.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  item.category,
                  style: const TextStyle(
                    color: AppColors.buttonTeal,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.vehicleName,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.place_outlined,
                size: 14,
                color: AppColors.buttonTeal,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.routeName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.schedule, size: 14, color: AppColors.headerNavy),
              const SizedBox(width: 4),
              Text(
                DateFormatter.formatDateTime(item.departureTime),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '${item.availableCapacity}/${item.totalCapacity} seats left',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.statusConfirmed,
                ),
              ),
            ],
          ),
          const Divider(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                CurrencyFormatter.format(item.fare),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.buttonTeal,
                ),
              ),
              ElevatedButton(
                onPressed: () => context.push(
                  '/booking/new?vehicleId=${item.vehicleId}&operator=${item.operatorName}&fare=${item.fare}&route=${item.routeName}',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonTeal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Select & Book',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
