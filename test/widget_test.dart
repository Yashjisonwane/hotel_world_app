import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_world_app/main.dart';

void main() {
  testWidgets('Hotel World App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HotelWorldApp());
  });
}
