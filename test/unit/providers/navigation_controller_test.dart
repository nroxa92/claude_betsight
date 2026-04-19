import 'package:betsight/models/navigation_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NavigationController', () {
    test('initial currentIndex is 0', () {
      final c = NavigationController();
      expect(c.currentIndex, 0);
    });

    test('setTab changes currentIndex and notifies', () {
      final c = NavigationController();
      var notified = 0;
      c.addListener(() => notified++);

      c.setTab(2);
      expect(c.currentIndex, 2);
      expect(notified, 1);
    });

    test('setTab with same index does not notify', () {
      final c = NavigationController();
      c.setTab(1);
      var notified = 0;
      c.addListener(() => notified++);

      c.setTab(1);
      expect(notified, 0);
    });

    test('multiple tab switches notify each time', () {
      final c = NavigationController();
      var notified = 0;
      c.addListener(() => notified++);

      c.setTab(1);
      c.setTab(2);
      c.setTab(0);
      expect(notified, 3);
      expect(c.currentIndex, 0);
    });
  });
}
