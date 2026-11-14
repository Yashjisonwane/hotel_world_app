import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import '../../constants/app_colors.dart';
import '../../models/quotation.dart';
import '../../providers/settings_provider.dart';
import '../../providers/quotation_provider.dart';
import '../../services/pdf_invoice_service.dart';
import 'create_quotation_screen.dart';

class QuotationPreviewScreen extends StatelessWidget {
  final Quotation quotation;

  const QuotationPreviewScreen({super.key, required this.quotation});

  @override
  Widget build(BuildContext context) {
    final settingsProv = context.watch<SettingsProvider>();
    final settings = settingsProv.settings;

    return Scaffold(
      appBar: AppBar(
        title: Text('${quotation.documentTitle}: ${quotation.quotationNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.primary400),
            tooltip: 'Share on WhatsApp / Email',
            onPressed: () async {
              try {
                await PdfInvoiceService.shareQuotationPdf(
                  quotation: quotation,
                  settings: settings,
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error sharing PDF: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.print, color: AppColors.primary400),
            tooltip: 'Print Quotation',
            onPressed: () async {
              try {
                await PdfInvoiceService.printQuotation(
                  quotation: quotation,
                  settings: settings,
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error printing PDF: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.primary400),
            tooltip: 'Edit Quotation',
            onPressed: () {
              context.read<QuotationProvider>().loadQuotationForEdit(quotation);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const CreateQuotationScreen()),
              );
            },
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => PdfInvoiceService.generateQuotationPdf(
          quotation: quotation,
          settings: settings,
        ),
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        dynamicLayout: false,
        pdfFileName: '${quotation.quotationNumber.replaceAll('/', '_')}.pdf',
        previewPageMargin: const EdgeInsets.all(12),
      ),
    );
  }
}

