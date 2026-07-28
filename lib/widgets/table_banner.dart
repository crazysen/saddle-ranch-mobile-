import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/order_session_provider.dart';

class TableBanner extends StatelessWidget {
  const TableBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<OrderSessionProvider>();
    if (!session.isDineIn) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.qr_code_2, color: AppColors.amber),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ordering for Table ${session.tableNumber}',
                  style: const TextStyle(
                    color: AppColors.amberSoft,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const Text(
                  'Your order goes straight to the kitchen',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (session.tableLocked)
            TextButton(
              onPressed: () {
                session.clearTableLock();
                session.setMode(OrderMode.pickup);
              },
              child: const Text('Change'),
            ),
        ],
      ),
    );
  }
}
