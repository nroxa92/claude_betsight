import 'package:betsight/models/bankroll.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BankrollConfig.defaultConfig', () {
    test('totalBankroll 0, defaultStakeUnit 10, currency EUR', () {
      const c = BankrollConfig.defaultConfig;
      expect(c.totalBankroll, 0);
      expect(c.defaultStakeUnit, 10);
      expect(c.currency, 'EUR');
    });
  });

  group('BankrollConfig.stakeAsPercentage', () {
    test('zero bankroll → 0 (no division by zero)', () {
      const c = BankrollConfig(
        totalBankroll: 0,
        defaultStakeUnit: 10,
        currency: 'EUR',
      );
      expect(c.stakeAsPercentage, 0);
    });
    test('100 bankroll, 10 unit → 10%', () {
      const c = BankrollConfig(
        totalBankroll: 100,
        defaultStakeUnit: 10,
        currency: 'EUR',
      );
      expect(c.stakeAsPercentage, 10);
    });
    test('1000 bankroll, 25 unit → 2.5%', () {
      const c = BankrollConfig(
        totalBankroll: 1000,
        defaultStakeUnit: 25,
        currency: 'EUR',
      );
      expect(c.stakeAsPercentage, 2.5);
    });
  });

  group('BankrollConfig.toMap + fromMap roundtrip', () {
    test('roundtrips all fields', () {
      const original = BankrollConfig(
        totalBankroll: 500,
        defaultStakeUnit: 20,
        currency: 'USD',
      );
      final parsed = BankrollConfig.fromMap(original.toMap());
      expect(parsed.totalBankroll, 500);
      expect(parsed.defaultStakeUnit, 20);
      expect(parsed.currency, 'USD');
    });
    test('fromMap handles int values via num.toDouble', () {
      final parsed = BankrollConfig.fromMap({
        'totalBankroll': 200,
        'defaultStakeUnit': 5,
        'currency': 'EUR',
      });
      expect(parsed.totalBankroll, 200.0);
      expect(parsed.defaultStakeUnit, 5.0);
    });
  });
}
