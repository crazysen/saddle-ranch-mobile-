import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/order_result.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_session_provider.dart';
import '../services/api_service.dart';
import '../utils/cavite_locations.dart';
import '../utils/ph_mobile_number.dart';
import 'confirmation_modal.dart';

final _peso = NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 2);

/// Full "View your Order" Modal in Light Mode with Pure White Background
class ViewOrderModal extends StatefulWidget {
  final VoidCallback? onOrderPlaced;

  const ViewOrderModal({super.key, this.onOrderPlaced});

  static Future<void> show(BuildContext context, {VoidCallback? onOrderPlaced}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ViewOrderModal(onOrderPlaced: onOrderPlaced),
    );
  }

  @override
  State<ViewOrderModal> createState() => _ViewOrderModalState();
}

class _ViewOrderModalState extends State<ViewOrderModal> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _couponCtrl = TextEditingController();

  String _selectedCity = defaultCity;
  String _selectedBarangay = defaultBarangay;
  String _paymentMethod = 'Cash on Delivery';
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    final session = context.read<OrderSessionProvider>();

    _nameCtrl.text = user?.fullName ?? '';
    _phoneCtrl.text = user?.phone ?? '';

    if (session.mode == OrderMode.pickup) {
      _paymentMethod = 'Cash';
    } else {
      _paymentMethod = 'Cash on Delivery';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _streetCtrl.dispose();
    _couponCtrl.dispose();
    super.dispose();
  }

  Future<void> _handlePlaceOrder() async {
    final cart = context.read<CartProvider>();
    final session = context.read<OrderSessionProvider>();

    if (cart.isEmpty) {
      setState(() => _errorMessage = 'Your cart is empty. Add items to order.');
      return;
    }

    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter your Full Name.');
      return;
    }

    final phone = _phoneCtrl.text.trim();
    final phoneError = PhMobileNumber.validate(phone, required: true);
    if (phoneError != null) {
      setState(() => _errorMessage = phoneError);
      return;
    }

    if (session.mode == OrderMode.delivery && _streetCtrl.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please provide your Street Address / Landmark.');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final deliveryAddr = session.mode == OrderMode.delivery
          ? buildDeliveryAddressString(
              streetAddress: _streetCtrl.text.trim(),
              barangay: _selectedBarangay,
              city: _selectedCity,
            )
          : null;

      final isBulihan = isBulihanArea(city: _selectedCity, barangay: _selectedBarangay);
      final branch = session.isDineIn
          ? session.branch
          : (session.mode == OrderMode.delivery ? (isBulihan ? 'Bulihan' : 'Dasma') : session.branch);

      final OrderResult order = await ApiService().placeOrder(
        orderType: session.mode.apiValue,
        branch: branch,
        paymentMethod: _paymentMethod,
        items: cart.toOrderItems(),
        tableNumber: session.mode == OrderMode.dineIn ? session.tableNumber : null,
        customerName: name,
        customerPhone: PhMobileNumber.normalize(phone),
        deliveryAddress: deliveryAddr,
        voucherCode: cart.appliedVoucherCode,
        discountAmount: cart.discountAmount,
      );

      cart.clear();

      if (!mounted) return;
      Navigator.pop(context);

      widget.onOrderPlaced?.call();

      await ConfirmationModal.show(
        context,
        title: 'Order Placed!',
        message: 'Order #${order.orderNumber} has been received by Saddle Ranch $branch Branch and sent to the kitchen.',
        type: ConfirmationType.success,
        confirmLabel: 'Track Order',
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _errorMessage = e.toString().replaceAll('ApiException: ', '').replaceAll('Exception:', '').trim();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final session = context.watch<OrderSessionProvider>();
    final isBulihan = isBulihanArea(city: _selectedCity, barangay: _selectedBarangay);
    final availableBarangays = caviteLocations[_selectedCity] ?? [];
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle & Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'View your Order',
                          style: GoogleFonts.domine(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Saddle Ranch • ${session.branch} Branch',
                          style: GoogleFonts.workSans(
                            fontSize: 12,
                            color: const Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: const Icon(LucideIcons.x, size: 18, color: Color(0xFF374151)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFFF3F4F6), height: 1),

          // Scrollable Content
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(18, 16, 18, 20 + bottomInset),
              children: [
                // 1. Fulfillment Switcher Tabs
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            session.setMode(OrderMode.pickup);
                            setState(() {
                              _paymentMethod = 'Cash';
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: session.mode == OrderMode.pickup
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: session.mode == OrderMode.pickup
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.shoppingBag,
                                  size: 16,
                                  color: session.mode == OrderMode.pickup
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFF6B7280),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Pick-Up',
                                  style: GoogleFonts.workSans(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: session.mode == OrderMode.pickup
                                        ? const Color(0xFF1F2937)
                                        : const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            session.setMode(OrderMode.delivery);
                            setState(() {
                              _paymentMethod = 'Cash on Delivery';
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: session.mode == OrderMode.delivery
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: session.mode == OrderMode.delivery
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.bike,
                                  size: 16,
                                  color: session.mode == OrderMode.delivery
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFF6B7280),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Delivery',
                                  style: GoogleFonts.workSans(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: session.mode == OrderMode.delivery
                                        ? const Color(0xFF1F2937)
                                        : const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Cart Items List
                if (cart.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Center(
                      child: Text(
                        'Your cart is empty. Add sizzling favorites!',
                        style: GoogleFonts.workSans(color: const Color(0xFF6B7280), fontSize: 13),
                      ),
                    ),
                  )
                else
                  ...cart.items.map((item) {
                    final price = item.product.priceForBranch(session.branch);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: item.product.imagePath != null && item.product.imagePath!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: item.product.imagePath!,
                                    width: 54,
                                    height: 54,
                                    fit: BoxFit.cover,
                                    placeholder: (_, _) => Container(color: const Color(0xFFF3F4F6)),
                                    errorWidget: (_, _, _) => Container(
                                      width: 54,
                                      height: 54,
                                      color: const Color(0xFFF3F4F6),
                                      child: const Icon(Icons.fastfood, color: Color(0xFF9CA3AF), size: 24),
                                    ),
                                  )
                                : Container(
                                    width: 54,
                                    height: 54,
                                    color: const Color(0xFFF3F4F6),
                                    child: const Icon(Icons.fastfood, color: Color(0xFF9CA3AF), size: 24),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product.name,
                                  style: GoogleFonts.domine(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: const Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _peso.format(price),
                                  style: GoogleFonts.domine(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                    color: const Color(0xFFF59E0B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Stepper Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () => cart.removeOne(item.product),
                                  behavior: HitTestBehavior.opaque,
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(
                                      item.quantity == 1 ? LucideIcons.trash2 : LucideIcons.minus,
                                      size: 14,
                                      color: item.quantity == 1 ? const Color(0xFFEF4444) : const Color(0xFF374151),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    '${item.quantity}',
                                    style: GoogleFonts.workSans(
                                      color: const Color(0xFF1F2937),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => cart.add(item.product),
                                  behavior: HitTestBehavior.opaque,
                                  child: const Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(LucideIcons.plus, size: 14, color: Color(0xFFF59E0B)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 14),

                // 3. Customer Info (Full Name & Mobile)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Full Name *',
                            style: GoogleFonts.workSans(color: const Color(0xFF374151), fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _nameCtrl,
                            style: GoogleFonts.workSans(color: const Color(0xFF1F2937), fontSize: 13),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s\.\-]')),
                            ],
                            decoration: InputDecoration(
                              hintText: 'Your Name',
                              hintStyle: GoogleFonts.workSans(color: const Color(0xFF9CA3AF), fontSize: 13),
                              fillColor: const Color(0xFFF9FAFB),
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mobile No. *',
                            style: GoogleFonts.workSans(color: const Color(0xFF374151), fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(11),
                            ],
                            style: GoogleFonts.workSans(color: const Color(0xFF1F2937), fontSize: 13),
                            decoration: InputDecoration(
                              hintText: '09171234567',
                              hintStyle: GoogleFonts.workSans(color: const Color(0xFF9CA3AF), fontSize: 13),
                              fillColor: const Color(0xFFF9FAFB),
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 4. Delivery Address Box (Only if Delivery mode)
                if (session.mode == OrderMode.delivery) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Live Delivery Fee Badge
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isBulihan
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isBulihan ? const Color(0xFF81C784) : const Color(0xFFFFB74D),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isBulihan ? LucideIcons.truck : LucideIcons.bike,
                                size: 16,
                                color: isBulihan ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isBulihan
                                      ? 'FREE Delivery Fee (Bulihan Area, Silang)'
                                      : 'Delivery via Lalamove: Out-of-area dispatched via rider.',
                                  style: GoogleFonts.workSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isBulihan ? const Color(0xFF1B5E20) : const Color(0xFFBF360C),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Dropdowns Row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('City / Municipality', style: GoogleFonts.workSans(color: const Color(0xFF6B7280), fontSize: 11)),
                                  const SizedBox(height: 4),
                                  DropdownButtonFormField<String>(
                                    key: ValueKey('city_$_selectedCity'),
                                    initialValue: _selectedCity,
                                    dropdownColor: Colors.white,
                                    isExpanded: true,
                                    style: GoogleFonts.workSans(color: const Color(0xFF1F2937), fontSize: 13),
                                    decoration: InputDecoration(
                                      fillColor: Colors.white,
                                      filled: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                                    ),
                                    items: caviteLocations.keys.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _selectedCity = val;
                                          _selectedBarangay = caviteLocations[val]?.first ?? '';
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Barangay', style: GoogleFonts.workSans(color: const Color(0xFF6B7280), fontSize: 11)),
                                  const SizedBox(height: 4),
                                  DropdownButtonFormField<String>(
                                    key: ValueKey('brgy_${_selectedCity}_$_selectedBarangay'),
                                    initialValue: availableBarangays.contains(_selectedBarangay) ? _selectedBarangay : availableBarangays.firstOrNull,
                                    dropdownColor: Colors.white,
                                    isExpanded: true,
                                    style: GoogleFonts.workSans(color: const Color(0xFF1F2937), fontSize: 13),
                                    decoration: InputDecoration(
                                      fillColor: Colors.white,
                                      filled: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                                    ),
                                    items: availableBarangays.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => _selectedBarangay = val);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Street Address
                        Text('Street / House No. / Landmark *', style: GoogleFonts.workSans(color: const Color(0xFF6B7280), fontSize: 11)),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _streetCtrl,
                          style: GoogleFonts.workSans(color: const Color(0xFF1F2937), fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Street address...',
                            hintStyle: GoogleFonts.workSans(color: const Color(0xFF9CA3AF), fontSize: 13),
                            fillColor: Colors.white,
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 5. Payment Method Selection
                Text(
                  'Payment Method',
                  style: GoogleFonts.workSans(color: const Color(0xFF374151), fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _paymentMethod = session.mode == OrderMode.pickup ? 'Cash' : 'Cash on Delivery';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: (_paymentMethod == 'Cash' || _paymentMethod == 'Cash on Delivery')
                                ? const Color(0xFFFFF7ED)
                                : const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: (_paymentMethod == 'Cash' || _paymentMethod == 'Cash on Delivery')
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFFE5E7EB),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              session.mode == OrderMode.pickup ? 'Cash' : 'Cash on Delivery',
                              style: GoogleFonts.workSans(
                                color: (_paymentMethod == 'Cash' || _paymentMethod == 'Cash on Delivery')
                                    ? const Color(0xFFB45309)
                                    : const Color(0xFF4B5563),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _paymentMethod = 'QRPh / e-Wallets');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _paymentMethod == 'QRPh / e-Wallets'
                                ? const Color(0xFFFFF7ED)
                                : const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _paymentMethod == 'QRPh / e-Wallets'
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFFE5E7EB),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'QRPh / e-Wallets',
                              style: GoogleFonts.workSans(
                                color: _paymentMethod == 'QRPh / e-Wallets'
                                    ? const Color(0xFFB45309)
                                    : const Color(0xFF4B5563),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 6. Promo Coupon Section
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.ticket, size: 16, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 6),
                          Text(
                            'PROMO COUPON',
                            style: GoogleFonts.workSans(
                              color: const Color(0xFFB45309),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _couponCtrl,
                              textCapitalization: TextCapitalization.characters,
                              style: GoogleFonts.workSans(color: const Color(0xFF1F2937), fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Enter coupon code...',
                                hintStyle: GoogleFonts.workSans(color: const Color(0xFF9CA3AF), fontSize: 13),
                                fillColor: Colors.white,
                                filled: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              final code = _couponCtrl.text.trim();
                              if (code.isEmpty) return;
                              final modalCtx = context;
                              final ok = await cart.validateAndApplyVoucher(code, session.branch);
                              if (!mounted || !modalCtx.mounted) return;
                              if (ok) {
                                ConfirmationModal.show(
                                  modalCtx,
                                  title: 'Voucher Applied!',
                                  message: 'Coupon code "$code" applied. You saved ₱${cart.discountAmount.toStringAsFixed(2)}!',
                                  type: ConfirmationType.success,
                                );
                              } else {
                                ConfirmationModal.show(
                                  modalCtx,
                                  title: 'Voucher Ineligible',
                                  message: cart.voucherError ?? 'Invalid or ineligible coupon code for current order.',
                                  type: ConfirmationType.alert,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text('APPLY', style: GoogleFonts.workSans(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                      if (cart.appliedVoucher != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Applied: ${cart.appliedVoucher!.code} (${cart.appliedVoucher!.discountLabel})',
                              style: GoogleFonts.workSans(
                                color: const Color(0xFF10B981),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => cart.removeVoucher(),
                              child: Text(
                                'Remove',
                                style: GoogleFonts.workSans(
                                  color: const Color(0xFFEF4444),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Error message banner
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.workSans(color: const Color(0xFFB91C1C), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),

                // 7. Totals Breakdown Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Subtotal', style: GoogleFonts.workSans(color: const Color(0xFF6B7280), fontSize: 13)),
                          Text(_peso.format(cart.subtotal), style: GoogleFonts.domine(color: const Color(0xFF1F2937), fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      if (cart.discountAmount > 0) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Coupon Discount', style: GoogleFonts.workSans(color: const Color(0xFF10B981), fontSize: 13, fontWeight: FontWeight.bold)),
                            Text('-${_peso.format(cart.discountAmount)}', style: GoogleFonts.domine(color: const Color(0xFF10B981), fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(color: Color(0xFFE5E7EB), height: 1),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Amount', style: GoogleFonts.domine(color: const Color(0xFF1F2937), fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(_peso.format(cart.totalAmount), style: GoogleFonts.domine(color: const Color(0xFFF59E0B), fontSize: 18, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 8. Sticky Place Order Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _handlePlaceOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : Text(
                            'PLACE ORDER • ${_peso.format(cart.totalAmount)}',
                            style: GoogleFonts.workSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
