import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:fieldpulse/main.dart' as app;

// Integration Test: Complete Job Flow
// Verifies login, fetching job list, and opening job details.
// Make sure backend is running and 'tech@fieldpulse.com' user exists.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Complete Job Flow E2E', () {
    testWidgets('Login → Job list loads → tap job to view details', (
      tester,
    ) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Login with test credentials
      // Find email and password fields
      final emailField = find.byType(TextField).first;
      final passwordField = find.byType(TextField).last;

      await tester.enterText(emailField, 'tech@fieldpulse.com');
      await tester.enterText(passwordField, 'Tech123!');
      await tester.pumpAndSettle();

      // Tap login button
      final loginButton = find.widgetWithText(ElevatedButton, 'Log In');
      if (loginButton.evaluate().isEmpty) {
        // Fallback: try finding any button with "Login" or "Sign In"
        final altButton = find.byType(ElevatedButton).first;
        await tester.tap(altButton);
      } else {
        await tester.tap(loginButton);
      }
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify Job List is displayed
      // We should now see the job list screen
      expect(find.text('My Jobs'), findsOneWidget);

      // Wait for jobs to load
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Find and tap the first job card
      final jobCards = find.byType(Card);
      expect(jobCards, findsWidgets);

      await tester.tap(jobCards.first);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      // Verify Job Detail Screen
      expect(find.byType(AppBar), findsOneWidget);

      // Look for Start Job or Complete Job button
      // final startButton = find.widgetWithText(ElevatedButton, 'Start Job');
      // final completeButton = find.widgetWithText(ElevatedButton, 'Complete Job');

      // if (startButton.evaluate().isNotEmpty) {
      //   // Job is pending → Start it
      //   await tester.tap(startButton);
      //   await tester.pumpAndSettle(const Duration(seconds: 3));
      // }

      // // Fill Checklist (if visible)
      // // Look for text input fields in the checklist
      // final textAreas = find.byType(TextFormField);
      // if (textAreas.evaluate().isNotEmpty) {
      //   // Fill in the first text field (likely "Work Performed")
      //   await tester.enterText(textAreas.first, 'Completed maintenance work');
      //   await tester.pumpAndSettle();
      // }

      // Look for checkbox fields
      // final checkboxes = find.byType(Checkbox);
      // if (checkboxes.evaluate().isNotEmpty) {
      //   // Check the first unchecked checkbox
      //   for (final checkbox in checkboxes.evaluate()) {
      //     final widget = checkbox.widget as Checkbox;
      //     if (widget.value != true) {
      //       await tester.tap(find.byWidget(widget));
      //       await tester.pumpAndSettle();
      //       break;
      //     }
      //   }
      // }

      // Save Draft
      // final saveDraftButton = find.widgetWithText(OutlinedButton, 'Save Draft');
      // if (saveDraftButton.evaluate().isNotEmpty) {
      //   await tester.tap(saveDraftButton);
      //   await tester.pumpAndSettle(const Duration(seconds: 2));
      // }

      // // Submit Checklist
      // final submitButton = find.widgetWithText(ElevatedButton, 'Submit');
      // if (submitButton.evaluate().isNotEmpty) {
      //   await tester.tap(submitButton);
      //   await tester.pumpAndSettle(const Duration(seconds: 3));
      // }

      // Complete Job
      // if (completeButton.evaluate().isNotEmpty) {
      //   await tester.tap(completeButton);
      //   await tester.pumpAndSettle(const Duration(seconds: 3));
      // }

      // Verify: Should see a success snackbar or status change
      // (Check for either the snackbar text or the updated status in UI)
      // final completedOrInProgress =
      //     find.text('Completed').evaluate().isNotEmpty ||
      //     find.text('In Progress').evaluate().isNotEmpty ||
      //     find.text('Status updated').evaluate().isNotEmpty;
      // expect(completedOrInProgress, isTrue);
    });
  });
}
