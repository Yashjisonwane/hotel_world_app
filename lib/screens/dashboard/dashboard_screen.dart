import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../services/pricing_engine.dart';
import '../../services/pdf_invoice_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/quotation_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/settings_provider.dart';
import '../quotation/create_quotation_screen.dart';
import '../quotation/quotation_list_screen.dart';
import '../quotation/quotation_preview_screen.dart';
import '../catalog/product_catalog_screen.dart';
import '../customers/customers_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuotationProvider>().fetchQuotations(refresh: true);
      context.read<ProductProvider>().fetchProducts(refresh: true);
      context.read<CustomerProvider>().fetchCustomers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final quoteProv = context.watch<QuotationProvider>();
    final prodProv = context.watch<ProductProvider>();
    final custProv = context.watch<CustomerProvider>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // NO HAMBURGER SIDEBAR
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A), // Black plate
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary500.withOpacity(0.5)),
              ),
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.restaurant,
                  color: AppColors.primary400,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text('HOTEL WORLD'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary400),
            tooltip: 'Sync Data',
            onPressed: () {
              quoteProv.fetchQuotations(refresh: true);
              prodProv.fetchProducts(refresh: true);
              custProv.fetchCustomers();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            quoteProv.fetchQuotations(refresh: true),
            prodProv.fetchProducts(refresh: true),
            custProv.fetchCustomers(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Banner with Full HW Logo
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.slate950, AppColors.slate900],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary500.withOpacity(0.35)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Full Brand Logo
                        Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.primary500.withOpacity(0.5)),
                          ),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary500.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primary500.withOpacity(0.4)),
                          ),
                          child: const Text(
                            'ENTERPRISE',
                            style: TextStyle(
                              color: AppColors.primary400,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Welcome back, ${auth.currentUser?.name ?? 'Admin'}',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Commercial Kitchen & Hospitality Equipment System',
                      style: TextStyle(color: AppColors.slate400, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // KPI Stats Grid
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Total Quotes',
                      value: quoteProv.totalCount.toString(),
                      icon: Icons.description_outlined,
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Catalog Items',
                      value: prodProv.totalCount.toString(),
                      icon: Icons.inventory_2_outlined,
                      color: AppColors.primary600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CustomersScreen()),
                        );
                      },
                      child: _buildStatCard(
                        title: 'Customers',
                        value: custProv.customers.length.toString(),
                        icon: Icons.people_outline,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Active Drafts',
                      value: quoteProv.quotations.where((q) => q.status == 'ACTIVE').length.toString(),
                      icon: Icons.pending_actions_outlined,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.slate900),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildActionBtn(
                      title: 'New Quotation',
                      icon: Icons.add_circle,
                      isPrimary: true,
                      onTap: () {
                        quoteProv.initNewQuotation();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CreateQuotationScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionBtn(
                      title: 'Browse Catalog',
                      icon: Icons.search,
                      isPrimary: false,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProductCatalogScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Recent Quotations Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Quotations',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.slate900),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const QuotationListScreen()),
                      );
                    },
                    child: const Text('View All', style: TextStyle(color: AppColors.primary700, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Quotation List
              if (quoteProv.isLoading && quoteProv.quotations.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(color: AppColors.primary500),
                  ),
                )
              else if (quoteProv.quotations.isEmpty)
                Container(
                  padding: const EdgeInsets.all(28),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.description_outlined, size: 48, color: AppColors.slate400),
                      const SizedBox(height: 10),
                      const Text(
                        'No quotations yet',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.slate700),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap "New Quotation" to create your first quote.',
                        style: TextStyle(fontSize: 12, color: AppColors.slate500),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: quoteProv.quotations.take(5).length,
                  itemBuilder: (context, idx) {
                    final q = quoteProv.quotations[idx];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.receipt_long, color: AppColors.primary700, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      q.quotationNumber,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                  ],
                                ),
                                Text(
                                  PricingEngine.formatCurrency(q.finalAmount),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary800),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              q.customerName,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.slate800),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${q.items.length} items • ${_dateFormat.format(q.date)}',
                              style: const TextStyle(fontSize: 11, color: AppColors.slate500),
                            ),
                            const Divider(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFDC2626), // High-visibility PDF Red
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    elevation: 2,
                                  ),
                                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                                  label: const Text(
                                    'VIEW PDF',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => QuotationPreviewScreen(quotation: q)),
                                    );
                                  },
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.slate600),
                                      tooltip: 'Edit Quotation',
                                      onPressed: () {
                                        quoteProv.loadQuotationForEdit(q);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => const CreateQuotationScreen()),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.share, size: 20, color: AppColors.slate600),
                                      tooltip: 'Share on WhatsApp',
                                      onPressed: () {
                                        final settingsProv = context.read<SettingsProvider>();
                                        PdfInvoiceService.shareQuotationPdf(
                                          quotation: q,
                                          settings: settingsProv.settings,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: AppColors.slate500, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.slate900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn({
    required String title,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    if (isPrimary) {
      return ElevatedButton.icon(
        icon: Icon(icon, size: 18),
        label: Text(title),
        onPressed: onTap,
      );
    }
    return OutlinedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(title),
      onPressed: onTap,
    );
  }
}
