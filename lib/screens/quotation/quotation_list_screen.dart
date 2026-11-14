import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../services/pricing_engine.dart';
import '../../services/pdf_invoice_service.dart';
import '../../providers/quotation_provider.dart';
import '../../providers/settings_provider.dart';
import 'create_quotation_screen.dart';
import 'quotation_preview_screen.dart';

class QuotationListScreen extends StatefulWidget {
  const QuotationListScreen({super.key});

  @override
  State<QuotationListScreen> createState() => _QuotationListScreenState();
}

class _QuotationListScreenState extends State<QuotationListScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      context.read<QuotationProvider>().search(query);
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACCEPTED':
        return AppColors.statusAcceptedText;
      case 'REJECTED':
        return AppColors.statusRejectedText;
      case 'ISSUED':
        return AppColors.statusSentText;
      case 'DRAFT':
        return AppColors.statusDraftText;
      default:
        return AppColors.primary700;
    }
  }

  Color _getStatusBg(String status) {
    switch (status.toUpperCase()) {
      case 'ACCEPTED':
        return AppColors.statusAcceptedBg;
      case 'REJECTED':
        return AppColors.statusRejectedBg;
      case 'ISSUED':
        return AppColors.statusSentBg;
      case 'DRAFT':
        return AppColors.statusDraftBg;
      default:
        return AppColors.primary100;
    }
  }

  @override
  Widget build(BuildContext context) {
    final qp = context.watch<QuotationProvider>();
    final settingsProv = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // NO HAMBURGER SIDEBAR
        title: const Text('QUOTATIONS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => qp.fetchQuotations(refresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Container(
            padding: const EdgeInsets.all(12),
            color: AppColors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search by Quote #, Customer Name, Phone...',
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
                const SizedBox(height: 8),
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['ALL', 'ACTIVE', 'ISSUED', 'ACCEPTED', 'REJECTED'].map((st) {
                      final isSelected = qp.selectedStatus == st;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(st),
                          selected: isSelected,
                          selectedColor: AppColors.primary500,
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.slate950 : AppColors.slate700,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 11,
                          ),
                          onSelected: (val) {
                            if (val) qp.setStatusFilter(st);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),

          // Quotation List
          Expanded(
            child: qp.isLoading && qp.quotations.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary500))
                : qp.quotations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.description_outlined, size: 54, color: AppColors.slate400),
                            const SizedBox(height: 12),
                            const Text('No quotations found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 6),
                            TextButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Create New Quotation'),
                              onPressed: () {
                                qp.initNewQuotation();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const CreateQuotationScreen()),
                                );
                              },
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => qp.fetchQuotations(refresh: true),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: qp.quotations.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, idx) {
                            final q = qp.quotations[idx];
                            return Card(
                              margin: EdgeInsets.zero,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => QuotationPreviewScreen(quotation: q)),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            q.quotationNumber,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: _getStatusBg(q.status),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              q.status,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: _getStatusColor(q.status),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        q.customerName,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.slate800),
                                      ),
                                      if (q.customerPhone != null && q.customerPhone!.isNotEmpty)
                                        Text('Phone: ${q.customerPhone}', style: const TextStyle(fontSize: 11, color: AppColors.slate500)),
                                      const Divider(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${_dateFormat.format(q.date)} • ${q.items.length} items',
                                            style: const TextStyle(fontSize: 11, color: AppColors.slate500),
                                          ),
                                          Text(
                                            PricingEngine.formatCurrency(q.finalAmount),
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary800),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.share, size: 19, color: AppColors.slate600),
                                            tooltip: 'Share on WhatsApp',
                                            onPressed: () {
                                              PdfInvoiceService.shareQuotationPdf(
                                                quotation: q,
                                                settings: settingsProv.settings,
                                              );
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 19, color: AppColors.slate600),
                                            tooltip: 'Edit',
                                            onPressed: () {
                                              qp.loadQuotationForEdit(q);
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (_) => const CreateQuotationScreen()),
                                              );
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 19, color: AppColors.error),
                                            tooltip: 'Delete',
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (dCtx) => AlertDialog(
                                                  title: const Text('Delete Quotation?'),
                                                  content: Text('Are you sure you want to delete ${q.quotationNumber}?'),
                                                  actions: [
                                                    TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
                                                    ElevatedButton(
                                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                                      onPressed: () {
                                                        qp.deleteQuotation(q.id);
                                                        Navigator.pop(dCtx);
                                                      },
                                                      child: const Text('Delete'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
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
        icon: const Icon(Icons.add),
        label: const Text('New Quote', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          qp.initNewQuotation();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateQuotationScreen()),
          );
        },
      ),
    );
  }
}
