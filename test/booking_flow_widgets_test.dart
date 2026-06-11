import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:binlink_mobile/features/household/components/service_selection_sheet.dart';
import 'package:binlink_mobile/features/household/components/address_selection_sheet.dart';

void main() {
  setUpAll(() {
    // No network in tests — fall back to bundled fonts silently
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget host(Widget sheet) => MaterialApp(
        home: Scaffold(
          body: Align(alignment: Alignment.bottomCenter, child: sheet),
        ),
      );

  group('Booking flow sheets (the "select screen" crash path)', () {
    testWidgets('ServiceSelectionSheet builds, selects category/size/bags and confirms',
        (tester) async {
      String? confirmedCategory;
      String? confirmedSize;
      int? confirmedBags;

      await tester.pumpWidget(host(ServiceSelectionSheet(
        onServiceSelected: (c, s, b) {
          confirmedCategory = c;
          confirmedSize = s;
          confirmedBags = b;
        },
        onCancel: () {},
      )));
      await tester.pumpAndSettle();

      expect(find.text('Select Service'), findsOneWidget);

      // Switch category and size
      await tester.tap(find.text('Organic'));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.tap(find.text('Family Bin'));
      await tester.pump(const Duration(milliseconds: 250));

      // Scroll the extra-bags row into view, then add 2 bags via "+"
      await tester.ensureVisible(find.text('Extra Bags'));
      await tester.pumpAndSettle();
      final plusBtn = find.byWidgetPredicate(
          (w) => w is Icon && w.color == Colors.white && w.size == 20);
      await tester.tap(plusBtn.last);
      await tester.pump();
      await tester.tap(plusBtn.last);
      await tester.pump();

      await tester.tap(find.textContaining('Confirm'));
      await tester.pump();

      expect(confirmedCategory, 'Organic');
      expect(confirmedSize, 'MEDIUM');
      expect(confirmedBags, 2);
    });

    testWidgets('ServiceSelectionSheet honours preselected category', (tester) async {
      await tester.pumpWidget(host(ServiceSelectionSheet(
        initialCategory: 'Plastic',
        onServiceSelected: (_, __, ___) {},
        onCancel: () {},
      )));
      await tester.pumpAndSettle();
      expect(find.text('Confirm Plastic'), findsOneWidget);
    });

    testWidgets('AddressSelectionSheet builds and confirms edited address',
        (tester) async {
      String? confirmed;
      await tester.pumpWidget(host(AddressSelectionSheet(
        currentAddress: 'Osu, Accra',
        onAddressConfirmed: (a) => confirmed = a,
        onCancel: () {},
      )));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Pickup Location'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Labone Crescent, Accra');
      await tester.tap(find.text('Confirm Address'));
      await tester.pump();

      expect(confirmed, 'Labone Crescent, Accra');
    });
  });
}
