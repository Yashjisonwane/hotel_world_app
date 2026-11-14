import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_world_app/services/pricing_engine.dart';
import 'package:hotel_world_app/models/quotation_item.dart';

void main() {
  group('Hotel World Master Pricing Rules Tests', () {
    test('Rule 1: Code-Based Calculation', () {
      // Code 75846 * 30 = 2275380, + 15% margin = 2616687
      final res = PricingEngine.calculateRule1(
        code: 'HW-M-75846',
        multiplier: 30,
        marginRate: 15,
      );

      expect(res['isValid'], true);
      expect(res['codeNumber'], 75846.0);
      expect(res['buyingPrice'], 2275380.0);
      expect(res['sellingPrice'], 2616687.0);
    });

    test('Rule 2: MRP-Based Calculation', () {
      // MRP 1000 - 50% = 500 Buying, MRP 1000 - 10% = 900 Selling
      final res = PricingEngine.calculateRule2(
        mrp: 1000.0,
        buyingDiscount: 50,
        sellingDiscount: 10,
      );

      expect(res['isValid'], true);
      expect(res['buyingPrice'], 500.0);
      expect(res['sellingPrice'], 900.0);
    });

    test('Rule 3: Company-Based Calculation', () {
      // MRP 1000 - 50% = 500, + 5% GST = 525, + 6% Frt = 556.50, + 15% Margin = 639.98
      final res = PricingEngine.calculateRule3(
        mrp: 1000.0,
        companyDiscount: 50,
        gstRate: 5,
        freightRate: 6,
        marginRate: 15,
      );

      expect(res['isValid'], true);
      expect(res['buyingPrice'], 556.50);
      expect(res['sellingPrice'], 639.98);
    });

    test('Quotation Row Math: With GST vs Without GST', () {
      final item = QuotationItem(
        name: 'Tandoor Standard',
        quantity: 2,
        price: 15000,
        gstRate: 18,
        isGstAdded: true,
        installationCharge: 500,
      );
      item.recalculate();

      // Net = 2 * 15000 = 30000
      // GST = 30000 * 18% = 5400
      // Gross = 30000 + 5400 + 500 = 35900
      expect(item.netAmount, 30000.0);
      expect(item.gstAmount, 5400.0);
      expect(item.grossAmount, 35900.0);

      // Now toggle without GST (isGstAdded = false)
      item.recalculate(overrideGstAdded: false);
      expect(item.netAmount, 30000.0);
      expect(item.gstAmount, 0.0);
      expect(item.grossAmount, 30500.0); // 30000 + 500 inst
    });
  });
}

