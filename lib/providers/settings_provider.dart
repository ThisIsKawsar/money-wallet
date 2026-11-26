import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cashpilot/data/models/reminder_model.dart';
import 'package:cashpilot/data/database/database_helper.dart';
import 'package:cashpilot/core/theme/app_colors.dart';
import 'package:uuid/uuid.dart';

class SettingsProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  static const _uuid = Uuid();

  static const _kThemeMode = 'themeMode';
  static const _kCurrency = 'currency';
  static const _kCurrencySymbol = 'currencySymbol';
  static const _kDecimalPlaces = 'decimalPlaces';
  static const _kPasscodeEnabled = 'passcodeEnabled';
  static const _kPasscodeHash = 'passcodeHash';
  static const _kUserName = 'userName';
  static const _kFilterPeriod = 'filterPeriod';
  static const _kHasSeenOnboarding = 'hasSeenOnboarding';
  static const _kBalanceHidden = 'balanceHidden';
  static const _kAccentIndex = 'accentIndex';
  static const _kDevMode = 'developerMode';
  static const _kShowTotal = 'showTotal';
  static const _kCarryOver = 'carryOver';

  ThemeMode _themeMode = ThemeMode.light;
  String _currency = 'USD';
  String _currencySymbol = '\$';
  int _decimalPlaces = 2;
  bool _passcodeEnabled = false;
  String? _passcodeHash;
  String _userName = 'User';
  String _filterPeriod = 'monthly';
  bool _hasSeenOnboarding = false;
  bool _balanceHidden = false;
  int _accentIndex = 0;
  bool _developerMode = false;
  bool _showTotal = true;
  bool _carryOver = false;

  static const List<Color> accentPalette = [
    Color(0xFF10A352), // Green
    Color(0xFF2F80ED), // Blue
    Color(0xFF8E44AD), // Purple
    Color(0xFFF39C12), // Orange
    Color(0xFFE74C3C), // Red
    Color(0xFF00B8A9), // Teal
  ];

  static const List<String> accentNames = [
    'Green',
    'Blue',
    'Purple',
    'Orange',
    'Red',
    'Teal',
  ];

  List<ReminderModel> _reminders = [];

  ThemeMode get themeMode => _themeMode;
  String get currency => _currency;
  String get currencySymbol => _currencySymbol;
  int get decimalPlaces => _decimalPlaces;
  bool get passcodeEnabled => _passcodeEnabled;
  String? get passcodeHash => _passcodeHash;
  String get userName => _userName;
  String get filterPeriod => _filterPeriod;
  bool get hasSeenOnboarding => _hasSeenOnboarding;
  bool get balanceHidden => _balanceHidden;
  int get accentIndex => _accentIndex;
  bool get showTotal => _showTotal;
  bool get carryOver => _carryOver;
  Color get accentColor => accentPalette[_accentIndex.clamp(0, accentPalette.length - 1)];
  String get accentName => accentNames[_accentIndex.clamp(0, accentNames.length - 1)];
  bool get developerMode => _developerMode;
  List<ReminderModel> get reminders => List.unmodifiable(_reminders);

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString(_kThemeMode) ?? 'light';
    _themeMode = themeName == 'light'
        ? ThemeMode.light
        : themeName == 'system'
            ? ThemeMode.system
            : ThemeMode.dark;
    _currency = prefs.getString(_kCurrency) ?? 'USD';
    _currencySymbol = prefs.getString(_kCurrencySymbol) ?? '\$';
    _decimalPlaces = prefs.getInt(_kDecimalPlaces) ?? 2;
    _passcodeEnabled = prefs.getBool(_kPasscodeEnabled) ?? false;
    _passcodeHash = prefs.getString(_kPasscodeHash);
    _userName = prefs.getString(_kUserName) ?? 'User';
    _filterPeriod = prefs.getString(_kFilterPeriod) ?? 'monthly';
    _hasSeenOnboarding = prefs.getBool(_kHasSeenOnboarding) ?? false;
    _balanceHidden = prefs.getBool(_kBalanceHidden) ?? false;
    _accentIndex = prefs.getInt(_kAccentIndex) ?? 0;
    AppColors.setBrand(accentColor);
    _developerMode = prefs.getBool(_kDevMode) ?? false;
    _showTotal = prefs.getBool(_kShowTotal) ?? true;
    _carryOver = prefs.getBool(_kCarryOver) ?? false;
    _reminders = await _db.getReminders();
    notifyListeners();
  }

  Future<void> setDisplayOptions({
    String? viewMode,
    bool? showTotal,
    bool? carryOver,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (viewMode != null) {
      _filterPeriod = viewMode;
      await prefs.setString(_kFilterPeriod, viewMode);
    }
    if (showTotal != null) {
      _showTotal = showTotal;
      await prefs.setBool(_kShowTotal, showTotal);
    }
    if (carryOver != null) {
      _carryOver = carryOver;
      await prefs.setBool(_kCarryOver, carryOver);
    }
    notifyListeners();
  }

  Future<void> setAppearance(ThemeMode mode, int accentIdx) async {
    _themeMode = mode;
    _accentIndex = accentIdx.clamp(0, accentPalette.length - 1);
    AppColors.setBrand(accentColor);
    final prefs = await SharedPreferences.getInstance();
    final name = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.system
            ? 'system'
            : 'dark';
    await prefs.setString(_kThemeMode, name);
    await prefs.setInt(_kAccentIndex, _accentIndex);
    notifyListeners();
  }

  Future<void> setDeveloperMode(bool on) async {
    _developerMode = on;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDevMode, on);
    notifyListeners();
  }

  Future<void> reloadReminders() async {
    _reminders = await _db.getReminders();
    notifyListeners();
  }

  Future<void> setOnboardingSeen() async {
    _hasSeenOnboarding = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHasSeenOnboarding, true);
    notifyListeners();
  }

  Future<void> toggleBalanceHidden() async {
    _balanceHidden = !_balanceHidden;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBalanceHidden, _balanceHidden);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    final name = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.system
            ? 'system'
            : 'dark';
    await prefs.setString(_kThemeMode, name);
    notifyListeners();
  }

  Future<void> setCurrency(String code, String symbol) async {
    _currency = code;
    _currencySymbol = symbol;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCurrency, code);
    await prefs.setString(_kCurrencySymbol, symbol);
    notifyListeners();
  }

  Future<void> setDecimalPlaces(int places) async {
    _decimalPlaces = places;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kDecimalPlaces, places);
    notifyListeners();
  }

  Future<void> setUserName(String name) async {
    _userName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserName, name);
    notifyListeners();
  }

  Future<void> setPasscode(String pin) async {
    final hash = pin.hashCode.toString();
    _passcodeEnabled = true;
    _passcodeHash = hash;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPasscodeEnabled, true);
    await prefs.setString(_kPasscodeHash, hash);
    notifyListeners();
  }

  Future<void> disablePasscode() async {
    _passcodeEnabled = false;
    _passcodeHash = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPasscodeEnabled, false);
    await prefs.remove(_kPasscodeHash);
    notifyListeners();
  }

  bool verifyPasscode(String pin) => pin.hashCode.toString() == _passcodeHash;

  Future<void> setFilterPeriod(String period) async {
    _filterPeriod = period;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kFilterPeriod, period);
    notifyListeners();
  }

  // ── Reminders ──────────────────────────────────────────────────────────────

  Future<void> addReminder(ReminderModel reminder) async {
    final withId = reminder.copyWith(id: _uuid.v4());
    await _db.insertReminder(withId);
    _reminders.add(withId);
    notifyListeners();
  }

  Future<void> updateReminder(ReminderModel reminder) async {
    await _db.updateReminder(reminder);
    final idx = _reminders.indexWhere((r) => r.id == reminder.id);
    if (idx != -1) {
      _reminders[idx] = reminder;
      notifyListeners();
    }
  }

  Future<void> deleteReminder(String id) async {
    await _db.deleteReminder(id);
    _reminders.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  Future<void> markReminderPaid(String id) async {
    final idx = _reminders.indexWhere((r) => r.id == id);
    if (idx == -1) return;
    final updated = _reminders[idx].copyWith(isPaid: true);
    await updateReminder(updated);
  }
}
