import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cashpilot/providers/settings_provider.dart';
import 'package:cashpilot/core/constants/app_constants.dart';
import 'package:cashpilot/core/theme/app_colors.dart';

class CurrencyPickerScreen extends StatefulWidget {
  const CurrencyPickerScreen({super.key});

  @override
  State<CurrencyPickerScreen> createState() => _CurrencyPickerScreenState();
}

class _CurrencyPickerScreenState extends State<CurrencyPickerScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();

    final filtered = AppConstants.currencies.where((c) {
      final q = _search.toLowerCase();
      return c['name']!.toLowerCase().contains(q) ||
          c['code']!.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Select Currency',
            style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1a1a2e))),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(
                hintText: 'Search currency...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final c = filtered[i];
                final isSelected = settings.currency == c['code'];
                return ListTile(
                  onTap: () async {
                    await settings.setCurrency(c['code']!, c['symbol']!);
                    if (context.mounted) Navigator.pop(context);
                  },
                  title: Text(c['name']!,
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w500)),
                  subtitle: Text(c['code']!,
                      style: GoogleFonts.inter(fontSize: 12)),
                  leading: Container(
                    width: 44,
                    alignment: Alignment.center,
                    child: Text(c['symbol']!,
                        style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary)),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_rounded,
                          color: AppColors.primary)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
