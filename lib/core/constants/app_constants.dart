class AppConstants {
  static const String defaultCurrency = 'USD';
  static const String defaultCurrencySymbol = '\$';
  static const String appName = 'CashPilot';
  static const String tagline = 'Smart Wallet. Better Life.';
  // Keep in sync with `version:` in pubspec.yaml.
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';

  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 350);
  static const Duration animSlow = Duration(milliseconds: 600);

  static const String dateFormat = 'dd MMM yyyy';
  static const String monthYearFormat = 'MMM yyyy';
  static const String timeFormat = 'hh:mm a';

  static const List<Map<String, String>> currencies = [
    {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
    {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
    {'code': 'JPY', 'symbol': '¥', 'name': 'Japanese Yen'},
    {'code': 'INR', 'symbol': '₹', 'name': 'Indian Rupee'},
    {'code': 'BDT', 'symbol': '৳', 'name': 'Bangladeshi Taka'},
    {'code': 'CNY', 'symbol': '¥', 'name': 'Chinese Yuan'},
    {'code': 'AUD', 'symbol': 'A\$', 'name': 'Australian Dollar'},
    {'code': 'CAD', 'symbol': 'C\$', 'name': 'Canadian Dollar'},
    {'code': 'CHF', 'symbol': 'Fr', 'name': 'Swiss Franc'},
    {'code': 'SGD', 'symbol': 'S\$', 'name': 'Singapore Dollar'},
    {'code': 'HKD', 'symbol': 'HK\$', 'name': 'Hong Kong Dollar'},
    {'code': 'MYR', 'symbol': 'RM', 'name': 'Malaysian Ringgit'},
    {'code': 'THB', 'symbol': '฿', 'name': 'Thai Baht'},
    {'code': 'IDR', 'symbol': 'Rp', 'name': 'Indonesian Rupiah'},
    {'code': 'PKR', 'symbol': '₨', 'name': 'Pakistani Rupee'},
    {'code': 'AED', 'symbol': 'د.إ', 'name': 'UAE Dirham'},
    {'code': 'SAR', 'symbol': '﷼', 'name': 'Saudi Riyal'},
    {'code': 'KRW', 'symbol': '₩', 'name': 'South Korean Won'},
    {'code': 'BRL', 'symbol': 'R\$', 'name': 'Brazilian Real'},
    {'code': 'MXN', 'symbol': 'Mex\$', 'name': 'Mexican Peso'},
    {'code': 'ZAR', 'symbol': 'R', 'name': 'South African Rand'},
    {'code': 'NGN', 'symbol': '₦', 'name': 'Nigerian Naira'},
    {'code': 'EGP', 'symbol': 'E£', 'name': 'Egyptian Pound'},
    {'code': 'TRY', 'symbol': '₺', 'name': 'Turkish Lira'},
    {'code': 'RUB', 'symbol': '₽', 'name': 'Russian Ruble'},
    {'code': 'SEK', 'symbol': 'kr', 'name': 'Swedish Krona'},
    {'code': 'NOK', 'symbol': 'kr', 'name': 'Norwegian Krone'},
    {'code': 'DKK', 'symbol': 'kr', 'name': 'Danish Krone'},
    {'code': 'PLN', 'symbol': 'zł', 'name': 'Polish Zloty'},
  ];
}
