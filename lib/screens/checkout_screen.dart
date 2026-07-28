import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/order_result.dart';
import '../providers/cart_provider.dart';
import '../providers/order_session_provider.dart';
import '../services/api_service.dart';
import '../utils/ph_mobile_number.dart';

final _peso = NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 0);

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _tableCtrl = TextEditingController();

  String _payment = 'Cash';
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final session = context.read<OrderSessionProvider>();
    if (session.tableNumber != null) {
      _tableCtrl.text = session.tableNumber!;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    _tableCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final cart = context.read<CartProvider>();
    final session = context.read<OrderSessionProvider>();

    if (cart.isEmpty) {
      setState(() => _error = 'Your cart is empty.');
      return;
    }

    if (session.mode == OrderMode.dineIn &&
        (_tableCtrl.text.trim().isEmpty && (session.tableNumber?.isEmpty ?? true))) {
      setState(() => _error = 'Table number is required for dine-in.');
      return;
    }

    if ((session.mode == OrderMode.pickup || session.mode == OrderMode.delivery) &&
        _nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Full name is required.');
      return;
    }

    if (session.mode == OrderMode.pickup || session.mode == OrderMode.delivery) {
      final phoneError = PhMobileNumber.validate(_phoneCtrl.text, required: true);
      if (phoneError != null) {
        setState(() => _error = phoneError);
        return;
      }
    }

    if (session.mode == OrderMode.delivery && _addressCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Delivery address is required.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final table = session.tableNumber ?? _tableCtrl.text.trim();
      final order = await ApiService().placeOrder(
        orderType: session.mode.apiValue,
        paymentMethod: _payment,
        items: cart.toOrderItems(),
        tableNumber: session.mode == OrderMode.dineIn ? table : null,
        customerName: _nameCtrl.text.trim(),
        customerPhone: (session.mode == OrderMode.pickup || session.mode == OrderMode.delivery)
            ? PhMobileNumber.normalize(_phoneCtrl.text)
            : _phoneCtrl.text.trim(),
        deliveryAddress: _addressCtrl.text.trim(),
        deliveryNotes: _notesCtrl.text.trim(),
      );
      if (!mounted) return;
      cart.clear();
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _SuccessDialog(order: order),
      );
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final session = context.watch<OrderSessionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Order type: ${session.mode.label}',
            style: const TextStyle(
              color: AppColors.amberSoft,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          if (session.mode == OrderMode.dineIn) ...[
            TextField(
              controller: _tableCtrl,
              enabled: !session.tableLocked,
              decoration: InputDecoration(
                labelText: 'Table number',
                helperText: session.tableLocked
                    ? 'Locked from QR scan'
                    : 'Enter your table number',
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (session.mode != OrderMode.dineIn) ...[
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Full name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              decoration: const InputDecoration(
                labelText: 'Mobile number',
                hintText: '09171234567',
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (session.mode == OrderMode.delivery) ...[
            TextField(
              controller: _addressCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Delivery address'),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _notesCtrl,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Special notes (optional)'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Payment method',
            style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.cream),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['Cash', 'GCash', 'Maya'].map((method) {
              final selected = _payment == method;
              return ChoiceChip(
                label: Text(method),
                selected: selected,
                onSelected: (_) => setState(() => _payment = method),
                selectedColor: AppColors.amber,
                labelStyle: TextStyle(
                  color: selected ? AppColors.onAmber : AppColors.cream,
                  fontWeight: FontWeight.w800,
                ),
                showCheckmark: false,
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderMuted),
            ),
            child: Row(
              children: [
                Text('${cart.itemCount} items'),
                const Spacer(),
                Text(
                  _peso.format(cart.subtotal),
                  style: const TextStyle(
                    color: AppColors.amberSoft,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.danger)),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Place order'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessDialog extends StatelessWidget {
  final OrderResult order;

  const _SuccessDialog({required this.order});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text(
        'Sizzling order sent!',
        style: TextStyle(color: AppColors.amberSoft, fontWeight: FontWeight.w900),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order ${order.orderNumber}', style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('Status: ${order.status}'),
          if (order.tableNumber != null) Text('Table: ${order.tableNumber}'),
          Text('Total: ${_peso.format(order.totalAmount)}'),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
