import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sahaay_flutter/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('SahaayApp displays Login screen on cold start when unauthenticated',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SahaayApp());
    await tester.pump(const Duration(milliseconds: 300));

    // Check Login header and Role selection cards
    expect(find.text('Welcome to Sahaay'), findsOneWidget);
    expect(find.text('1. SELECT YOUR ACCOUNT TYPE'), findsOneWidget);
    expect(find.text('Senior Citizen\n(Victim)'), findsOneWidget);
    expect(find.text('Community\nResponder'), findsOneWidget);
    expect(find.text('Save session on this device'), findsOneWidget);
    expect(find.text('Sign In as Senior Resident'), findsOneWidget);
  });

  testWidgets('Victim can sign in and enter Elderly SOS Home Screen',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SahaayApp());
    await tester.pump(const Duration(milliseconds: 300));

    // Tap 1-tap quick demo button for Kamla Devi (Amma)
    final ammaBtn = find.text('Kamla Devi\n(Amma)');
    expect(ammaBtn, findsOneWidget);
    await tester.ensureVisible(ammaBtn);
    await tester.tap(ammaBtn);
    await tester.pump(const Duration(milliseconds: 300));

    // Should now be on ElderlyHomeScreen
    expect(find.text('SOS'), findsOneWidget);
    expect(find.text('Tap for emergency'), findsOneWidget);
    expect(find.text('Emergency Contacts'), findsOneWidget);
  });

  testWidgets('Responder can select responder role and sign in to Responder Dashboard',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SahaayApp());
    await tester.pump(const Duration(milliseconds: 300));

    // Tap Community Responder role card
    final responderCard = find.text('Community\nResponder');
    expect(responderCard, findsOneWidget);
    await tester.tap(responderCard);
    await tester.pump(const Duration(milliseconds: 100));

    // Primary action button should now reflect responder
    expect(find.text('Sign In as Community Responder'), findsOneWidget);

    // Tap Rahul Sharma quick demo button
    final rahulBtn = find.text('Rahul Sharma\n(Responder)');
    expect(rahulBtn, findsOneWidget);
    await tester.ensureVisible(rahulBtn);
    await tester.tap(rahulBtn);
    await tester.pump(const Duration(milliseconds: 300));

    // Should now be on ResponderHomeScreen
    expect(find.text('Responder Portal'), findsOneWidget);
    expect(find.text('VERIFIED (On-Chain)'), findsOneWidget);
    expect(find.text('Nearby Incidents (< 3 km)'), findsOneWidget);
  });
}
