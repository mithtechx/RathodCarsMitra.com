import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rc_mitra_mobile/src/app.dart';

void main() {
  testWidgets('RC Mitra app smoke test', (WidgetTester tester) async {
    // Replace RCMitraApp with whatever class name is exported in your src/app.dart (e.g., App, RCMitraApp)
    await tester.pumpWidget(const RCMitraApp());
    expect(find.byType(MaterialApp), findsWidgets);
  });
}