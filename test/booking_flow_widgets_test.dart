import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:binlink_mobile/core/design_system/household_design_system.dart';

void main() {
  testWidgets('Household button and icon system render from BinLink assets', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: HButton(
            label: 'Request now',
            icon: 'pickup',
            onPressed: () => tapped = true,
          ),
        ),
      ),
    ));

    expect(find.text('Request now'), findsOneWidget);
    await tester.tap(find.text('Request now'));
    expect(tapped, isTrue);
  });
}
