import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/quotation_provider.dart';
import 'dashboard/dashboard_screen.dart';
import 'quotation/quotation_list_screen.dart';
import 'quotation/create_quotation_screen.dart';
import 'catalog/product_catalog_screen.dart';
import 'more/more_hub_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  final List<Widget> _screens = const [
    DashboardScreen(),
    QuotationListScreen(),
    ProductCatalogScreen(),
    MoreHubScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      // Center Floating Action Button for 1-Tap New Quotation
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        elevation: 6,
        backgroundColor: AppColors.primary500,
        shape: const CircleBorder(),
        tooltip: 'Create New Quotation',
        onPressed: () {
          final quoteProv = context.read<QuotationProvider>();
          quoteProv.initNewQuotation();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateQuotationScreen()),
          );
        },
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.primary400, AppColors.primary600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary500.withOpacity(0.4),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(Icons.add, color: AppColors.slate950, size: 30),
        ),
      ),
      // Modern Curved Bottom Navigation Bar (No Web Sidebar!)
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.slate950,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
          border: Border(
            top: BorderSide(color: AppColors.primary500.withOpacity(0.2), width: 1),
          ),
        ),
        child: BottomAppBar(
          color: AppColors.slate950,
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 0: Dashboard
                _buildNavItem(
                  index: 0,
                  icon: Icons.dashboard_rounded,
                  label: 'Home',
                ),
                // 1: Quotations
                _buildNavItem(
                  index: 1,
                  icon: Icons.receipt_long_rounded,
                  label: 'Quotes',
                ),
                // Center Gap for FAB
                const SizedBox(width: 48),
                // 2: Catalog
                _buildNavItem(
                  index: 2,
                  icon: Icons.inventory_2_rounded,
                  label: 'Catalog',
                ),
                // 3: More
                _buildNavItem(
                  index: 3,
                  icon: Icons.grid_view_rounded,
                  label: 'Menu',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppColors.primary400 : AppColors.slate400;

    return InkWell(
      onTap: () => _onTabTapped(index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 23),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

