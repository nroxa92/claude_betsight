class BankrollConfig {
  final double totalBankroll;
  final double defaultStakeUnit;
  final String currency;

  const BankrollConfig({
    required this.totalBankroll,
    required this.defaultStakeUnit,
    required this.currency,
  });

  static const defaultConfig = BankrollConfig(
    totalBankroll: 0,
    defaultStakeUnit: 10,
    currency: 'EUR',
  );

  double get stakeAsPercentage =>
      totalBankroll == 0 ? 0 : (defaultStakeUnit / totalBankroll) * 100;

  Map<String, dynamic> toMap() => {
        'totalBankroll': totalBankroll,
        'defaultStakeUnit': defaultStakeUnit,
        'currency': currency,
      };

  factory BankrollConfig.fromMap(Map<dynamic, dynamic> map) => BankrollConfig(
        totalBankroll: (map['totalBankroll'] as num).toDouble(),
        defaultStakeUnit: (map['defaultStakeUnit'] as num).toDouble(),
        currency: map['currency'] as String,
      );
}
