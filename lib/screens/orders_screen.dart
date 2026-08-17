import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../providers/order_session_provider.dart';
import '../theme/apple_theme.dart';

final _currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 0);

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  static final List<Map<String, dynamic>> _mockOrders = [
    {
      'id': 'SR-10492',
      'date': 'Today, 1:15 PM',
      'mode': 'Dine-In',
      'table': '05',
      'status': 'Preparing',
      'items': ['Sizzling Pork Sisig x1', 'Extra Garlic Rice x2', 'Red Iced Tea x2'],
      'total': 480.0,
    },
    {
      'id': 'SR-10381',
      'date': 'Yesterday, 7:45 PM',
      'mode': 'Pick-Up',
      'table': null,
      'status': 'Completed',
      'items': ['Bulalo Steak Feast x1', 'Sizzling Pepper Rice x1'],
      'total': 720.0,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final session = context.watch<OrderSessionProvider>();

    return Scaffold(
      backgroundColor: AppleColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          'My Orders',
          style: GoogleFonts.domine(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: AppleColors.textPrimary,
          ),
        ),
        backgroundColor: AppleColors.pureWhite,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Active Session Card if Dine-In
          if (session.isDineIn) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppleColors.primaryAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppleColors.primaryAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppleColors.primaryAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.qrCode, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Active Table ${session.tableNumber}',
                          style: GoogleFonts.domine(
                            color: AppleColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Dine-in session locked. Items added will go straight to the kitchen.',
                          style: GoogleFonts.inter(
                            color: AppleColors.mutedText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          Text(
            'Order History',
            style: GoogleFonts.inter(
              color: AppleColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),

          ..._mockOrders.map((order) {
            final isPreparing = order['status'] == 'Preparing';

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppleColors.pureWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppleColors.cardBorder),
                boxShadow: AppleColors.ambientShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order ${order['id']}',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppleColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPreparing
                              ? AppleColors.primaryAccent.withValues(alpha: 0.15)
                              : Colors.green.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          order['status'] as String,
                          style: GoogleFonts.inter(
                            color: isPreparing ? AppleColors.primaryAccent : Colors.green[700],
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${order['date']} • ${order['mode']}${order['table'] != null ? ' (Table ${order['table']})' : ''}',
                    style: GoogleFonts.inter(
                      color: AppleColors.mutedText,
                      fontSize: 12,
                    ),
                  ),
                  const Divider(height: 20),
                  ...(order['items'] as List<String>).map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• $item',
                        style: GoogleFonts.inter(
                          color: AppleColors.textBody,
                          fontSize: 13,
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total: ${_currency.format(order['total'])}',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppleColors.primaryAccent,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          AppleTheme.hapticFeedback();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Items reordered into cart!')),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          side: const BorderSide(color: AppleColors.primaryAccent),
                        ),
                        icon: const Icon(LucideIcons.rotateCcw, size: 14, color: AppleColors.primaryAccent),
                        label: Text(
                          'Reorder',
                          style: GoogleFonts.inter(
                            color: AppleColors.primaryAccent,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
