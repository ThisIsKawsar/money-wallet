import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:cashpilot/core/utils/data_transfer.dart';
import 'package:cashpilot/data/database/demo_data.dart';
import 'package:cashpilot/providers/settings_provider.dart';

/// Turns Developer Mode on (seeds demo data) or off (removes it) and reloads
/// every provider so all screens update immediately.
class DeveloperMode {
  static Future<void> set(BuildContext context, bool enabled) async {
    final settings = context.read<SettingsProvider>();
    final reload = DataTransfer.reloader(context);
    if (enabled) {
      await DemoData.seed();
    } else {
      await DemoData.clear();
    }
    await settings.setDeveloperMode(enabled);
    await reload();
  }
}
