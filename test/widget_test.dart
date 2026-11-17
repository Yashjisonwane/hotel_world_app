import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_world_app/models/quotation_item.dart';

void main() {
  test('QuotationItem isGstInclusive and serialization test', () {
    final item = QuotationItem(
      name: 'BANQUET CHAIR (INC GST)',
      price: 1650.0,
      quantity: 10,
      isGstInclusive: true,
    );

    expect(item.isGstInclusive, true);
    final json = item.toJson();
    expect(json['isGstInclusive'], true);

    final restored = QuotationItem.fromJson(json);
    expect(restored.isGstInclusive, true);

    // Test legacy detection from name
    final legacyItem = QuotationItem.fromJson({
      'name': 'STEAM IRON (INC GST)',
      'price': 1400.0,
      'quantity': 2,
    });
    expect(legacyItem.isGstInclusive, true);
  });
}
