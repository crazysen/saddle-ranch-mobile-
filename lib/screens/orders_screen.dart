import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/order_result.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/menu_provider.dart';
import '../providers/order_session_provider.dart';
import '../services/api_service.dart';
import '../theme/apple_theme.dart';
import '../widgets/confirmation_modal.dart';

final _currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 0);

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<OrderResult> _orders = [];
  bool _loading = true;
  Timer? _pollingTimer;
  Timer? _waiterPollingTimer;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    // Poll active orders every 5 seconds per System Spec Section 8
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) => _pollOrders());
    // Poll waiter buzzer status every 2.5 seconds per System Spec Section 4
    _waiterPollingTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      if (mounted) {
        context.read<OrderSessionProvider>().pollWaiterStatus();
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _waiterPollingTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders({String? query}) async {
    setState(() {
      _loading = true;
    });

    try {
      final results = await _api.trackOrders(query: query, all: query == null || query.isEmpty);
      if (mounted) {
        setState(() {
          _orders = results;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _orders = [];
          _loading = false;
        });
      }
    }
  }

  Future<void> _pollOrders() async {
    if (_loading) return;
    try {
      final query = _searchCtrl.text.trim();
      final results = await _api.trackOrders(query: query.isNotEmpty ? query : null, all: query.isEmpty);
      if (mounted) {
        setState(() {
          _orders = results;
        });
      }
    } catch (_) {}
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'preparing':
        return AppleColors.primaryAccent;
      case 'ready':
      case 'completed':
        return const Color(0xFF2E7D32);
      case 'cancelled':
        return const Color(0xFFC62828);
      default:
        return const Color(0xFF0288D1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<OrderSessionProvider>();

    return Scaffold(
      backgroundColor: AppleColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          'Order Tracker & History',
          style: GoogleFonts.domine(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: AppleColors.textPrimary,
          ),
        ),
        backgroundColor: AppleColors.pureWhite,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _fetchOrders(query: _searchCtrl.text.trim()),
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            tooltip: 'Refresh Orders',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchOrders(query: _searchCtrl.text.trim()),
        color: AppleColors.primaryAccent,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Active Session & Waiter Buzzer Card if Dine-In
            if (session.isDineIn) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppleColors.primaryAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppleColors.primaryAccent.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
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
                                'Table ${session.tableNumber} • ${session.branch} Branch',
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
                    const SizedBox(height: 14),

                    // "Call Waiter" Buzzer Button (System Spec Section 4)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: session.waiterCallStatus == 'pending'
                            ? null
                            : () async {
                                await session.triggerCallWaiter();
                                if (context.mounted) {
                                  ConfirmationModal.show(
                                    context,
                                    title: 'Buzzer Sent!',
                                    message: 'Table #${session.tableNumber} buzzer has been sent. A server will assist you shortly.',
                                    type: ConfirmationType.success,
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: session.waiterCallStatus == 'pending'
                              ? Colors.grey[400]
                              : (session.waiterCallStatus == 'acknowledged'
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFFD84315)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: Icon(
                          session.waiterCallStatus == 'pending'
                              ? LucideIcons.loader
                              : LucideIcons.bellRing,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: Text(
                          session.waiterCallStatus == 'pending'
                              ? 'Calling Waiter... / Assistance Requested'
                              : (session.waiterCallStatus == 'acknowledged'
                                  ? 'Server is on the way!'
                                  : 'Call Waiter (Table Buzzer)'),
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Live Order Search / Tracker input
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E5E7)),
              ),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Track by Order # (e.g. SR-10492) or phone...',
                  prefixIcon: const Icon(LucideIcons.search, size: 18),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: () {
                      _searchCtrl.clear();
                      _fetchOrders();
                    },
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onSubmitted: (query) => _fetchOrders(query: query.trim()),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active & Recent Orders',
                  style: GoogleFonts.inter(
                    color: AppleColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                if (_loading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppleColors.primaryAccent),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (_orders.isEmpty && !_loading)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    const Icon(LucideIcons.receipt, size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text(
                      'No orders found',
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: AppleColors.mutedText),
                    ),
                  ],
                ),
              ),

            ..._orders.map((order) {
              final statusColor = _getStatusColor(order.status);

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
                        Row(
                          children: [
                            Text(
                              order.orderNumber,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: AppleColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F0F2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                order.branch,
                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppleColors.mutedText),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            order.statusLabel,
                            style: GoogleFonts.inter(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${order.createdAt ?? 'Recent'} • ${order.orderType.toUpperCase()}${order.tableNumber != null ? ' (Table ${order.tableNumber})' : ''}',
                      style: GoogleFonts.inter(
                        color: AppleColors.mutedText,
                        fontSize: 12,
                      ),
                    ),
                    if (order.deliveryAddress != null && order.deliveryAddress!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(LucideIcons.mapPin, size: 13, color: AppleColors.mutedText),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              order.deliveryAddress!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(color: AppleColors.mutedText, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const Divider(height: 20),

                    // Order Items
                    ...order.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${item.quantity}x ${item.productName}',
                              style: GoogleFonts.inter(
                                color: AppleColors.textBody,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              _currency.format(item.subtotal),
                              style: GoogleFonts.inter(
                                color: AppleColors.textBody,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (order.discountAmount > 0)
                              Text(
                                'Discount: -${_currency.format(order.discountAmount)}',
                                style: GoogleFonts.inter(color: const Color(0xFF2E7D32), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            Text(
                              'Total: ${_currency.format(order.totalAmount)}',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: AppleColors.primaryAccent,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 36,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              AppleTheme.hapticFeedback();
                              final cart = context.read<CartProvider>();
                              final menu = context.read<MenuProvider>();
                              for (final item in order.items) {
                                final prod = menu.products.firstWhere(
                                  (p) => p.id == item.productId,
                                  orElse: () => Product(
                                    id: item.productId,
                                    name: item.productName,
                                    description: '',
                                    price: item.unitPrice,
                                    stockQuantity: 50,
                                    isActive: true,
                                  ),
                                );
                                cart.add(prod, quantity: item.quantity);
                              }
                              ConfirmationModal.show(
                                context,
                                title: 'Items Reordered!',
                                message: 'All items from order ${order.orderNumber} have been added to your cart.',
                                type: ConfirmationType.success,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(LucideIcons.repeat, size: 14, color: Colors.white),
                            label: Text(
                              'Reorder',
                              style: GoogleFonts.workSans(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
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
      ),
    );
  }
}
