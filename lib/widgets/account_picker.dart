import 'package:flutter/material.dart';
import 'package:cashpilot/core/constants/app_icons.dart';
import 'package:cashpilot/core/theme/app_colors.dart';
import 'package:cashpilot/data/models/account_model.dart';
import 'package:cashpilot/widgets/ui_kit.dart';

/// Card-style account selector that opens a bottom sheet list.
class AccountPickerField extends StatelessWidget {
  final List<AccountModel> accounts;
  final AccountModel? selected;
  final String symbol;
  final ValueChanged<AccountModel> onChanged;

  const AccountPickerField({
    super.key,
    required this.accounts,
    required this.selected,
    required this.symbol,
    required this.onChanged,
  });

  Future<void> _open(BuildContext context) async {
    final picked = await showAppSheet<AccountModel>(
      context,
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Select Account',
              style: jakarta(18, weight: FontWeight.w800, color: ctx.textPrimary)),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.5),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: accounts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final a = accounts[i];
                final isSel = a.id == selected?.id;
                return SoftCard(
                  shadow: false,
                  radius: 16,
                  padding: const EdgeInsets.all(12),
                  color: isSel ? AppColors.primary.withValues(alpha: 0.08) : null,
                  onTap: () => Navigator.pop(ctx, a),
                  child: Row(
                    children: [
                      GlossyIcon(icon: AppIcons.fromName(a.icon), color: AppColors.fromHex(a.color), size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(a.name,
                            style: jakarta(15, weight: FontWeight.w600, color: ctx.textPrimary)),
                      ),
                      Text(fmtMoney(a.balance, symbol),
                          style: jakarta(14, weight: FontWeight.w700, color: ctx.textSecondary)),
                      if (isSel) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final a = selected;
    return FieldBox(
      onTap: accounts.isEmpty ? null : () => _open(context),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          if (a != null)
            GlossyIcon(icon: AppIcons.fromName(a.icon), color: AppColors.fromHex(a.color), size: 44)
          else
            GlossyIcon(icon: Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a?.name ?? (accounts.isEmpty ? 'No accounts' : 'Select account'),
                    style: jakarta(15, weight: FontWeight.w600, color: context.textPrimary)),
                if (a != null)
                  Text(fmtMoney(a.balance, symbol),
                      style: jakarta(14, weight: FontWeight.w700, color: context.textSecondary)),
              ],
            ),
          ),
          Icon(Icons.keyboard_arrow_down_rounded, color: context.textSecondary),
        ],
      ),
    );
  }
}
