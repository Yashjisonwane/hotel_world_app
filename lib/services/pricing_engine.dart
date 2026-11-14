import 'package:intl/intl.dart';

class PricingEngine {
  static final NumberFormat indianCurrency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹ ',
    decimalDigits: 2,
  );

  static String formatCurrency(double amount) {
    return indianCurrency.format(amount);
  }

  static double round(double val) {
    return (val * 100).roundToDouble() / 100.0;
  }

  /// Extracts number from item code string (e.g. "HW-M-75846" -> 75846)
  static double? extractCodeNumber(String? code) {
    if (code == null || code.trim().isEmpty) return null;
    final clean = code.trim();
    final direct = double.tryParse(clean);
    if (direct != null && direct > 0) return direct;

    final reg = RegExp(r'\b\d+(\.\d+)?\b');
    final match = reg.firstMatch(clean);
    if (match != null) {
      return double.tryParse(match.group(0)!);
    }
    return null;
  }

  /// Rule 1: Code-Based Calculation
  /// Buying Price = CodeNumber * Multiplier (default 30)
  /// Selling Price = Buying Price * (1 + Margin% / 100) (default 15%)
  static Map<String, dynamic> calculateRule1({
    required String? code,
    double multiplier = 30.0,
    double marginRate = 15.0,
  }) {
    final codeNum = extractCodeNumber(code);
    if (codeNum == null || codeNum <= 0) {
      return {
        'isValid': false,
        'error': 'Missing or non-numeric item code',
        'buyingPrice': 0.0,
        'sellingPrice': 0.0,
      };
    }

    final buyingPrice = round(codeNum * multiplier);
    final sellingPrice = round(buyingPrice * (1 + marginRate / 100));

    return {
      'isValid': true,
      'codeNumber': codeNum,
      'multiplier': multiplier,
      'marginRate': marginRate,
      'buyingPrice': buyingPrice,
      'sellingPrice': sellingPrice,
      'summary': 'Code ($codeNum) × $multiplier = ₹$buyingPrice | +$marginRate% Margin = ₹$sellingPrice',
    };
  }

  /// Rule 2: MRP-Based Calculation
  /// Buying Price = MRP - BuyingDiscount% (default 50%)
  /// Selling Price = MRP - SellingDiscount% (default 10%)
  static Map<String, dynamic> calculateRule2({
    required double mrp,
    double buyingDiscount = 50.0,
    double sellingDiscount = 10.0,
  }) {
    if (mrp <= 0) {
      return {
        'isValid': false,
        'error': 'Missing or zero MRP',
        'buyingPrice': 0.0,
        'sellingPrice': 0.0,
      };
    }

    final buyingPrice = round(mrp * (1 - buyingDiscount / 100));
    final sellingPrice = round(mrp * (1 - sellingDiscount / 100));

    return {
      'isValid': true,
      'mrp': mrp,
      'buyingDiscount': buyingDiscount,
      'sellingDiscount': sellingDiscount,
      'buyingPrice': buyingPrice,
      'sellingPrice': sellingPrice,
      'summary': 'MRP (₹$mrp) − $buyingDiscount% = ₹$buyingPrice | MRP − $sellingDiscount% = ₹$sellingPrice',
    };
  }

  /// Rule 3: Company-Based Calculation
  /// 1. Discounted Base = MRP - CompanyDiscount% (default 50%)
  /// 2. With GST = Base + GST% (default 5%)
  /// 3. Buying Price = With GST + Freight% (default 6%)
  /// 4. Selling Price = Buying Price + Margin% (default 15%)
  static Map<String, dynamic> calculateRule3({
    required double mrp,
    double companyDiscount = 50.0,
    double gstRate = 5.0,
    double freightRate = 6.0,
    double marginRate = 15.0,
  }) {
    if (mrp <= 0) {
      return {
        'isValid': false,
        'error': 'Missing or zero MRP',
        'buyingPrice': 0.0,
        'sellingPrice': 0.0,
      };
    }

    final discountedBase = mrp * (1 - companyDiscount / 100);
    final withGstRaw = discountedBase * (1 + gstRate / 100);
    final buyingPriceRaw = withGstRaw * (1 + freightRate / 100);
    final buyingPrice = round(buyingPriceRaw);
    final marginAmount = round(buyingPrice * (marginRate / 100));
    final sellingPrice = round(buyingPrice + marginAmount);

    return {
      'isValid': true,
      'mrp': mrp,
      'companyDiscount': companyDiscount,
      'gstRate': gstRate,
      'freightRate': freightRate,
      'marginRate': marginRate,
      'buyingPrice': buyingPrice,
      'sellingPrice': sellingPrice,
      'summary': 'MRP ₹$mrp − $companyDiscount% + $gstRate% GST + $freightRate% Frt = ₹$buyingPrice | +$marginRate% = ₹$sellingPrice',
    };
  }

  /// Rule 4: Custom Flexible Formula
  /// Buying Price = (Base * Multiplier) * (1 - Discount% / 100)
  /// Selling Price = Buying Price * (1 + Margin% / 100)
  static Map<String, dynamic> calculateRule4({
    required double baseValue,
    double multiplier = 1.0,
    double discountRate = 0.0,
    double marginRate = 0.0,
  }) {
    final multiplied = round(baseValue * multiplier);
    final buyingPrice = round(multiplied * (1 - discountRate / 100));
    final sellingPrice = round(buyingPrice * (1 + marginRate / 100));

    return {
      'isValid': true,
      'baseValue': baseValue,
      'multiplier': multiplier,
      'discountRate': discountRate,
      'marginRate': marginRate,
      'buyingPrice': buyingPrice,
      'sellingPrice': sellingPrice,
      'summary': 'Base ₹$baseValue × $multiplier − $discountRate% + $marginRate% = ₹$sellingPrice',
    };
  }
}
