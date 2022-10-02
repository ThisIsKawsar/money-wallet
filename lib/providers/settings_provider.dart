import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cashpilot/data/models/reminder_model.dart';
import 'package:cashpilot/data/database/database_helper.dart';
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

  ThemeMode _themeMode = ThemeMode.dark;
  String _currency = 'USD';
  String _currencySymbol = '\$';
  int _decimalPlaces = 2;
  bool _passcodeEnabled = false;
  String? _passcodeHash;
  String _userName = '';
  String _filterPeriod = 'monthly';

  List<ReminderModel> _reminders = [];

  ThemeMode get themeMode => _themeMode;
  String get currency => _currency;
  String get currencySymbol => _currencySymbol;
  int get decimalPlaces => _decimalPlaces;
  bool get passcodeEnabled => _passcodeEnabled;
  String? get passcodeHash => _passcodeHash;
  String get userName => _userName;
  String get filterPeriod => _filterPeriod;
  List<ReminderModel> get reminders => List.unmodifiable(_reminders);

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString(_kThemeMode) ?? 'dark';
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
    _userName = prefs.getString(_kUserName) ?? '';
    _filterPeriod = prefs.getString(_kFilterPeriod) ?? 'monthly';
    _reminders = await _db.getReminders();
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
