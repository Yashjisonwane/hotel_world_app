import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_colors.dart';
import '../constants/api_constants.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/quotation/quotation_list_screen.dart';
import '../screens/quotation/create_quotation_screen.dart';
import '../screens/catalog/product_catalog_screen.dart';
import '../screens/customers/customers_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/users/users_management_screen.dart';
import '../screens/auth/login_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final settingsProv = context.watch<SettingsProvider>();
    final user = auth.currentUser;
    final backendUrl = settingsProv.backendUrl;

    return Drawer(
      backgroundColor: AppColors.white,
      child: Column(
        children: [
          // User / Brand Header
          Container(
            padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
            color: AppColors.slate950,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primary500,
                  backgroundImage: (user?.avatar != null && user!.avatar!.isNotEmpty)
                      ? CachedNetworkImageProvider(ApiConstants.resolveImageUrl(user.avatar, backendUrl))
                      : null,
                  child: (user?.avatar == null || user!.avatar!.isEmpty)
                      ? Text(
                          user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'H',
                          style: const TextStyle(
                            color: AppColors.slate950,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: pwCrossAxisAlignment(CrossAxisAlignment.start),
                    children: [
                      Text(
                        user?.name ?? 'Hotel World Staff',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? 'hotelworld2017@gmail.com',
                        style: const TextStyle(
                          color: AppColors.slate400,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary500.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.primary500.withOpacity(0.5)),
                        ),
                        child: Text(
                          user?.role ?? 'STAFF',
                          style: const TextStyle(
                            color: AppColors.primary400,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Navigation Links
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const DashboardScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.add_circle_outline,
                  title: 'Create Quotation',
                  color: AppColors.primary600,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateQuotationScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.description_outlined,
                  title: 'Quotations List',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const QuotationListScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.inventory_2_outlined,
                  title: 'Product Catalog',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProductCatalogScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.people_outline,
                  title: 'Customers Directory',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CustomersScreen()),
                    );
                  },
                ),
                if (auth.isAdmin) ...[
                  _buildDrawerItem(
                    context,
                    icon: Icons.manage_accounts_outlined,
                    title: 'Users & Permissions',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const UsersManagementScreen()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.settings_outlined,
                    title: 'Company Settings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),

          // Logout Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Sign Out'),
                onPressed: () async {
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  CrossAxisAlignment pwCrossAxisAlignment(CrossAxisAlignment val) => val;

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.slate700, size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? AppColors.slate800,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      onTap: onTap,
    );
  }
}
