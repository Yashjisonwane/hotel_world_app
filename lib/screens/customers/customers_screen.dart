import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../models/customer.dart';
import '../../providers/customer_provider.dart';
import '../../providers/quotation_provider.dart';
import '../quotation/create_quotation_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().fetchCustomers();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      context.read<CustomerProvider>().fetchCustomers(query: query);
    });
  }

  void _showAddEditCustomerModal({Customer? customer}) {
    final companyCtrl = TextEditingController(text: customer?.companyName ?? '');
    final contactCtrl = TextEditingController(text: customer?.contactPerson ?? '');
    final phoneCtrl = TextEditingController(text: customer?.phone ?? '');
    final emailCtrl = TextEditingController(text: customer?.email ?? '');
    final addressCtrl = TextEditingController(text: customer?.billingAddress ?? '');
    final gstinCtrl = TextEditingController(text: customer?.gstin ?? '');
    final cityCtrl = TextEditingController(text: customer?.city ?? 'Indore');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer != null ? 'Edit Customer' : 'Add New Customer',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                TextField(controller: companyCtrl, decoration: const InputDecoration(labelText: 'Company / Business Name *')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: contactCtrl, decoration: const InputDecoration(labelText: 'Contact Person'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number'))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: gstinCtrl, decoration: const InputDecoration(labelText: 'GSTIN'))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(flex: 2, child: TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address'))),
                    const SizedBox(width: 10),
                    Expanded(flex: 1, child: TextField(controller: cityCtrl, decoration: const InputDecoration(labelText: 'City'))),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final name = companyCtrl.text.trim();
                      if (name.isEmpty) return;

                      final data = {
                        'companyName': name,
                        'contactPerson': contactCtrl.text.trim().isNotEmpty ? contactCtrl.text.trim() : null,
                        'phone': phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
                        'email': emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : null,
                        'billingAddress': addressCtrl.text.trim().isNotEmpty ? addressCtrl.text.trim() : null,
                        'gstin': gstinCtrl.text.trim().isNotEmpty ? gstinCtrl.text.trim().toUpperCase() : null,
                        'city': cityCtrl.text.trim().isNotEmpty ? cityCtrl.text.trim() : 'Indore',
                      };

                      if (customer != null) {
                        await context.read<CustomerProvider>().updateCustomer(customer.id, data);
                      } else {
                        await context.read<CustomerProvider>().addCustomer(data);
                      }

                      if (mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(customer != null ? 'Customer updated!' : 'Customer added successfully!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    },
                    child: Text(customer != null ? 'Update Customer' : 'Save Customer'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final custProv = context.watch<CustomerProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('CUSTOMERS DIRECTORY'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => custProv.fetchCustomers(),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: AppColors.white,
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search customer by name, contact, phone...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          const Divider(),
          Expanded(
            child: custProv.isLoading && custProv.customers.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary500))
                : custProv.customers.isEmpty
                    ? const Center(child: Text('No customers found'))
                    : RefreshIndicator(
                        onRefresh: () => custProv.fetchCustomers(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: custProv.customers.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, idx) {
                            final c = custProv.customers[idx];
                            return Card(
                              margin: EdgeInsets.zero,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primary100,
                                  child: Text(
                                    c.companyName.isNotEmpty ? c.companyName[0].toUpperCase() : 'C',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary700),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        c.companyName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ),
                                    if (c.quotationsCount > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary100,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${c.quotationsCount} quotes',
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary800),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 3),
                                    if (c.phone != null && c.phone!.isNotEmpty)
                                      Text('Phone: ${c.phone}', style: const TextStyle(fontSize: 12, color: AppColors.slate700)),
                                    if (c.billingAddress != null && c.billingAddress!.isNotEmpty)
                                      Text(c.billingAddress!, style: const TextStyle(fontSize: 11, color: AppColors.slate500)),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (c.phone != null && c.phone!.isNotEmpty)
                                      IconButton(
                                        icon: const Icon(Icons.phone, color: AppColors.success, size: 20),
                                        tooltip: 'Call Customer',
                                        onPressed: () => launchUrl(Uri.parse('tel:${c.phone}')),
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.add_shopping_cart, color: AppColors.primary700, size: 20),
                                      tooltip: 'Create Quote for this Customer',
                                      onPressed: () {
                                        final qp = context.read<QuotationProvider>();
                                        qp.initNewQuotation();
                                        qp.setCustomer(c);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => const CreateQuotationScreen()),
                                        );
                                      },
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (val) {
                                        if (val == 'edit') {
                                          _showAddEditCustomerModal(customer: c);
                                        } else if (val == 'delete') {
                                          custProv.deleteCustomer(c.id);
                                        }
                                      },
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                                        PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary500,
        foregroundColor: AppColors.slate950,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Customer', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _showAddEditCustomerModal(),
      ),
    );
  }
}

