import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cashpilot/core/theme/app_colors.dart';
import 'package:cashpilot/core/utils/data_transfer.dart';
import 'package:cashpilot/providers/account_provider.dart';
import 'package:cashpilot/providers/category_provider.dart';
import 'package:cashpilot/providers/transaction_provider.dart';
import 'package:cashpilot/widgets/ui_kit.dart';
import 'package:cashpilot/widgets/wavy_background.dart';

/// Import & Export page: step-by-step import instructions, the CSV column
/// reference, a downloadable template, and export options.
///
/// [initialTab]: 0 = Import, 1 = Export.
class ImportExportScreen extends StatefulWidget {
  final int initialTab;
  const ImportExportScreen({super.key, this.initialTab = 0});

  @override
  State<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends State<ImportExportScreen> {
  late int _tab = widget.initialTab.clamp(0, 1);
  bool _busy = false;

  Rect _shareOrigin() {
    final size = MediaQuery.of(context).size;
    return Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: 2, height: 2);
  }

  Future<void> _guard(String failPrefix, Future<void> Function() job) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await job();
    } catch (e) {
      if (mounted) {
        showToast(context, e is FormatException ? e.message : '$failPrefix: $e', error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _downloadTemplate() => _guard('Could not share template', () async {
        await DataTransfer.shareFile(
          'cashpilot_import_template.csv',
          DataTransfer.buildTemplateCsv(),
          origin: _shareOrigin(),
          text: 'CashPilot import template',
        );
      });

  void _copyTemplate() {
    Clipboard.setData(ClipboardData(text: DataTransfer.buildTemplateCsv()));
    showToast(context, 'Template copied to clipboard', icon: Icons.copy_rounded);
  }

  Future<void> _import() {
    final reload = DataTransfer.reloader(context);
    return _guard('Import failed', () async {
      final res = await DataTransfer.pickAndImport();
      if (res == null) return;
      await reload();
      if (!mounted) return;
      showToast(
        context,
        res.kind == 'backup'
            ? 'Backup restored · ${res.added} transactions'
            : 'Imported ${res.added} transactions${res.skipped > 0 ? ' · ${res.skipped} skipped' : ''}',
        icon: Icons.check_circle_rounded,
      );
      final negative = context.read<AccountProvider>().accounts.where((a) => a.balance < 0).toList();
      if (res.kind == 'csv' && negative.isNotEmpty) await _showBalanceHint(negative.map((a) => a.name).toList());
    });
  }

  Future<void> _showBalanceHint(List<String> names) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set your account balances'),
        content: Text(
          'A CSV only has transactions, not the money each account started with, '
          'so ${names.join(', ')} ${names.length == 1 ? 'is' : 'are'} now below zero.\n\n'
          'Open Accounts, tap an account, then the edit button, and enter its real '
          'Current Balance.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Later')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/accounts');
            },
            child: const Text('Open Accounts'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCsv() {
    final txs = context.read<TransactionProvider>().transactions;
    final accs = context.read<AccountProvider>().accounts;
    final cats = context.read<CategoryProvider>().categories;
    final origin = _shareOrigin();
    return _guard('Export failed', () async {
      if (txs.isEmpty) {
        showToast(context, 'No transactions to export', error: true);
        return;
      }
      await DataTransfer.shareFile(
        'cashpilot_transactions_${DataTransfer.stamp()}.csv',
        DataTransfer.buildCsv(txs, accs, cats),
        origin: origin,
        text: 'CashPilot transactions',
      );
    });
  }

  Future<void> _exportBackup() {
    final origin = _shareOrigin();
    return _guard('Export failed', () async {
      await DataTransfer.shareFile(
        'cashpilot_backup_${DataTransfer.stamp()}.json',
        await DataTransfer.buildBackupJson(),
        origin: origin,
        text: 'CashPilot backup',
      );
    });
  }

  // ── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WavyBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const ScreenHeader(title: 'Import & Export'),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: PillTabs(
                  labels: const ['Import', 'Export'],
                  index: _tab,
                  onChanged: (i) => setState(() => _tab = i),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                  children: _tab == 0 ? _importTab(context) : _exportTab(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _importTab(BuildContext context) {
    final cols = DataTransfer.csvColumns.map((c) => '"$c"').join(',');
    return [
      // Steps
      const _SectionTitle('How to import'),
      SoftCard(
        radius: 20,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          children: const [
            _Step(1, 'Download the CSV template',
                'Tap "Download Template" below and save it, or send it to your computer.'),
            _Step(2, 'Fill in your transactions',
                'Open it in Excel, Google Sheets or Numbers. Delete the sample rows and add one row per transaction.'),
            _Step(3, 'Save as CSV',
                'Keep the header row as it is and save the file as CSV (UTF-8).'),
            _Step(4, 'Import the file',
                'Tap "Choose File" and select your CSV. A CashPilot backup (.json) also works here.',
                last: true),
          ],
        ),
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(
            child: _OutlineButton(
              icon: Icons.file_download_outlined,
              label: 'Download Template',
              onTap: _busy ? null : _downloadTemplate,
            ),
          ),
          const SizedBox(width: 10),
          _OutlineButton(
            icon: Icons.copy_rounded,
            label: 'Copy',
            onTap: _copyTemplate,
          ),
        ],
      ),
      const SizedBox(height: 10),
      GradientButton(
        label: 'Choose File',
        trailingIcon: Icons.folder_open_rounded,
        loading: _busy,
        onPressed: _import,
      ),
      const SizedBox(height: 24),

      // Column reference
      const _SectionTitle('CSV columns'),
      _Code(cols),
      const SizedBox(height: 10),
      SoftCard(
        radius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          children: const [
            _ColumnRow(
              name: 'TIME',
              desc: 'Date and time of the transaction.',
              examples: ['Nov 25, 2026 7:47 PM'],
              note: 'Also accepted: 2026-11-25 19:47 or 2026-11-25',
            ),
            _ColumnRow(
              name: 'TYPE',
              desc: 'One of the three transaction types.',
              examples: ['(+) Income', '(-) Expense', '(*) Transfer'],
              note: 'Optional: "(=) Opening Balance" sets the starting amount of the '
                  'account in ACCOUNT (one row per account, can be negative).',
            ),
            _ColumnRow(
              name: 'AMOUNT',
              desc: 'Positive number, no currency sign needed.',
              examples: ['150.00', '30000'],
            ),
            _ColumnRow(
              name: 'CATEGORY',
              desc: 'Category name. New names are created automatically.',
              examples: ['O Food', 'Salary'],
              note: 'For transfers write "  -  " or leave it empty.',
            ),
            _ColumnRow(
              name: 'ACCOUNT',
              desc: 'Account name. New accounts are created automatically.',
              examples: ['Cash', 'IB Card'],
              note: 'For transfers use From->To, e.g. IB Card->Cash',
            ),
            _ColumnRow(
              name: 'NOTES',
              desc: 'Optional note. Leave empty if not needed.',
              examples: ['electric', 'internet'],
              last: true,
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),

      // Sample
      const _SectionTitle('Example file'),
      _Code(DataTransfer.buildTemplateCsv().trimRight(), scroll: true),
      const SizedBox(height: 24),

      // Good to know
      const _SectionTitle('Good to know'),
      SoftCard(
        radius: 20,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Column(
          children: const [
            _Bullet('A CSV exported from CashPilot can be imported back as is. Both use the same format.'),
            _Bullet('Account balances are updated from the imported income, expenses and transfers.'),
            _Bullet('Opening Balance rows set where each account starts. They are only applied to '
                'accounts that have no transactions yet, so they are never added twice.'),
            _Bullet('A CSV from another app usually has no opening balances, so accounts can show a '
                'minus balance after import. Fix it by editing the account and entering its real Current Balance.'),
            _Bullet('Rows that already exist (same time, type, amount and note) are skipped, so importing the same file twice is safe.'),
            _Bullet('Rows with an unknown type, a missing amount or an unreadable time are skipped.'),
            _Bullet('A .json backup restores accounts, categories, transactions, budgets and goals.'),
          ],
        ),
      ),
    ];
  }

  List<Widget> _exportTab(BuildContext context) {
    final txCount = context.watch<TransactionProvider>().transactions.length;
    final accCount = context.watch<AccountProvider>().accounts.length;
    return [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 14),
        child: Text('$txCount transactions · $accCount accounts',
            style: jakarta(13, color: context.textSecondary)),
      ),
      _OptionCard(
        icon: Icons.table_chart_rounded,
        color: AppColors.income,
        title: 'Spreadsheet (CSV)',
        subtitle: 'Open in Excel, Numbers or Google Sheets. Can be imported back.',
        onTap: _busy ? null : _exportCsv,
      ),
      const SizedBox(height: 10),
      _OptionCard(
        icon: Icons.backup_rounded,
        color: AppColors.transfer,
        title: 'Full Backup (JSON)',
        subtitle: 'Accounts, categories, transactions, budgets & goals',
        onTap: _busy ? null : _exportBackup,
      ),
      const SizedBox(height: 24),
      const _SectionTitle('CSV format'),
      _Code(DataTransfer.csvColumns.map((c) => '"$c"').join(',')),
      const SizedBox(height: 10),
      SoftCard(
        radius: 20,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Column(
          children: const [
            _Bullet('Starts with one "(=) Opening Balance" row per account that has money not '
                'explained by its transactions, then one row per transaction, oldest first.'),
            _Bullet('TYPE is (+) Income, (-) Expense or (*) Transfer.'),
            _Bullet('Transfers show the accounts as From->To and "  -  " as the category.'),
            _Bullet('Use the Import tab to bring this file back into CashPilot on any device.'),
          ],
        ),
      ),
    ];
  }
}

// ── Pieces ─────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(text.toUpperCase(),
            style: jakarta(11.5, weight: FontWeight.w700, color: context.textTertiary, spacing: 1)),
      );
}

class _Step extends StatelessWidget {
  final int n;
  final String title;
  final String body;
  final bool last;
  const _Step(this.n, this.title, this.body, {this.last = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 8 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [AppColors.primaryLight, AppColors.primary]),
            ),
            child: Text('$n', style: jakarta(13, weight: FontWeight.w800, color: Colors.white)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: jakarta(14.5, weight: FontWeight.w700, color: context.textPrimary)),
                const SizedBox(height: 2),
                Text(body, style: jakarta(13, color: context.textSecondary, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ColumnRow extends StatelessWidget {
  final String name;
  final String desc;
  final List<String> examples;
  final String? note;
  final bool last;

  const _ColumnRow({
    required this.name,
    required this.desc,
    required this.examples,
    this.note,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: context.borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(name,
                  style: jakarta(13.5,
                      weight: FontWeight.w800,
                      color: context.isDark ? AppColors.accent : AppColors.primaryDark,
                      spacing: 0.5)),
              if (name != 'NOTES') ...[
                const SizedBox(width: 6),
                Text('required', style: jakarta(10.5, weight: FontWeight.w600, color: context.textTertiary)),
              ] else ...[
                const SizedBox(width: 6),
                Text('optional', style: jakarta(10.5, weight: FontWeight.w600, color: context.textTertiary)),
              ],
            ],
          ),
          const SizedBox(height: 3),
          Text(desc, style: jakarta(13, color: context.textSecondary, height: 1.4)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final e in examples) _Chip(e)],
          ),
          if (note != null) ...[
            const SizedBox(height: 6),
            Text(note!, style: jakarta(12, color: context.textTertiary, height: 1.4)),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip(this.text);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: context.fieldColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.borderColor),
        ),
        child: Text(text,
            style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: context.textPrimary)),
      );
}

class _Code extends StatelessWidget {
  final String text;
  final bool scroll;
  const _Code(this.text, {this.scroll = false});

  @override
  Widget build(BuildContext context) {
    final body = SelectableText(
      text,
      style: TextStyle(fontFamily: 'monospace', fontSize: 11.5, height: 1.6, color: context.textPrimary),
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.fieldColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: scroll ? SingleChildScrollView(scrollDirection: Axis.horizontal, child: body) : body,
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Icon(Icons.circle, size: 6, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: jakarta(13, color: context.textSecondary, height: 1.45))),
          ],
        ),
      );
}

class _OutlineButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _OutlineButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = context.isDark ? AppColors.accent : AppColors.primaryDark;
    return Opacity(
      opacity: onTap == null ? 0.6 : 1,
      child: Material(
        color: context.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.45), width: 1.3),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: SizedBox(
            height: 52,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20, color: color),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(label,
                        overflow: TextOverflow.ellipsis,
                        style: jakarta(14.5, weight: FontWeight.w700, color: color)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _OptionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      radius: 18,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          GlossyIcon(icon: icon, color: color, size: 46),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: jakarta(15, weight: FontWeight.w700, color: context.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle, style: jakarta(12.5, color: context.textSecondary)),
              ],
            ),
          ),
          Icon(Icons.ios_share_rounded, color: context.textTertiary, size: 20),
        ],
      ),
    );
  }
}
