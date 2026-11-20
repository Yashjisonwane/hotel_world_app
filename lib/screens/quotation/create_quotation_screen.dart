import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../constants/app_colors.dart';
import '../../models/quotation_item.dart';
import '../../providers/quotation_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/pdf_invoice_service.dart';
import 'widgets/inline_item_card.dart';
import 'quotation_preview_screen.dart';

class CreateQuotationScreen extends StatefulWidget {
  const CreateQuotationScreen({super.key});

  @override
  State<CreateQuotationScreen> createState() => _CreateQuotationScreenState();
}

class _CreateQuotationScreenState extends State<CreateQuotationScreen> {
  final _customerNameCtrl = TextEditingController();
  final _customerPhoneCtrl = TextEditingController();
  final _customerEmailCtrl = TextEditingController();
  final _customerAddressCtrl = TextEditingController();
  final _customerGstinCtrl = TextEditingController();

  final _preparedByCtrl = TextEditingController();
  final _preparedByPhoneCtrl = TextEditingController();
  final _rateGivenByCtrl = TextEditingController();
  final _rateGivenByPhoneCtrl = TextEditingController();

  final _deliveryCtrl = TextEditingController(text: '0');
  final _packingCtrl = TextEditingController(text: '0');
  final _previousCtrl = TextEditingController(text: '0');
  final _instChargesCtrl = TextEditingController(text: '0');
  final _discountCtrl = TextEditingController(text: '0');

  final _deliveryLabelCtrl = TextEditingController(text: 'DELIVERY CHARGES');
  final _packingLabelCtrl = TextEditingController(text: 'PACKING CHARGES');
  final _previousLabelCtrl = TextEditingController(text: 'PREVIOUS CHARGES');

  bool _isInitialized = false;
  bool _isCustomerCardOpen = true;
  bool _isChargesCardOpen = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final qp = context.read<QuotationProvider>();
      _customerNameCtrl.text = qp.customerName;
      _customerPhoneCtrl.text = qp.customerPhone;
      _customerEmailCtrl.text = qp.customerEmail;
      _customerAddressCtrl.text = qp.customerAddress;
      _customerGstinCtrl.text = qp.customerGstin;

      _preparedByCtrl.text = qp.preparedBy ?? '';
      _preparedByPhoneCtrl.text = qp.preparedByPhone ?? '';
      _rateGivenByCtrl.text = qp.rateGivenBy ?? '';
      _rateGivenByPhoneCtrl.text = qp.rateGivenByPhone ?? '';

      _deliveryCtrl.text = qp.deliveryCharges > 0 ? qp.deliveryCharges.toStringAsFixed(0) : '';
      _packingCtrl.text = qp.packingCharges > 0 ? qp.packingCharges.toStringAsFixed(0) : '';
      _previousCtrl.text = qp.previousCharges > 0 ? qp.previousCharges.toStringAsFixed(0) : '';
      _discountCtrl.text = qp.overallDiscount > 0 ? qp.overallDiscount.toStringAsFixed(0) : '';

      _deliveryLabelCtrl.text = qp.deliveryChargeLabel;
      _packingLabelCtrl.text = qp.packingChargeLabel;
      _previousLabelCtrl.text = qp.previousChargeLabel;

      if (qp.items.isEmpty) {
        qp.addNewBlankRow();
      }

      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _customerPhoneCtrl.dispose();
    _customerEmailCtrl.dispose();
    _customerAddressCtrl.dispose();
    _customerGstinCtrl.dispose();
    _preparedByCtrl.dispose();
    _preparedByPhoneCtrl.dispose();
    _rateGivenByCtrl.dispose();
    _rateGivenByPhoneCtrl.dispose();
    _deliveryCtrl.dispose();
    _packingCtrl.dispose();
    _previousCtrl.dispose();
    _instChargesCtrl.dispose();
    _discountCtrl.dispose();
    _deliveryLabelCtrl.dispose();
    _packingLabelCtrl.dispose();
    _previousLabelCtrl.dispose();
    super.dispose();
  }

  void _syncCustomerData() {
    context.read<QuotationProvider>().setCustomerDetails(
      name: _customerNameCtrl.text.trim().isEmpty ? 'Walk-in Customer' : _customerNameCtrl.text.trim(),
      phone: _customerPhoneCtrl.text.trim(),
      email: _customerEmailCtrl.text.trim(),
      address: _customerAddressCtrl.text.trim(),
      gstin: _customerGstinCtrl.text.trim(),
    );
  }

  void _syncCharges() {
    context.read<QuotationProvider>().setAdditionalCharges(
      delivery: double.tryParse(_deliveryCtrl.text) ?? 0.0,
      packing: double.tryParse(_packingCtrl.text) ?? 0.0,
      previous: double.tryParse(_previousCtrl.text) ?? 0.0,
      deliveryLabel: _deliveryLabelCtrl.text.trim(),
      packingLabel: _packingLabelCtrl.text.trim(),
      previousLabel: _previousLabelCtrl.text.trim(),
      discount: double.tryParse(_discountCtrl.text) ?? 0.0,
    );
  }

  void _showCustomerPickerSheet() {
    final custProv = context.read<CustomerProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.75,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Select Customer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search customer by name or phone...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (val) => custProv.fetchCustomers(query: val),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: custProv.isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary500))
                    : custProv.customers.isEmpty
                        ? const Center(child: Text('No customers found'))
                        : ListView.separated(
                            itemCount: custProv.customers.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (c, idx) {
                              final item = custProv.customers[idx];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primary100,
                                  child: Text(
                                    item.companyName.isNotEmpty ? item.companyName[0].toUpperCase() : 'C',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary700),
                                  ),
                                ),
                                title: Text(item.companyName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text([if (item.phone != null) item.phone!, if (item.city != null) item.city!].join(' • ')),
                                onTap: () {
                                  context.read<QuotationProvider>().setCustomer(item);
                                  _customerNameCtrl.text = item.companyName;
                                  _customerPhoneCtrl.text = item.phone ?? '';
                                  _customerEmailCtrl.text = item.email ?? '';
                                  _customerAddressCtrl.text = item.billingAddress ?? '';
                                  _customerGstinCtrl.text = item.gstin ?? '';
                                  Navigator.pop(ctx);
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPhotoZoom(String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary500.withOpacity(0.5)),
              ),
              clipBehavior: Clip.antiAlias,
              child: InteractiveViewer(
                child: imageUrl.startsWith('http')
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image, color: Colors.white, size: 60),
                        ),
                      )
                    : Image.file(
                        File(imageUrl),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image, color: Colors.white, size: 60),
                        ),
                      ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.close, color: Colors.white, size: 20),
                ),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSaveAndPreview() async {
    _syncCustomerData();
    _syncCharges();

    final qp = context.read<QuotationProvider>();
    if (qp.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kripya kam se kam 1 item quotation me add karein.'), backgroundColor: AppColors.error),
      );
      return;
    }

    final saved = await qp.saveActiveQuotation(fallbackToLocal: true);
    if (saved != null && mounted) {
      if (saved.id.startsWith('LOCAL-')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quotation locally save ho gayi hai (Offline Mode). PDF preview open ho raha hai.'),
            backgroundColor: Color(0xFFD97706),
            duration: Duration(seconds: 2),
          ),
        );
      }
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => QuotationPreviewScreen(quotation: saved)),
      );
    }
  }

  Future<void> _handleSharePdf() async {
    _syncCustomerData();
    _syncCharges();

    final qp = context.read<QuotationProvider>();
    if (qp.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kripya kam se kam 1 item quotation me add karein.'), backgroundColor: AppColors.error),
      );
      return;
    }

    final saved = await qp.saveActiveQuotation(fallbackToLocal: true);
    if (saved != null && mounted) {
      final settings = context.read<SettingsProvider>().settings;
      try {
        await PdfInvoiceService.shareQuotationPdf(quotation: saved, settings: settings);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error sharing PDF: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Future<void> _handleExcelExport() async {
    _syncCustomerData();
    _syncCharges();

    final qp = context.read<QuotationProvider>();
    if (qp.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kripya kam se kam 1 item quotation me add karein.'), backgroundColor: AppColors.error),
      );
      return;
    }

    try {
      final quote = qp.buildCurrentQuotation();
      final buffer = StringBuffer();
      // UTF-8 BOM so Microsoft Excel & Google Sheets open cleanly with proper Indian formatting
      buffer.write('\uFEFF');
      buffer.writeln('HOTEL WORLD QUOTATION');
      buffer.writeln('Quote No,"${quote.quotationNumber}",Date,"${DateFormat('dd/MM/yyyy').format(quote.date)}"');
      buffer.writeln('Customer Name,"${quote.customerName}",Phone,"${quote.customerPhone ?? ''}"');
      buffer.writeln('Address,"${quote.customerAddress ?? ''}",GSTIN,"${quote.customerGstin ?? ''}"');
      buffer.writeln('');
      buffer.writeln('S.N.,Item Name,Section,Specification,Size,Qty,Unit,Rate (Rs),Net Amt (Rs),GST %,Gross Amt (Rs)');

      for (int i = 0; i < quote.items.length; i++) {
        final it = quote.items[i];
        final name = it.name.replaceAll('"', '""');
        final sec = (it.section ?? '').replaceAll('"', '""');
        final spec = (it.specification ?? '').replaceAll('"', '""');
        final size = (it.size ?? '').replaceAll('"', '""');
        buffer.writeln('${i + 1},"$name","$sec","$spec","$size",${it.quantity},"${it.unit}",${it.price},${it.netAmount},${it.gstRate == 0 ? (it.isGstInclusive ? "0% inc." : "0%") : "${it.gstRate}%"},${it.grossAmount}');
      }

      buffer.writeln('');
      buffer.writeln(',,,,,,,,,Total Net Amount (Rs),${quote.totalNet}');
      buffer.writeln(',,,,,,,,,Total GST (Rs),${quote.totalGst}');
      if (quote.deliveryCharges > 0) buffer.writeln(',,,,,,,,,Delivery Charges (Rs),${quote.deliveryCharges}');
      if (quote.packingCharges > 0) buffer.writeln(',,,,,,,,,Packing Charges (Rs),${quote.packingCharges}');
      if (quote.previousCharges > 0) buffer.writeln(',,,,,,,,,Previous Balance (Rs),${quote.previousCharges}');
      if (quote.overallDiscount > 0) buffer.writeln(',,,,,,,,,Discount (Rs),-${quote.overallDiscount}');
      buffer.writeln(',,,,,,,,,FINAL PAYABLE (Rs),${quote.finalAmount}');

      final tempDir = await getTemporaryDirectory();
      final cleanNum = quote.quotationNumber.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final file = File('${tempDir.path}/Quotation_$cleanNum.csv');
      await file.writeAsString(buffer.toString());

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        text: 'Hotel World Quotation ${quote.quotationNumber} for ${quote.customerName}',
        subject: 'Quotation ${quote.quotationNumber}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Excel export error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final qp = context.watch<QuotationProvider>();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final isMachinery = qp.quotationType == 'MACHINERY';
    final isPhotoMode = qp.presentationMode == 'PHOTO';

    return PopScope(
      canPop: qp.items.isEmpty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldDiscard = await showDialog<bool>(
          context: context,
          builder: (dCtx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Discard Quotation?', style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text('Aapki banayi hui quotation save nahi hui hai. Kya aap bina save kiye bahar jaana chahte hain?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dCtx, false),
                child: const Text('Wapas Likhein', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: () => Navigator.pop(dCtx, true),
                child: const Text('Discard Karein', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
        if (shouldDiscard == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          qp.editingQuotationId != null ? 'Edit Quotation' : 'Create Quotation',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.language, size: 13, color: Color(0xFF1D4ED8)),
                SizedBox(width: 4),
                Text('English', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ==============================================================
            // 0. TOP QUICK CONTROLS BAR (Single Clean Row for Mobile)
            // [ ⚙️ Machinery: OFF/ON ] | [ GST: 🚫 OFF / ON ] | [ 📷 Photos: OFF/ON ]
            // ==============================================================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  // 1. Machinery Mode Toggle
                  Expanded(
                    child: InkWell(
                      onTap: () => qp.toggleQuotationType(),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
                        decoration: BoxDecoration(
                          color: isMachinery ? const Color(0xFF7C3AED) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isMachinery ? const Color(0xFF6D28D9) : const Color(0xFFCBD5E1),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.precision_manufacturing,
                              size: 14,
                              color: isMachinery ? Colors.white : const Color(0xFF7C3AED),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                isMachinery ? 'Machinery: ON' : 'Machinery: OFF',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: isMachinery ? Colors.white : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // 2. GST Mode Toggle
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        if (qp.gstMode == 'WITH_GST') {
                          qp.setGstMode('WITHOUT_GST');
                        } else {
                          qp.setGstMode('WITH_GST');
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
                        decoration: BoxDecoration(
                          color: qp.gstMode == 'WITH_GST' ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: qp.gstMode == 'WITH_GST' ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              qp.gstMode == 'WITH_GST' ? Icons.check_circle : Icons.block,
                              size: 14,
                              color: qp.gstMode == 'WITH_GST' ? const Color(0xFF047857) : const Color(0xFFB45309),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                qp.gstMode == 'WITH_GST' ? 'GST: ON' : 'GST: 🚫 OFF',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: qp.gstMode == 'WITH_GST' ? const Color(0xFF047857) : const Color(0xFFB45309),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // 3. Photos Mode Toggle (Strict ON / OFF)
                  Expanded(
                    child: InkWell(
                      onTap: () => qp.togglePresentationMode(),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
                        decoration: BoxDecoration(
                          color: isPhotoMode ? const Color(0xFF2563EB) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isPhotoMode ? const Color(0xFF1D4ED8) : const Color(0xFFCBD5E1),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 14,
                              color: isPhotoMode ? Colors.white : const Color(0xFF2563EB),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                isPhotoMode ? 'Photos: ON' : 'Photos: OFF',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: isPhotoMode ? Colors.white : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ==============================================================
            // 1. PARTY / CUSTOMER DETAILS CARD (Matches Web Screenshot 2)
            // ==============================================================
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  // Card Header
                  InkWell(
                    onTap: () => setState(() => _isCustomerCardOpen = !_isCustomerCardOpen),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      color: const Color(0xFFF8FAFC),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.business_center, size: 17, color: Color(0xFFD97706)),
                              SizedBox(width: 8),
                              Text(
                                'Party / Customer Details',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                _customerNameCtrl.text.isNotEmpty ? _customerNameCtrl.text : 'Walk-in',
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                _isCustomerCardOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                size: 18,
                                color: const Color(0xFF64748B),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_isCustomerCardOpen)
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // CUSTOMER NAME / HOTEL NAME
                          const Text(
                            'CUSTOMER NAME / HOTEL NAME:',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _customerNameCtrl,
                                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                                  decoration: InputDecoration(
                                    hintText: 'Type name (e.g. Hotel Radisson, Yash...)',
                                    hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5)),
                                  ),
                                  onChanged: (_) => _syncCustomerData(),
                                ),
                              ),
                              const SizedBox(width: 6),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEFF6FF),
                                  foregroundColor: const Color(0xFF1D4ED8),
                                  elevation: 0,
                                  side: const BorderSide(color: Color(0xFFBFDBFE)),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: _showCustomerPickerSheet,
                                child: const Text('Pick', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // MOBILE / PHONE
                          const Text(
                            'MOBILE / PHONE:',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _customerPhoneCtrl,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              hintText: 'Phone number',
                              hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5)),
                            ),
                            onChanged: (_) => _syncCustomerData(),
                          ),
                          const SizedBox(height: 10),

                          // BILLING ADDRESS / LOCATION
                          const Text(
                            'BILLING ADDRESS / LOCATION:',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _customerAddressCtrl,
                            maxLines: 2,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Address / City',
                              hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5)),
                            ),
                            onChanged: (_) => _syncCustomerData(),
                          ),
                          const SizedBox(height: 10),

                          // Doc Type Selector: [ QUOTE ] [ PI ] [ PROFORMA ] [ ESTIMATE ]
                          Row(
                            children: [
                              const Text('Doc Type: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF334155))),
                              const SizedBox(width: 4),
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  child: Row(
                                    children: [
                                      {'label': 'QUOTE', 'val': 'QUOTATION'},
                                      {'label': 'PI', 'val': 'PI'},
                                      {'label': 'PROFORMA', 'val': 'PROFORMA INVOICE'},
                                      {'label': 'ESTIMATE', 'val': 'ESTIMATE'},
                                    ].map((d) {
                                      final isSel = (qp.documentTitle).toUpperCase() == d['val'];
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 6),
                                        child: InkWell(
                                          onTap: () => qp.setQuotationMeta(documentTitle: d['val']),
                                          borderRadius: BorderRadius.circular(6),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: isSel ? const Color(0xFFEFF6FF) : AppColors.white,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: isSel ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                                                width: isSel ? 1.5 : 1,
                                              ),
                                            ),
                                            child: Text(
                                              d['label']!,
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w900,
                                                color: isSel ? const Color(0xFF1D4ED8) : const Color(0xFF475569),
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Gray Info Bar: Quote No & Date (Exact matching Web Screenshot 2)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Quote No: ${qp.quotationNumber}',
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                ),
                                Text(
                                  'Date: ${dateFormat.format(qp.quotationDate)}',
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // ==============================================================
            // 2. ITEMS SECTION HEADER (Matches Web Screenshot 3)
            // 🏷️ Items (N)    [ Machinery: OFF ] [ 📷 + Photos ]
            // ==============================================================
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 2, right: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sell_outlined, size: 16, color: Color(0xFF2563EB)),
                      const SizedBox(width: 6),
                      Text(
                        'Items (${qp.items.length})',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      InkWell(
                        onTap: () => qp.toggleQuotationType(),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isMachinery ? const Color(0xFFEDE9FE) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isMachinery ? const Color(0xFF7C3AED) : const Color(0xFFCBD5E1), width: 1.5),
                          ),
                          child: Text(
                            isMachinery ? 'Machinery: ON' : 'Machinery: OFF',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isMachinery ? const Color(0xFF6D28D9) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => qp.togglePresentationMode(),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPhotoMode ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isPhotoMode ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1), width: 1.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.camera_alt, size: 12, color: isPhotoMode ? const Color(0xFF1D4ED8) : const Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Text(
                                isPhotoMode ? 'Photos: ON' : '+ Photos',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isPhotoMode ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // INLINE ITEM CARDS (Exact match to Screenshot 3)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: qp.items.length,
              itemBuilder: (ctx, idx) {
                final it = qp.items[idx];
                return InlineItemCard(
                  key: ValueKey(it.id ?? 'row_$idx'),
                  item: it,
                  index: idx,
                  isMachinery: isMachinery,
                  isPhotoMode: isPhotoMode,
                  gstMode: qp.gstMode,
                  onChanged: (updated) => qp.updateItem(idx, updated),
                  onDelete: () => qp.removeItem(idx),
                  onPhotoZoom: _showPhotoZoom,
                );
              },
            ),

            // CLEAR ACTION BUTTONS BELOW ITEMS (Normal vs Machinery)
            if (isMachinery) ...[
              // 1. + Add Normal Item (Hotelware / Bartan)
              InkWell(
                onTap: () {
                  final newItem = QuotationItem(
                    serialNumber: qp.items.length + 1,
                    name: '',
                    quantity: 1.0,
                    unit: 'Pcs',
                    price: 0.0,
                    gstRate: qp.gstMode == 'WITH_GST' ? 18.0 : 0.0,
                    isGstAdded: qp.gstMode == 'WITH_GST',
                    section: null,
                    specification: null,
                    size: null,
                  );
                  newItem.recalculate();
                  qp.addItem(newItem);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2563EB), width: 1.8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add_circle_outline, color: Color(0xFF1D4ED8), size: 18),
                      SizedBox(width: 6),
                      Text(
                        '+ Normal Item Add Karein (Hotelware / Bartan)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1D4ED8)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // 2. + Add Machinery Item (Specs & Size)
              InkWell(
                onTap: () {
                  final lastSec = qp.items.reversed.firstWhere(
                    (it) => it.section != null && it.section!.trim().isNotEmpty,
                    orElse: () => QuotationItem(name: '', section: 'EQUIPMENT SECTION'),
                  ).section ?? 'EQUIPMENT SECTION';

                  final newItem = QuotationItem(
                    serialNumber: qp.items.length + 1,
                    name: '',
                    quantity: 1.0,
                    unit: 'Pcs',
                    price: 0.0,
                    gstRate: qp.gstMode == 'WITH_GST' ? 18.0 : 0.0,
                    isGstAdded: qp.gstMode == 'WITH_GST',
                    section: lastSec,
                  );
                  newItem.recalculate();
                  qp.addItem(newItem);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF7C3AED), width: 1.8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add_circle, color: Color(0xFF6D28D9), size: 18),
                      SizedBox(width: 6),
                      Text(
                        '+ Machinery Item Add Karein (Specs & Size)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF6D28D9)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ] else ...[
              // Standard Mode: + Add Another Item
              InkWell(
                onTap: () => qp.addNewBlankRow(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF60A5FA), width: 1.8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add, color: Color(0xFF1D4ED8), size: 18),
                      SizedBox(width: 6),
                      Text(
                        '+ Add Another Item (सामान जोड़ें)',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF1D4ED8)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // 3. + New Custom Product (नया कस्टम सामान जोड़ें)
            InkWell(
              onTap: () {
                final newItem = QuotationItem(
                  serialNumber: qp.items.length + 1,
                  name: 'Custom Product',
                  quantity: 1.0,
                  unit: 'Pcs',
                  price: 0.0,
                  gstRate: qp.gstMode == 'WITH_GST' ? 18.0 : 0.0,
                  isGstAdded: qp.gstMode == 'WITH_GST',
                );
                newItem.recalculate();
                qp.addItem(newItem);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.edit, color: Color(0xFFB45309), size: 16),
                    SizedBox(width: 6),
                    Text(
                      '+ New Custom Product (नया कस्टम सामान जोड़ें)',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ==============================================================
            // 3. ADDITIONAL CHARGES & DISCOUNT (खर्चे व छूट) (Screenshot 4)
            // ==============================================================
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  InkWell(
                    onTap: () => setState(() => _isChargesCardOpen = !_isChargesCardOpen),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      color: const Color(0xFFF8FAFC),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Additional Charges & Discount (खर्चे व छूट)',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                          Icon(
                            _isChargesCardOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            size: 18,
                            color: const Color(0xFF64748B),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_isChargesCardOpen)
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          // DELIVERY CHARGES
                          Row(
                            children: [
                              Expanded(
                                flex: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: const Text('DELIVERY CHARGES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('+₹', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                              const SizedBox(width: 4),
                              Expanded(
                                flex: 4,
                                child: TextField(
                                  controller: _deliveryCtrl,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    isDense: true,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                  ),
                                  onChanged: (_) => _syncCharges(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // PACKING CHARGES
                          Row(
                            children: [
                              Expanded(
                                flex: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: const Text('PACKING CHARGES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('+₹', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                              const SizedBox(width: 4),
                              Expanded(
                                flex: 4,
                                child: TextField(
                                  controller: _packingCtrl,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    isDense: true,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                  ),
                                  onChanged: (_) => _syncCharges(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // PREVIOUS CHARGES (Amber Highlight)
                          Row(
                            children: [
                              Expanded(
                                flex: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFF59E0B)),
                                  ),
                                  child: const Text('PREVIOUS CHARGES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('+₹', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                              const SizedBox(width: 4),
                              Expanded(
                                flex: 4,
                                child: TextField(
                                  controller: _previousCtrl,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    isDense: true,
                                    fillColor: const Color(0xFFFFFBEB),
                                    filled: true,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFF59E0B))),
                                  ),
                                  onChanged: (_) => _syncCharges(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Installation / Fitting (+₹)
                          Row(
                            children: [
                              const Expanded(
                                flex: 6,
                                child: Text('Installation / Fitting (+₹):', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                              ),
                              Expanded(
                                flex: 4,
                                child: TextField(
                                  controller: _instChargesCtrl,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    isDense: true,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                  ),
                                  onChanged: (_) => _syncCharges(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Special Discount (-₹)
                          Row(
                            children: [
                              const Expanded(
                                flex: 6,
                                child: Text('Special Discount (-₹):', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFFDC2626))),
                              ),
                              Expanded(
                                flex: 4,
                                child: TextField(
                                  controller: _discountCtrl,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    isDense: true,
                                    fillColor: const Color(0xFFFEF2F2),
                                    filled: true,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFFCA5A5))),
                                  ),
                                  onChanged: (_) => _syncCharges(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // ==============================================================
            // 4. GRAND TOTAL HERO BANNER (Matches Web Screenshot 4 & 5)
            // ==============================================================
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Net Total:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5)),
                      Text('₹ ${qp.totalNetAmt.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (qp.gstMode != 'WITHOUT_GST') ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total GST:', style: TextStyle(color: Color(0xFF86EFAC), fontSize: 12.5)),
                        Text('+ ₹ ${qp.totalGstAmt.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF86EFAC), fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('FINAL QUOTATION AMOUNT:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFE2E8F0))),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                qp.gstMode == 'WITHOUT_GST' ? '(Without GST)' : '(With GST)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: qp.gstMode == 'WITHOUT_GST' ? const Color(0xFFFDE047) : const Color(0xFF86EFAC),
                                ),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () {
                                  if (qp.gstMode == 'WITH_GST') {
                                    qp.setGstMode('WITHOUT_GST');
                                  } else {
                                    qp.setGstMode('WITH_GST');
                                  }
                                },
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF334155),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    qp.gstMode == 'WITH_GST' ? 'Remove GST' : '+ Add GST (18%)',
                                    style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        '₹ ${qp.finalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFFFBBF24)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ==============================================================
            // 5. PREPARED BY & RATE GIVEN BY (Matches Web Screenshot 5)
            // ==============================================================
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Prepared By:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                        const SizedBox(height: 3),
                        TextField(
                          controller: _preparedByCtrl,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            isDense: true,
                            hintText: 'Staff Name',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                          ),
                          onChanged: (v) => qp.setQuotationMeta(preparedBy: v),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _preparedByPhoneCtrl,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(fontSize: 11.5),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            isDense: true,
                            hintText: 'Mobile (Optional)',
                            hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          ),
                          onChanged: (v) => qp.setQuotationMeta(preparedByPhone: v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Rate Given By:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                        const SizedBox(height: 3),
                        TextField(
                          controller: _rateGivenByCtrl,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            isDense: true,
                            hintText: 'Manager Name',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                          ),
                          onChanged: (v) => qp.setQuotationMeta(rateGivenBy: v),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _rateGivenByPhoneCtrl,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(fontSize: 11.5),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            isDense: true,
                            hintText: 'Mobile (Optional)',
                            hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          ),
                          onChanged: (v) => qp.setQuotationMeta(rateGivenByPhone: v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // ==============================================================
      // 6. STICKY BOTTOM ACTION BAR (Exact match to Web Screenshots 1 - 5)
      // TOTAL AMOUNT: ₹ 0 | [ 📥 PDF ] | [ 📊 Excel ] | [ 🔗 ] | [ ✓ Save & View ]
      // ==============================================================
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          border: const Border(top: BorderSide(color: Color(0xFFCBD5E1), width: 1.5)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -3)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tier 1: Total Amount & Items Summary
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                color: const Color(0xFFF8FAFC),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('TOTAL: ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                        Text(
                          '₹ ${qp.finalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    Text(
                      '${qp.items.length} ${qp.items.length == 1 ? "Item" : "Items"}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              // Tier 2: Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    // PDF Button
                    Expanded(
                      flex: 1,
                      child: InkWell(
                        onTap: _handleSaveAndPreview,
                        child: Container(
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.download, size: 14, color: Colors.white),
                              SizedBox(width: 3),
                              Text('PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Excel Button
                    Expanded(
                      flex: 1,
                      child: InkWell(
                        onTap: _handleExcelExport,
                        child: Container(
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.table_chart_outlined, size: 14, color: Colors.white),
                              SizedBox(width: 3),
                              Text('Excel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Share WhatsApp Button
                    InkWell(
                      onTap: _handleSharePdf,
                      child: Container(
                        height: 38,
                        width: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.share, size: 16, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Save & View Button
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: _handleSaveAndPreview,
                        child: Container(
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD97706),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFFD97706).withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.check_circle_outline, size: 15, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'Save & View',
                                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
