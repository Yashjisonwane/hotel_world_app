import '../models/quotation_item.dart';

/// Intelligent multi-platform paste helper for Hotel World Quotation Management App.
/// Parses multi-line text from WhatsApp, Google Keep, Notes, Excel, Google Sheets, or CSV.
/// Auto-extracts:
/// - Product Name
/// - Quantity
/// - Unit (Pcs, Dzn, Kg, Box, Pkt, Set, etc.)
/// - Price / Rate
/// - Specification & Size (in Machinery mode or when present)
class PasteHelper {
  /// Checks whether raw text contains multiple rows or columns
  static bool isMultiRow(String? text) {
    if (text == null || text.trim().isEmpty) return false;
    final clean = text.trim();
    if (clean.contains('\n') || clean.contains('\r')) return true;
    if (clean.contains('\t')) return true;
    if (clean.contains('|')) return true;
    if (clean.contains(',') && RegExp(r'\d+').hasMatch(clean)) return true;
    return false;
  }

  /// Parses pasted multi-line text into a list of QuotationItem objects
  static List<QuotationItem> parsePastedText(
    String rawText, {
    required String gstMode,
    required bool isMachinery,
    String? defaultSection,
  }) {
    if (rawText.trim().isEmpty) return [];

    final rawLines = rawText.split(RegExp(r'\r?\n'));
    final List<QuotationItem> results = [];
    String currentSection = defaultSection ?? (isMachinery ? 'EQUIPMENT SECTION' : 'GENERAL SECTION');

    for (var rawLine in rawLines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      // Skip obvious header rows
      final lower = line.toLowerCase();
      if (lower.startsWith('s.n') ||
          lower.startsWith('sn\t') ||
          lower == 'particular' ||
          lower.startsWith('particular\t') ||
          lower.startsWith('item name') ||
          lower.startsWith('total amount') ||
          lower.startsWith('final amount')) {
        continue;
      }

      // Check if line represents a section header (e.g. "TANDOOR SECTION", "INDIAN SECTION")
      if (isMachinery && _isSectionHeader(line)) {
        currentSection = _cleanSectionName(line);
        continue;
      }

      // Parse individual line
      final item = _parseSingleLine(
        line,
        gstMode: gstMode,
        isMachinery: isMachinery,
        section: currentSection,
        serialNumber: results.length + 1,
      );

      if (item != null && item.name.isNotEmpty) {
        results.add(item);
      }
    }

    return results;
  }

  static bool _isSectionHeader(String line) {
    final lower = line.toLowerCase().trim();
    if (RegExp(r'\b(section|area|room|pantry|washing|exhaust|storage|counter|bakery|kitchen)\b').hasMatch(lower)) {
      // Must not have numeric price or qty columns
      final hasPrice = RegExp(r'₹|\b\d{3,}\b').hasMatch(line);
      return !hasPrice;
    }
    return false;
  }

  static String _cleanSectionName(String line) {
    return line.replaceAll(RegExp(r'[:\-–—\t]+$'), '').trim().toUpperCase();
  }

  static QuotationItem? _parseSingleLine(
    String rawLine, {
    required String gstMode,
    required bool isMachinery,
    required String section,
    required int serialNumber,
  }) {
    final line = rawLine.trim();
    if (line.isEmpty) return null;

    // 1. Tab-separated line (Excel / Google Sheets)
    if (line.contains('\t')) {
      final cols = line.split('\t').map((c) => c.trim()).toList();
      return _parseColumns(cols, gstMode: gstMode, isMachinery: isMachinery, section: section, serialNumber: serialNumber);
    }

    // 2. Comma or Pipe separated line
    if (line.contains('|') || (line.contains(',') && line.split(',').length >= 3)) {
      final delim = line.contains('|') ? '|' : ',';
      final cols = line.split(delim).map((c) => c.trim()).toList();
      return _parseColumns(cols, gstMode: gstMode, isMachinery: isMachinery, section: section, serialNumber: serialNumber);
    }

    // 3. Plain text / WhatsApp list format
    // E.g.: "1. Kadchi 2 pcs @ 150" or "Kadai 2 pcs" or "3. Fry Pan - 450/-"
    return _parseWhatsAppLine(line, gstMode: gstMode, isMachinery: isMachinery, section: section, serialNumber: serialNumber);
  }

  static QuotationItem? _parseColumns(
    List<String> rawCols, {
    required String gstMode,
    required bool isMachinery,
    required String section,
    required int serialNumber,
  }) {
    final cols = rawCols.where((c) => c.isNotEmpty).toList();
    if (cols.isEmpty) return null;

    int offset = 0;
    // Skip S.No if first col is pure integer and there are 3+ cols
    if (cols.length >= 3 && RegExp(r'^\d+$').hasMatch(cols[0])) {
      offset = 1;
    }

    if (offset >= cols.length) return null;

    final name = _cleanProductName(cols[offset]);
    if (name.isEmpty) return null;

    String? spec;
    String? size;
    double qty = 1.0;
    String unit = 'Pcs';
    double price = 0.0;
    double gstRate = (gstMode == 'WITH_GST') ? 18.0 : 0.0;

    if (isMachinery && cols.length >= offset + 3) {
      spec = cols[offset + 1];
      size = cols[offset + 2];
      final remaining = cols.sublist(offset + 3);

      for (var col in remaining) {
        final colClean = col.trim();
        if (colClean.contains('%')) {
          final gstMatch = RegExp(r'(\d+)\s*%').firstMatch(colClean);
          if (gstMatch != null) {
            gstRate = double.tryParse(gstMatch.group(1)!) ?? 18.0;
          }
        } else {
          final num = double.tryParse(colClean.replaceAll(RegExp(r'[^\d.]'), ''));
          if (num != null && num > 0) {
            if (qty == 1.0 && num <= 100 && price == 0.0 && remaining.indexOf(col) == 0) {
              qty = num;
            } else if (price == 0.0) {
              price = num;
            }
          }
        }
      }
    } else {
      // Standard Columns
      final remaining = cols.sublist(offset + 1);
      for (var col in remaining) {
        final colClean = col.trim();
        final unitFound = _extractUnit(colClean);
        if (unitFound != null) {
          unit = unitFound;
        }

        final num = double.tryParse(colClean.replaceAll(RegExp(r'[^\d.]'), ''));
        if (num != null && num > 0) {
          if (qty == 1.0 && price == 0.0 && (colClean.toLowerCase().contains('pc') || num <= 50)) {
            qty = num;
          } else if (price == 0.0) {
            price = num;
          }
        }
      }
    }

    final item = QuotationItem(
      serialNumber: serialNumber,
      name: name,
      section: isMachinery ? section : null,
      specification: spec,
      size: size,
      quantity: qty,
      unit: unit,
      price: price,
      gstRate: gstRate,
      isGstAdded: gstMode == 'WITH_GST',
    );
    item.recalculate();
    return item;
  }

  static QuotationItem? _parseWhatsAppLine(
    String rawLine, {
    required String gstMode,
    required bool isMachinery,
    required String section,
    required int serialNumber,
  }) {
    var line = rawLine.trim();

    // Remove leading numbering like "1.", "1)", "1 -", "-", "*"
    line = line.replaceFirst(RegExp(r'^(\d+[\.\)\-:]\s*|[\*\-•–—]\s*)'), '').trim();
    if (line.isEmpty) return null;

    double qty = 1.0;
    String unit = 'Pcs';
    double price = 0.0;

    // Check for rate / price at the end e.g. "@ 350", "Rs 350", "350/-", "= 350"
    final rateMatch = RegExp(r'[@=:–—\-]\s*(?:rs\.?|inr|₹)?\s*(\d+(?:\.\d{1,2})?)\s*(?:\/-)?$', caseSensitive: false).firstMatch(line);
    if (rateMatch != null) {
      price = double.tryParse(rateMatch.group(1)!) ?? 0.0;
      line = line.substring(0, rateMatch.start).trim();
    } else {
      final trailingPriceMatch = RegExp(r'(?:rs\.?|inr|₹)\s*(\d+(?:\.\d{1,2})?)\s*(?:\/-)?$', caseSensitive: false).firstMatch(line);
      if (trailingPriceMatch != null) {
        price = double.tryParse(trailingPriceMatch.group(1)!) ?? 0.0;
        line = line.substring(0, trailingPriceMatch.start).trim();
      }
    }

    // Check for quantity & unit e.g. "2 pcs", "10 dzn", "5 kg", "20 nos"
    final qtyUnitMatch = RegExp(r'\b(\d+(?:\.\d{1,2})?)\s*(pcs|pc|dzn|dozen|kg|kilo|box|pkt|packet|set|nos|mtr|ltr)\b', caseSensitive: false).firstMatch(line);
    if (qtyUnitMatch != null) {
      qty = double.tryParse(qtyUnitMatch.group(1)!) ?? 1.0;
      final u = qtyUnitMatch.group(2)!.toLowerCase();
      unit = _normalizeUnit(u);
      line = line.replaceRange(qtyUnitMatch.start, qtyUnitMatch.end, '').trim();
    }

    // If price is still 0, check for trailing numeric price (e.g. "Test Plate 10 pcs 1200" or "Kadai 450")
    if (price == 0.0) {
      final trailingNum = RegExp(r'[\s\-–—:]+(\d+(?:\.\d{1,2})?)\s*(?:\/-)?$').firstMatch(line);
      if (trailingNum != null) {
        final pVal = double.tryParse(trailingNum.group(1)!) ?? 0.0;
        if (pVal > 0) {
          price = pVal;
          line = line.substring(0, trailingNum.start).trim();
        }
      }
    }

    // If quantity is still default 1, check for trailing number as quantity (e.g. "Kadai 5")
    if (qty == 1.0) {
      final trailingQtyMatch = RegExp(r'[\-–—:\s]+(\d+)\s*$').firstMatch(line);
      if (trailingQtyMatch != null) {
        final parsed = double.tryParse(trailingQtyMatch.group(1)!);
        if (parsed != null && parsed <= 500) {
          qty = parsed;
          line = line.substring(0, trailingQtyMatch.start).trim();
        }
      }
    }

    // Clean remaining text as product name
    final name = _cleanProductName(line);
    if (name.isEmpty) return null;

    final item = QuotationItem(
      serialNumber: serialNumber,
      name: name,
      section: isMachinery ? section : null,
      quantity: qty,
      unit: unit,
      price: price,
      gstRate: (gstMode == 'WITH_GST') ? 18.0 : 0.0,
      isGstAdded: gstMode == 'WITH_GST',
    );
    item.recalculate();
    return item;
  }

  static String? _extractUnit(String text) {
    final m = RegExp(r'\b(pcs|pc|dzn|dozen|kg|kilo|box|pkt|packet|set|nos|mtr|ltr)\b', caseSensitive: false).firstMatch(text);
    if (m != null) {
      return _normalizeUnit(m.group(1)!);
    }
    return null;
  }

  static String _normalizeUnit(String raw) {
    final lower = raw.toLowerCase();
    if (lower == 'dzn' || lower == 'dozen') return 'Dzn';
    if (lower == 'kg' || lower == 'kilo') return 'Kg';
    if (lower == 'box') return 'Box';
    if (lower == 'pkt' || lower == 'packet') return 'Pkt';
    if (lower == 'set') return 'Set';
    if (lower == 'nos') return 'Nos';
    if (lower == 'mtr') return 'Mtr';
    if (lower == 'ltr') return 'Ltr';
    return 'Pcs';
  }

  static String _cleanProductName(String raw) {
    return raw
        .replaceAll(RegExp(r'^[\s\-–—:,]+|[\s\-–—:,]+$'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
