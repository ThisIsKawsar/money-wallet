import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' show Sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:cashpilot/data/database/database_helper.dart';
import 'package:cashpilot/data/database/demo_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await databaseFactory.setDatabasesPath('.dart_tool/test_db/demo_data');
    await databaseFactory.deleteDatabase(
        '${await databaseFactory.getDatabasesPath()}/cashpilot.db');
    SharedPreferences.setMockInitialValues({});
  });

  Future<Map<String, double>> balances() async {
    final db = await DatabaseHelper.instance.database;
    return {
      for (final r in await db.query('accounts'))
        r['name'] as String: (r['balance'] as num).toDouble()
    };
  }

  test('demo seed loads the CSV and clear restores balances', () async {
    final db = await DatabaseHelper.instance.database;
    final before = await balances();
    expect(before.keys, containsAll(['Cash', 'IB Card', 'Bkash', 'Nagad']));

    await DemoData.seed();
    final txCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM transactions'));
    expect(txCount, 2325);
    final after = await balances();
    // ignore: avoid_print
    print('balances after seed: $after');
    expect(after.values.every((v) => v >= 0), isTrue);

    // Seeding again must not duplicate.
    await DemoData.seed();
    expect(Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM transactions')), 2325);
    expect(await balances(), after);

    await DemoData.clear();
    expect(Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM transactions')), 0);
    final cleared = await balances();
    for (final k in before.keys) {
      expect(cleared[k], closeTo(before[k]!, 0.001));
    }
  });
}
