import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dio/dio.dart';
import '../models/quotation.dart';
import '../models/company_settings.dart';

class PdfInvoiceService {
  static final DateFormat dateFormatter = DateFormat('dd/MM/yyyy');

  static String formatAmount(double val) {
    final formatter = NumberFormat('#,##,##0.00', 'en_IN');
    return formatter.format(val);
  }

  static String formatInteger(double val) {
    final formatter = NumberFormat('#,##,##0', 'en_IN');
    return formatter.format(val);
  }

  static Future<Uint8List> generateQuotationPdf({
    required Quotation quotation,
    required CompanySettings settings,
  }) async {
    // 0. Load Unicode TrueType Fonts with Native Indian Rupee (₹) Symbol Support
    pw.Font? ttfRegular;
    pw.Font? ttfBold;
    try {
      ttfRegular = await PdfGoogleFonts.notoSansRegular();
      ttfBold = await PdfGoogleFonts.notoSansBold();
    } catch (_) {}

    final bool fontLoaded = ttfRegular != null && ttfBold != null;
    final String currSymbol = fontLoaded ? '₹ ' : 'Rs. ';

    final pw.ThemeData pdfTheme = fontLoaded
        ? pw.ThemeData.withFont(base: ttfRegular, bold: ttfBold)
        : pw.ThemeData.base();

    final pdf = pw.Document(theme: pdfTheme);

    // 1. Load Company Logo
    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/images/logo.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {}

    // 2. Pre-fetch Item Images for Photo Mode
    final Map<String, pw.MemoryImage> itemImages = {};
    final isPhotoMode = quotation.presentationMode == 'PHOTO';

    if (isPhotoMode) {
      final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 4), receiveTimeout: const Duration(seconds: 5)));
      for (final it in quotation.items) {
        final url = it.imageUrl;
        if (url != null && url.isNotEmpty && !itemImages.containsKey(url)) {
          try {
            if (url.startsWith('http')) {
              final res = await dio.get<List<int>>(url, options: Options(responseType: ResponseType.bytes));
              if (res.data != null) {
                itemImages[url] = pw.MemoryImage(Uint8List.fromList(res.data!));
              }
            } else {
              final file = File(url);
              if (await file.exists()) {
                final bytes = await file.readAsBytes();
                itemImages[url] = pw.MemoryImage(bytes);
              }
            }
          } catch (_) {}
        }
      }
    }

    final hasGst = quotation.totalGst > 0 || quotation.items.any((it) => it.isGstAdded && it.gstRate > 0);
    final docTitle = quotation.documentTitle.isNotEmpty ? quotation.documentTitle.toUpperCase() : 'QUOTATION';
    final isMachinery = quotation.quotationType == 'MACHINERY';

    // 3. Build MultiPage Document matching Indore Hotel World Official Reference Layout
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(16),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 4),
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
          ),
        ),
        build: (context) {
          return [
            // ==============================================================
            // 0-3. DOCUMENT HEADER & META
            // ==============================================================
            pw.Container(
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(color: PdfColors.black, width: 2),
                  left: pw.BorderSide(color: PdfColors.black, width: 2),
                  right: pw.BorderSide(color: PdfColors.black, width: 2),
                  bottom: pw.BorderSide(color: PdfColors.black, width: 2),
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  // ==============================================================
                  // 0. TOP DOCUMENT TITLE BANNER (Pitch Black + Gold Text)
                  // ==============================================================
                  pw.Container(
                    width: double.infinity,
                    color: PdfColors.black,
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Center(
                      child: pw.Text(
                        docTitle,
                        style: pw.TextStyle(
                          color: PdfColor.fromHex('#E5A93C'),
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                  ),

                  // ==============================================================
                  // 1. HOTEL WORLD BRAND HEADER (Black Background + Gold Title + HW Logo)
                  // ==============================================================
                  pw.Container(
                    color: PdfColors.black,
                    padding: const pw.EdgeInsets.fromLTRB(14, 6, 14, 10),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        // Left Company Meta
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                settings.companyName.isNotEmpty ? settings.companyName : 'HOTEL WORLD',
                                style: pw.TextStyle(
                                  color: PdfColor.fromHex('#E5A93C'),
                                  fontSize: 18,
                                  fontWeight: pw.FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                settings.tagline.isNotEmpty ? settings.tagline.toUpperCase() : 'ALL TYPES OF HOTELWARE & CATERING CROCKERY',
                                style: pw.TextStyle(
                                  color: PdfColors.white,
                                  fontSize: 8.5,
                                  fontWeight: pw.FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              pw.SizedBox(height: 3),
                              pw.Text(
                                'ADDRESS : ${settings.address.isNotEmpty ? settings.address : "215 , JAWAHAR MARG (RAJMOHALLA) INDORE , M.P"}',
                                style: pw.TextStyle(color: PdfColors.white, fontSize: 7.5, fontWeight: pw.FontWeight.bold),
                              ),
                              pw.Text(
                                'PHONE NO. ${settings.phone.isNotEmpty ? settings.phone : "94250-63550 / 70007-72501"}',
                                style: pw.TextStyle(color: PdfColors.white, fontSize: 7.5, fontWeight: pw.FontWeight.bold),
                              ),
                              pw.Text(
                                'E-MAIL : ${settings.email.isNotEmpty ? settings.email : "hotelworld2017@gmail.com"}',
                                style: pw.TextStyle(color: PdfColors.white, fontSize: 7.5, fontWeight: pw.FontWeight.bold),
                              ),
                              pw.Text(
                                'GSTIN : ${settings.gstin.isNotEmpty ? settings.gstin : "23ADBPC6221H1Z9"}',
                                style: pw.TextStyle(color: PdfColors.white, fontSize: 7.5, fontWeight: pw.FontWeight.bold),
                              ),
                            ],
                          ),
                        ),

                        // Right Logo Plate
                        if (logoImage != null)
                          pw.Container(
                            width: 100,
                            height: 55,
                            child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                          ),
                      ],
                    ),
                  ),

                  // ==============================================================
                  // 2. PURCHASER and DATE BOXES (Side-by-side with Black Borders)
                  // ==============================================================
                  pw.Container(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        top: pw.BorderSide(color: PdfColors.black, width: 2),
                        bottom: pw.BorderSide(color: PdfColors.black, width: 2),
                      ),
                    ),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Purchaser Box (Left 68%)
                        pw.Expanded(
                          flex: 68,
                          child: pw.Container(
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(right: pw.BorderSide(color: PdfColors.black, width: 2)),
                            ),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                              children: [
                                pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(vertical: 3),
                                  decoration: const pw.BoxDecoration(
                                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1.5)),
                                  ),
                                  child: pw.Center(
                                    child: pw.Text(
                                      'PURCHASER',
                                      style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, letterSpacing: 1),
                                    ),
                                  ),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.fromLTRB(10, 6, 10, 8),
                                  child: pw.Column(
                                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text('NAME : ${quotation.customerName.toUpperCase()}', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                                      pw.SizedBox(height: 2),
                                      pw.Text('ADDRESS : ${quotation.customerAddress != null && quotation.customerAddress!.isNotEmpty ? quotation.customerAddress! : "—"}', style: const pw.TextStyle(fontSize: 8)),
                                      pw.SizedBox(height: 2),
                                      pw.Text('PHONE NO. : ${quotation.customerPhone != null && quotation.customerPhone!.isNotEmpty ? quotation.customerPhone! : "—"}', style: const pw.TextStyle(fontSize: 8)),
                                      pw.SizedBox(height: 2),
                                      pw.Text('E-MAIL : ${quotation.customerEmail != null && quotation.customerEmail!.isNotEmpty ? quotation.customerEmail! : "—"}', style: const pw.TextStyle(fontSize: 8)),
                                      pw.SizedBox(height: 2),
                                      pw.Text('GSTIN : ${quotation.customerGstin != null && quotation.customerGstin!.isNotEmpty ? quotation.customerGstin! : "—"}', style: const pw.TextStyle(fontSize: 8)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Date & Quote No Box (Right 32%)
                        pw.Expanded(
                          flex: 32,
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                            children: [
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(vertical: 3),
                                decoration: const pw.BoxDecoration(
                                  border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1.5)),
                                ),
                                child: pw.Center(
                                  child: pw.Text(
                                    'DATE',
                                    style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, letterSpacing: 1),
                                  ),
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.fromLTRB(6, 12, 6, 12),
                                child: pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                                  children: [
                                    pw.Text(
                                      dateFormatter.format(quotation.date),
                                      style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                                    ),
                                    pw.SizedBox(height: 4),
                                    pw.Text(
                                      '#${quotation.quotationNumber}',
                                      style: pw.TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: pw.FontWeight.bold,
                                        color: PdfColor.fromHex('#1E40AF'),
                                      ),
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
                  // 3. ORDER & ESTIMATE / QUOTATION BANNER
                  // ==============================================================
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 2)),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        'ORDER & ESTIMATE / $docTitle',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, letterSpacing: 1),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ==============================================================
            // 4. ITEMS TABLE (Flows and splits across pages automatically)
            // ==============================================================
            pw.Table(
              border: const pw.TableBorder(
                left: pw.BorderSide(color: PdfColors.black, width: 2),
                right: pw.BorderSide(color: PdfColors.black, width: 2),
                bottom: pw.BorderSide(color: PdfColors.black, width: 1.5),
                horizontalInside: pw.BorderSide(color: PdfColors.black, width: 1),
                verticalInside: pw.BorderSide(color: PdfColors.black, width: 1),
              ),
                    columnWidths: isPhotoMode
                        ? {
                            0: const pw.FixedColumnWidth(26), // S.N.
                            1: const pw.FixedColumnWidth(46), // PHOTO
                            2: const pw.FlexColumnWidth(3),   // PARTICULAR
                            3: const pw.FixedColumnWidth(48), // QTY
                            4: const pw.FixedColumnWidth(48), // PRICE
                            if (hasGst) ...{
                              5: const pw.FixedColumnWidth(66), // NET. AMT
                              6: const pw.FixedColumnWidth(40), // GST%
                            },
                            if (hasGst) 7: const pw.FixedColumnWidth(68) else 5: const pw.FixedColumnWidth(68), // GROSS AMT.
                          }
                        : {
                            0: const pw.FixedColumnWidth(28), // S.N.
                            1: const pw.FlexColumnWidth(3.5), // PARTICULAR
                            2: const pw.FixedColumnWidth(52), // QTY
                            3: const pw.FixedColumnWidth(52), // PRICE
                            if (hasGst) ...{
                              4: const pw.FixedColumnWidth(68), // NET. AMT
                              5: const pw.FixedColumnWidth(42), // GST%
                            },
                            if (hasGst) 6: const pw.FixedColumnWidth(70) else 4: const pw.FixedColumnWidth(70), // GROSS AMT.
                          },
                    children: [
                      // Table Headers
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.white),
                        children: [
                          _buildTh('S.N.', align: pw.TextAlign.center),
                          if (isPhotoMode) _buildTh('PHOTO', align: pw.TextAlign.center),
                          _buildTh('PARTICULAR', align: pw.TextAlign.left),
                          _buildTh('QTY', align: pw.TextAlign.center),
                          _buildTh('PRICE', align: pw.TextAlign.center),
                          if (hasGst) ...[
                            _buildTh('NET. AMT', align: pw.TextAlign.right),
                            _buildTh('GST%', align: pw.TextAlign.center),
                          ],
                          _buildTh(hasGst ? 'GROSS AMT.' : 'AMOUNT', align: pw.TextAlign.right),
                        ],
                      ),

                      // Table Rows
                      ...quotation.items.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final it = entry.value;
                        final img = (it.imageUrl != null) ? itemImages[it.imageUrl!] : null;

                        return pw.TableRow(
                          children: [
                            // S.N.
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                              alignment: pw.Alignment.center,
                              child: pw.Text('${idx + 1}', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                            ),

                            // PHOTO
                            if (isPhotoMode)
                              pw.Container(
                                padding: const pw.EdgeInsets.all(2),
                                alignment: pw.Alignment.center,
                                child: img != null
                                    ? pw.Container(
                                        width: 38,
                                        height: 38,
                                        child: pw.Image(img, fit: pw.BoxFit.contain),
                                      )
                                    : pw.Text('—', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500)),
                              ),

                            // PARTICULAR
                            pw.Container(
                              padding: const pw.EdgeInsets.fromLTRB(6, 4, 6, 4),
                              alignment: pw.Alignment.centerLeft,
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    it.name.toUpperCase(),
                                    style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                                  ),
                                  if (isMachinery && it.specification != null && it.specification!.isNotEmpty)
                                    pw.Text(
                                      it.specification!,
                                      style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800),
                                    ),
                                  if (isMachinery && it.size != null && it.size!.isNotEmpty)
                                    pw.Text(
                                      'Size: ${it.size}',
                                      style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                                    ),
                                  if (it.installationCharge > 0)
                                    pw.Text(
                                      '* Includes Fitting: $currSymbol${formatAmount(it.installationCharge)}',
                                      style: pw.TextStyle(fontSize: 7, color: PdfColor.fromHex('#0369A1')),
                                    ),
                                ],
                              ),
                            ),

                            // QTY
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                              alignment: pw.Alignment.center,
                              child: pw.Text(
                                '${it.quantity == it.quantity.roundToDouble() ? it.quantity.toInt() : it.quantity} ${it.unit}',
                                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                              ),
                            ),

                            // PRICE
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                              alignment: pw.Alignment.center,
                              child: pw.Text(
                                formatInteger(it.price),
                                style: const pw.TextStyle(fontSize: 8),
                              ),
                            ),

                            // NET. AMT
                            if (hasGst)
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                                alignment: pw.Alignment.centerRight,
                                child: pw.Text(
                                  formatAmount(it.netAmount),
                                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                                ),
                              ),

                            // GST%
                            if (hasGst)
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                                alignment: pw.Alignment.center,
                                child: pw.Text(
                                  '${it.gstRate.toInt()}%',
                                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                                ),
                              ),

                            // GROSS AMT
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                              alignment: pw.Alignment.centerRight,
                              child: pw.Text(
                                formatAmount(hasGst ? it.grossAmount : it.netAmount),
                                style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),

                  // ==============================================================
                  // 5-7. SUMMARY, CHARGES, TOTAL PAYABLE & FOOTER
                  // ==============================================================
                  pw.Container(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        left: pw.BorderSide(color: PdfColors.black, width: 2),
                        right: pw.BorderSide(color: PdfColors.black, width: 2),
                        bottom: pw.BorderSide(color: PdfColors.black, width: 2),
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: [
                  if (hasGst)
                    pw.Container(
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(color: PdfColors.black, width: 1.5),
                        ),
                      ),
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text('TOTAL NET AMT: ', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                          pw.Text('$currSymbol${formatAmount(quotation.totalNet)}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(width: 14),
                          pw.Text('GST: ', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                          pw.Text('+ $currSymbol${formatAmount(quotation.totalGst)}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#047857'))),
                        ],
                      ),
                    ),

                  // Additional charges rows (if any)
                  if (quotation.packingCharges > 0 || quotation.deliveryCharges > 0 || quotation.previousCharges > 0 || quotation.overallDiscount > 0)
                    pw.Container(
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1)),
                      ),
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          if (quotation.packingCharges > 0) ...[
                            pw.Text('${quotation.packingChargeLabel}: +$currSymbol${formatInteger(quotation.packingCharges)}   ', style: const pw.TextStyle(fontSize: 7.5)),
                          ],
                          if (quotation.deliveryCharges > 0) ...[
                            pw.Text('${quotation.deliveryChargeLabel}: +$currSymbol${formatInteger(quotation.deliveryCharges)}   ', style: const pw.TextStyle(fontSize: 7.5)),
                          ],
                          if (quotation.previousCharges > 0) ...[
                            pw.Text('${quotation.previousChargeLabel}: +$currSymbol${formatInteger(quotation.previousCharges)}   ', style: pw.TextStyle(fontSize: 7.5, color: PdfColor.fromHex('#B45309'))),
                          ],
                          if (quotation.overallDiscount > 0) ...[
                            pw.Text('DISCOUNT: -$currSymbol${formatAmount(quotation.overallDiscount)}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#DC2626'))),
                          ],
                        ],
                      ),
                    ),

                  // ==============================================================
                  // 6. TOTAL PAYABLE STRIP (Grey background + Final Amount)
                  // ==============================================================
                  pw.Container(
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#E2E8F0'),
                      border: const pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 2)),
                    ),
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              hasGst ? 'TOTAL PAYABLE (INCL. GST & ALL CHARGES)' : 'TOTAL PAYABLE (ALL CHARGES)',
                              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, letterSpacing: 0.3),
                            ),
                            pw.Text(
                              'All prices quoted are in Indian Rupees (INR)',
                              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                            ),
                          ],
                        ),
                        pw.Row(
                          children: [
                            pw.Text(
                              'FINAL AMOUNT   ',
                              style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, letterSpacing: 0.5),
                            ),
                            pw.Text(
                              '$currSymbol${formatAmount(quotation.finalAmount)}',
                              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ==============================================================
                  // 7. BOTTOM PITCH BLACK FOOTER (Terms on Left, Signatures on Right)
                  // ==============================================================
                  pw.Container(
                    color: PdfColors.black,
                    padding: const pw.EdgeInsets.fromLTRB(12, 8, 12, 10),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Left Notes
                        pw.Expanded(
                          flex: 62,
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('NOTE : 100% ADVANCE PAYMENT', style: pw.TextStyle(color: PdfColors.white, fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                              pw.Text('NOTE : DELIVERY : IN A WEEK', style: pw.TextStyle(color: PdfColors.white, fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                              pw.Text('NOTE : PAYMENT METHOD : IMPS / CHEQUE / CASH', style: pw.TextStyle(color: PdfColors.white, fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                              if (hasGst)
                                pw.Text('NOTE : GST - EXTRA AND AS MENTIONED', style: pw.TextStyle(color: PdfColors.white, fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                              pw.Text('OTHER CHARG - EXTRA', style: pw.TextStyle(color: PdfColor.fromHex('#EF4444'), fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                              pw.Text('FREIGHT - EXTRA', style: pw.TextStyle(color: PdfColor.fromHex('#EF4444'), fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                        ),

                        // Right Signatures
                        pw.Expanded(
                          flex: 38,
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              if (quotation.rateGivenBy != null && quotation.rateGivenBy!.isNotEmpty) ...[
                                pw.Text('RATE GIVEN BY:', style: const pw.TextStyle(color: PdfColors.grey400, fontSize: 6.5)),
                                pw.Text(quotation.rateGivenBy!.toLowerCase(), style: pw.TextStyle(color: PdfColors.white, fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                                pw.SizedBox(height: 2),
                              ],
                              if (quotation.preparedBy != null && quotation.preparedBy!.isNotEmpty) ...[
                                pw.Text('QUOTATION PREPARED BY:', style: const pw.TextStyle(color: PdfColors.grey400, fontSize: 6.5)),
                                pw.Text(quotation.preparedBy!.toLowerCase(), style: pw.TextStyle(color: PdfColors.white, fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                                pw.SizedBox(height: 6),
                              ],
                              pw.Text('FOR HOTEL WORLD', style: pw.TextStyle(color: PdfColors.white, fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                              pw.SizedBox(height: 1),
                              pw.Text('(Authorized Signatory)', style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 7)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildTh(String text, {pw.TextAlign align = pw.TextAlign.center}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 3),
      alignment: align == pw.TextAlign.center
          ? pw.Alignment.center
          : (align == pw.TextAlign.right ? pw.Alignment.centerRight : pw.Alignment.centerLeft),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
        textAlign: align,
      ),
    );
  }

  /// Print directly
  static Future<void> printQuotation({
    required Quotation quotation,
    required CompanySettings settings,
  }) async {
    final pdfBytes = await generateQuotationPdf(quotation: quotation, settings: settings);
    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: '${quotation.quotationNumber.replaceAll(RegExp(r'[/\\:]'), '_')}.pdf',
    );
  }

  /// Share PDF via WhatsApp or email
  static Future<void> shareQuotationPdf({
    required Quotation quotation,
    required CompanySettings settings,
  }) async {
    final pdfBytes = await generateQuotationPdf(quotation: quotation, settings: settings);
    final output = await getTemporaryDirectory();
    final cleanNum = quotation.quotationNumber.replaceAll(RegExp(r'[/\\:]'), '_');
    final file = File('${output.path}/Quotation_$cleanNum.pdf');
    await file.writeAsBytes(pdfBytes);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      text: 'Quotation ${quotation.quotationNumber} from Hotel World for ${quotation.customerName}',
      subject: 'Quotation ${quotation.quotationNumber} - Hotel World',
    );
  }
}
