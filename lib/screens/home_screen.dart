import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../main.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/menu_provider.dart';
import '../providers/order_session_provider.dart';
import '../utils/menu_category.dart';
import '../widgets/banner_carousel.dart';
import '../widgets/confirmation_modal.dart';
import 'qr_scanner_screen.dart';

import '../models/order_result.dart';
import '../models/product.dart';
import '../models/voucher.dart';
import '../services/api_service.dart';
import '../utils/image_url_helper.dart';

final _currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 0);

typedef OpenMenuCallback = void Function({MenuCategory? category});

final List<Map<String, dynamic>> _savedAddresses = [
  {
    'title': 'Saddle Ranch Bulihan Main',
    'subtitle': 'Aguinaldo Highway, Bulihan, Silang, Cavite',
    'icon': LucideIcons.mapPin,
    'mode': OrderMode.pickup,
    'isBulihan': true,
  },
  {
    'title': 'Saddle Ranch Dasmariñas Branch',
    'subtitle': 'Sampaloc 1, Dasmariñas City, Cavite',
    'icon': LucideIcons.building,
    'mode': OrderMode.pickup,
    'isBulihan': false,
  },
];

class HomeScreen extends StatefulWidget {
  final OpenMenuCallback onOpenMenu;

  const HomeScreen({super.key, required this.onOpenMenu});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedLocation = 'Saddle Ranch Bulihan Main';
  int _unreadNotifications = 0;
  List<Voucher> _vouchers = [];
  List<OrderResult> _activeOrders = [];
  bool _loadingVouchers = false;
  Timer? _ordersPollingTimer;

  @override
  void initState() {
    super.initState();
    _loadVouchers();
    _loadActiveOrders();
    _ordersPollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _loadActiveOrders();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoDetectClosestBranch();
    });
  }

  Future<void> _autoDetectClosestBranch() async {
    if (!mounted) return;
    final session = context.read<OrderSessionProvider>();
    final menu = context.read<MenuProvider>();
    await session.autoDetectBranch();
    menu.setBranch(session.branch);
  }

  Future<void> _loadVouchers() async {
    setState(() => _loadingVouchers = true);
    try {
      final list = await _api.fetchCustomerVouchers();
      if (mounted) {
        setState(() {
          _vouchers = list;
          _loadingVouchers = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingVouchers = false);
    }
  }

  final Set<String> _dismissedOrderSignatures = {};

  Future<void> _loadActiveOrders() async {
    try {
      final list = await _api.trackOrders(all: true);
      if (mounted) {
        setState(() {
          _activeOrders = list;
          _unreadNotifications = list.where((o) {
            if (o.status == 'completed' || o.status == 'cancelled') return false;
            final sig = '${o.orderNumber}_${o.status}';
            return !_dismissedOrderSignatures.contains(sig);
          }).length;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _ordersPollingTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showLocationPicker() {
    final session = context.read<OrderSessionProvider>();
    final menu = context.read<MenuProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setPickerState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Branch Switcher (Bulihan vs Dasmariñas)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Branch Menu',
                          style: GoogleFonts.domine(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppleColors.textPrimary,
                          ),
                        ),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'Bulihan', label: Text('Bulihan')),
                            ButtonSegment(value: 'Dasma', label: Text('Dasma')),
                          ],
                          selected: {session.branch},
                          onSelectionChanged: (val) {
                            final newBranch = val.first;
                            session.setBranch(newBranch);
                            menu.setBranch(newBranch);
                            setPickerState(() {});
                          },
                          style: ButtonStyle(
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Text(
                      'Select Delivery / Fulfillment Location',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppleColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    ..._savedAddresses.map((addr) {
                      final title = addr['title'] as String;
                      final subtitle = addr['subtitle'] as String;
                      final icon = addr['icon'] as IconData;
                      final mode = addr['mode'] as OrderMode;
                      final isBulihan = addr['isBulihan'] as bool? ?? false;
                      final isSelected = !session.isDineIn && _selectedLocation == title;

                      return _LocationOptionTile(
                        icon: icon,
                        title: title,
                        subtitle: subtitle,
                        selected: isSelected,
                        deliveryTag: isBulihan ? 'FREE Delivery' : 'Lalamove',
                        isFreeDelivery: isBulihan,
                        onTap: () {
                          setState(() => _selectedLocation = title);
                          session.setMode(mode);
                          Navigator.pop(ctx);
                        },
                      );
                    }),
                    if (session.isDineIn)
                      _LocationOptionTile(
                        icon: LucideIcons.qrCode,
                        title: 'Table ${session.tableNumber} (Dine-In)',
                        subtitle: 'Locked table session',
                        selected: true,
                        onTap: () => Navigator.pop(ctx),
                      ),
                    // Auto-Detect Nearest Branch Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final currentCtx = context;
                          await session.autoDetectBranch();
                          menu.setBranch(session.branch);
                          setPickerState(() {});
                          if (!mounted) return;
                          final branchName = session.branch == 'Bulihan' ? 'Bulihan Main (Silang)' : 'Dasmariñas Branch';
                          if (currentCtx.mounted) {
                            ConfirmationModal.show(
                              currentCtx,
                              title: 'Closest Branch Detected',
                              message: 'Your nearest location is $branchName. Menu items and pricing are now configured for this branch.',
                              type: ConfirmationType.success,
                            );
                          }
                        },
                        icon: const Icon(LucideIcons.locateFixed, size: 16, color: Color(0xFFF59E0B)),
                        label: Text(
                          'Auto-Detect Closest Branch',
                          style: GoogleFonts.workSans(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F2937),
                            fontSize: 13,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order Notifications',
                        style: GoogleFonts.domine(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppleColors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          for (final o in _activeOrders) {
                            _dismissedOrderSignatures.add('${o.orderNumber}_${o.status}');
                          }
                          setState(() => _unreadNotifications = 0);
                          Navigator.pop(ctx);
                        },
                        child: const Text('Dismiss'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _activeOrders.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(LucideIcons.bellOff, size: 40, color: AppleColors.mutedText),
                                const SizedBox(height: 12),
                                Text(
                                  'No active order notifications',
                                  style: GoogleFonts.inter(fontSize: 14, color: AppleColors.mutedText),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            controller: controller,
                            itemCount: _activeOrders.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final order = _activeOrders[index];
                              final status = order.status.toLowerCase();
                              final isPreparing = status == 'preparing';
                              final isDelivering = status == 'delivering' || status == 'out_for_delivery';
                              final isReady = status == 'ready';

                              IconData statusIcon = LucideIcons.receipt;
                              Color statusColor = const Color(0xFFF59E0B);
                              String statusMessage = order.statusDescription;

                              if (status == 'pending') {
                                statusIcon = LucideIcons.clock;
                                statusColor = const Color(0xFF3B82F6);
                              } else if (isPreparing) {
                                statusIcon = LucideIcons.flame;
                                statusColor = const Color(0xFFF59E0B);
                              } else if (isReady) {
                                statusIcon = LucideIcons.checkCircle2;
                                statusColor = const Color(0xFF10B981);
                              } else if (isDelivering) {
                                statusIcon = LucideIcons.bike;
                                statusColor = const Color(0xFF8B5CF6);
                              } else if (status == 'completed') {
                                statusIcon = LucideIcons.checkCircle2;
                                statusColor = const Color(0xFF10B981);
                              } else if (status == 'cancelled') {
                                statusIcon = LucideIcons.xCircle;
                                statusColor = const Color(0xFFEF4444);
                              }

                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    _dismissedOrderSignatures.add('${order.orderNumber}_${order.status}');
                                    setState(() {
                                      _unreadNotifications = _activeOrders.where((o) {
                                        if (o.status == 'completed' || o.status == 'cancelled') return false;
                                        return !_dismissedOrderSignatures.contains('${o.orderNumber}_${o.status}');
                                      }).length;
                                    });
                                    Navigator.pop(ctx);
                                    AppTabController.switchTab?.call(1);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: statusColor.withValues(alpha: 0.3),
                                        width: 1.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.03),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(alpha: 0.12),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            statusIcon,
                                            color: statusColor,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    'Order ${order.orderNumber}',
                                                    style: GoogleFonts.domine(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                      color: const Color(0xFF1F2937),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: statusColor.withValues(alpha: 0.1),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      order.statusLabel,
                                                      style: GoogleFonts.workSans(
                                                        color: statusColor,
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                statusMessage,
                                                style: GoogleFonts.workSans(
                                                  color: const Color(0xFF4B5563),
                                                  fontSize: 12,
                                                  height: 1.3,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    '${order.orderType.toUpperCase()} • ${order.branch} Branch',
                                                    style: GoogleFonts.workSans(
                                                      color: const Color(0xFF9CA3AF),
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Track Order →',
                                                    style: GoogleFonts.workSans(
                                                      color: const Color(0xFFF59E0B),
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  if (_activeOrders.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () {
                          for (final o in _activeOrders) {
                            _dismissedOrderSignatures.add('${o.orderNumber}_${o.status}');
                          }
                          setState(() => _unreadNotifications = 0);
                          Navigator.pop(ctx);
                          AppTabController.switchTab?.call(1);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          'View in Orders Tracker',
                          style: GoogleFonts.workSans(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showOrderModeModal(BuildContext context) {
    final session = context.read<OrderSessionProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'How would you like to order?',
                style: GoogleFonts.domine(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select your fulfillment preference to view available sizzling items.',
                style: GoogleFonts.workSans(color: const Color(0xFF6B7280), fontSize: 13),
              ),
              const SizedBox(height: 18),

              // 1. Dine-In
              _buildOrderModeTile(
                ctx: ctx,
                title: 'Dine-In',
                subtitle: 'Order from your table or scan QR code',
                icon: LucideIcons.qrCode,
                selected: session.mode == OrderMode.dineIn,
                onTap: () {
                  session.setMode(OrderMode.dineIn);
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const QrScannerScreen()),
                  );
                },
              ),
              const SizedBox(height: 10),

              // 2. Pick-Up
              _buildOrderModeTile(
                ctx: ctx,
                title: 'Pick-Up',
                subtitle: 'Order ahead and pick up at the counter',
                icon: LucideIcons.shoppingBag,
                selected: session.mode == OrderMode.pickup,
                onTap: () {
                  session.setMode(OrderMode.pickup);
                  Navigator.pop(ctx);
                  widget.onOpenMenu();
                },
              ),
              const SizedBox(height: 10),

              // 3. Delivery
              _buildOrderModeTile(
                ctx: ctx,
                title: 'Delivery',
                subtitle: 'Delivered directly to your Cavite doorstep',
                icon: LucideIcons.bike,
                selected: session.mode == OrderMode.delivery,
                onTap: () {
                  session.setMode(OrderMode.delivery);
                  Navigator.pop(ctx);
                  widget.onOpenMenu();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderModeTile({
    required BuildContext ctx,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? const Color(0xFFFFF7ED) : const Color(0xFFF9FAFB),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          AppleTheme.hapticFeedback();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? const Color(0xFFF59E0B) : const Color(0xFFE5E7EB),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFFF59E0B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? const Color(0xFFF59E0B) : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: selected ? Colors.white : const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.workSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.workSans(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.chevron_right,
                color: selected ? const Color(0xFFF59E0B) : const Color(0xFF9CA3AF),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<MenuProvider>();
    final auth = context.watch<AuthProvider>();
    final session = context.watch<OrderSessionProvider>();
    final user = auth.user;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final userName = user?.fullName.isNotEmpty == true
        ? user!.fullName
        : 'Guest';

    final displayLocation = session.isDineIn
        ? 'Table ${session.tableNumber} (Dine-In)'
        : _selectedLocation;

    return Scaffold(
      backgroundColor: AppleColors.scaffoldBackground,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppleColors.primaryAccent,
          backgroundColor: Colors.white,
          onRefresh: () async {
            await Future.wait([
              menu.load(),
              _loadVouchers(),
              _loadActiveOrders(),
            ]);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Functional Header Section with Location Picker
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppleColors.cardSurface,
                        backgroundImage: (user?.photoUrl != null && user!.photoUrl!.isNotEmpty && ImageUrlHelper.normalize(user.photoUrl) != null)
                            ? CachedNetworkImageProvider(ImageUrlHelper.normalize(user.photoUrl!)!)
                            : null,
                        child: user?.photoUrl == null || user!.photoUrl!.isEmpty
                            ? Text(
                                userName.isNotEmpty ? userName[0].toUpperCase() : 'S',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  color: AppleColors.primaryAccent,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      // Functional Delivery Location Dropdown
                      Expanded(
                        child: GestureDetector(
                          onTap: _showLocationPicker,
                          behavior: HitTestBehavior.opaque,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: AppleColors.primaryAccent,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    session.isDineIn ? 'Dine-In Seat' : 'Fulfillment Branch / Address',
                                    style: GoogleFonts.inter(
                                      color: AppleColors.mutedText,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(
                                    Icons.keyboard_arrow_down,
                                    color: AppleColors.mutedText,
                                    size: 16,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                displayLocation,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: AppleColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Notification Bell
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(LucideIcons.bell, size: 22, color: AppleColors.textPrimary),
                            onPressed: _showNotificationsSheet,
                            tooltip: 'Order Notifications',
                          ),
                          if (_unreadNotifications > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppleColors.primaryAccent,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$_unreadNotifications',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Search Bar (70%) + Order Button (30%)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Search Bar (70%)
                      Expanded(
                        flex: 7,
                        child: Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            style: GoogleFonts.workSans(fontSize: 14, color: const Color(0xFF1F2937)),
                            decoration: InputDecoration(
                              hintText: 'Search food or menu...',
                              hintStyle: GoogleFonts.workSans(color: const Color(0xFF9CA3AF), fontSize: 13),
                              prefixIcon: const Icon(LucideIcons.search, size: 18, color: Color(0xFF9CA3AF)),
                              prefixIconConstraints: const BoxConstraints(minWidth: 30),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onSubmitted: (q) {
                              menu.setSearch(q);
                              widget.onOpenMenu();
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Order Button (30%)
                      Expanded(
                        flex: 3,
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () => _showOrderModeModal(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(LucideIcons.utensilsCrossed, size: 15, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  'Order',
                                  style: GoogleFonts.workSans(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.white,
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
              ),

              // 3. "How are you Ordering" Section (Directly below Search)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                  child: Text(
                    'How are you Ordering',
                    style: GoogleFonts.inter(
                      color: AppleColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _CompactOrderingCard(
                          title: 'Dine-In',
                          subtitle: 'Scan Table',
                          icon: LucideIcons.qrCode,
                          selected: session.mode == OrderMode.dineIn,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const QrScannerScreen()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _CompactOrderingCard(
                          title: 'Pick-Up',
                          subtitle: 'Order Ahead',
                          icon: LucideIcons.shoppingBag,
                          selected: session.mode == OrderMode.pickup,
                          onTap: () {
                            session.setMode(OrderMode.pickup);
                            widget.onOpenMenu();
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _CompactOrderingCard(
                          title: 'Delivery',
                          subtitle: 'To Your Door',
                          icon: LucideIcons.bike,
                          selected: session.mode == OrderMode.delivery,
                          onTap: () {
                            session.setMode(OrderMode.delivery);
                            widget.onOpenMenu();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Promotion Banner Carousel
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: BannerCarousel(
                    banners: menu.banners,
                    onSeeAll: () => widget.onOpenMenu(),
                    onBannerTap: () => widget.onOpenMenu(),
                  ),
                ),
              ),

              // 5. Featured Sizzling Items Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Featured Sizzling Items',
                        style: GoogleFonts.domine(
                          color: const Color(0xFF1F2937),
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Piping hot cast-iron platters seared right off our charcoal fire.',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Builder(
                  builder: (context) {
                    final featuredItems = _getFeaturedSizzlingItems(menu.products);
                    return SizedBox(
                      height: 310,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: featuredItems.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 14),
                        itemBuilder: (context, index) {
                          final itemData = featuredItems[index];
                          final prod = itemData['product'] as Product;
                          final badge = itemData['badge'] as String;

                          return _FeaturedSizzlingCard(
                            product: prod,
                            badgeText: badge,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),

              // 6. Explore Our Sizzling Categories Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Explore Our Sizzling Categories',
                        style: GoogleFonts.domine(
                          color: const Color(0xFF1F2937),
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Signature sizzling categories straight from the fire.',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 240,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _sizzlingCategoriesData.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final cat = _sizzlingCategoriesData[index];
                      return _SizzlingCategoryCard(
                        title: cat['title'] as String,
                        description: cat['description'] as String,
                        imageUrl: cat['imageUrl'] as String,
                        badgeText: cat['badge'] as String,
                        onTap: () => widget.onOpenMenu(category: cat['category'] as MenuCategory),
                      );
                    },
                  ),
                ),
              ),

              // Vouchers Section filtered for the user's Location/Branch
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 26, 16, 12),
                  child: Text(
                    'Vouchers & Coupons',
                    style: GoogleFonts.inter(
                      color: AppleColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 110 + bottomInset),
                sliver: SliverToBoxAdapter(
                  child: Builder(
                    builder: (context) {
                      final branchVouchers = _vouchers.where((v) {
                        final b = v.branch.toLowerCase();
                        final activeB = session.branch.toLowerCase();
                        return b == 'all' ||
                            b == activeB ||
                            (activeB == 'bulihan' && b.contains('bulihan')) ||
                            (activeB == 'dasma' && b.contains('dasma'));
                      }).toList();

                      return SizedBox(
                        height: 110,
                        child: branchVouchers.isEmpty
                            ? Container(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: _loadingVouchers
                                    ? const CircularProgressIndicator(color: AppleColors.primaryAccent)
                                    : Text(
                                        'No vouchers available for ${session.branch} branch.',
                                        style: GoogleFonts.inter(color: AppleColors.mutedText),
                                      ),
                              )
                            : ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: branchVouchers.length,
                                separatorBuilder: (_, _) => const SizedBox(width: 14),
                                itemBuilder: (context, index) {
                                  final v = branchVouchers[index];
                                  final cart = context.watch<CartProvider>();
                                  final isVoucherUsed = v.isUsed || cart.isVoucherUsed(v.code);
                                  final isVoucherApplied = cart.appliedVoucherCode?.toUpperCase() == v.code.toUpperCase();

                                  return _TicketVoucherCard(
                                    discount: v.discountLabel,
                                    title: v.code,
                                    minSpend: v.minSpend > 0 ? 'Min. ₱${v.minSpend.toInt()}' : 'No min. spend',
                                    code: v.code,
                                    expiry: v.branch.toLowerCase() == 'all'
                                        ? 'All Branches'
                                        : '${v.branch} branch only',
                                    claimed: isVoucherUsed,
                                    isUsed: isVoucherUsed,
                                    isApplied: isVoucherApplied,
                                    accentColor: index % 2 == 0 ? const Color(0xFFFF6B00) : const Color(0xFF0288D1),
                                    onClaim: () async {
                                      final currentCtx = context;
                                      await Clipboard.setData(ClipboardData(text: v.code));
                                      if (currentCtx.mounted) {
                                        if (cart.items.isNotEmpty) {
                                          await cart.applyVoucher(v.code);
                                        }
                                        if (currentCtx.mounted) {
                                          ConfirmationModal.show(
                                            currentCtx,
                                            title: 'Voucher Copied!',
                                            message: 'Voucher code "${v.code}" copied to clipboard and applied to your order.',
                                            type: ConfirmationType.success,
                                          );
                                        }
                                      }
                                    },
                                  );
                                },
                              ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFeaturedSizzlingItems(List<Product> allProducts) {
    final inasal = allProducts.where((p) => p.name.toLowerCase().contains('inasal')).firstOrNull ??
        const Product(
          id: 7,
          name: 'Sizzling Chicken Inasal',
          description: 'Bacolod-style chargrilled chicken quarter served sizzling with savory chicken oil and garlic rice.',
          price: 120.0,
          imagePath: 'https://saddle-ranch-web.onrender.com/images/Menu/chicken_inasal.webp',
          category: 'Sizzling Rice Meals',
          stockQuantity: 50,
          isActive: true,
        );

    final sisig = allProducts.where((p) => p.name.toLowerCase().contains('sisig') && !p.name.toLowerCase().contains('platter')).firstOrNull ??
        const Product(
          id: 9,
          name: 'Sizzling Sisig (w/ Egg)',
          description: 'Crispy chopped pork seasoned with onions, calamansi, and chili, topped with a fresh egg.',
          price: 100.0,
          imagePath: 'https://saddle-ranch-web.onrender.com/images/Menu/sisig.webp',
          category: 'Sizzling Rice Meals',
          stockQuantity: 60,
          isActive: true,
        );

    final teriyaki = allProducts.where((p) => p.name.toLowerCase().contains('teriyaki') && !p.name.toLowerCase().contains('platter')).firstOrNull ??
        const Product(
          id: 5,
          name: 'Sizzling Beef Teriyaki',
          description: 'Tender slices of beef glazed with sweet-savory teriyaki sauce on a sizzling platter.',
          price: 140.0,
          imagePath: 'https://saddle-ranch-web.onrender.com/images/Menu/beef_teriyaki.webp',
          category: 'Sizzling Rice Meals',
          stockQuantity: 50,
          isActive: true,
        );

    return [
      {'product': inasal, 'badge': 'CHICKEN INASAL'},
      {'product': sisig, 'badge': 'SISIG'},
      {'product': teriyaki, 'badge': 'BEEF TERIYAKI'},
    ];
  }

  static const List<Map<String, dynamic>> _sizzlingCategoriesData = [
    {
      'title': 'Sizzling Rice Meals',
      'description': 'Complete hearty platters with garlic rice, topped with tender meats and savory gravies on hot cast iron.',
      'imageUrl': 'https://saddle-ranch-web.onrender.com/images/Menu/sisig.webp',
      'badge': 'SISIG',
      'category': MenuCategory.sizzling,
    },
    {
      'title': 'Authentic Filipino Cuisine',
      'description': 'Time-honored Filipino heritage recipes cooked sizzling hot with bold local seasonings and native flair.',
      'imageUrl': 'https://saddle-ranch-web.onrender.com/images/FilipinoCousines/pork_sinigang.webp',
      'badge': 'PORK SINIGANG',
      'category': MenuCategory.filipino,
    },
    {
      'title': 'Barkada Platters',
      'description': 'Generous sharing platters made for group feasts, family gatherings, and roadhouse celebrations.',
      'imageUrl': 'https://saddle-ranch-web.onrender.com/images/Platters/platter_sisig.webp',
      'badge': 'SISIG PLATTER',
      'category': MenuCategory.barkada,
    },
  ];
}

class _FeaturedSizzlingCard extends StatelessWidget {
  final Product product;
  final String badgeText;

  const _FeaturedSizzlingCard({
    required this.product,
    required this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final session = context.watch<OrderSessionProvider>();
    final cartItem = cart.items.where((i) => i.product.id == product.id).firstOrNull;
    final inCart = cartItem?.quantity ?? 0;
    final price = product.priceForBranch(session.branch);
    final normalizedImg = ImageUrlHelper.normalize(product.imagePath);

    return Container(
      width: 255,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Food Image with Badges
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                child: SizedBox(
                  height: 135,
                  width: double.infinity,
                  child: normalizedImg != null && normalizedImg.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: normalizedImg,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => Container(color: const Color(0xFFF3F4F6)),
                          errorWidget: (_, _, _) => Container(
                            color: const Color(0xFFF3F4F6),
                            child: const Icon(Icons.fastfood, color: Color(0xFFF59E0B), size: 36),
                          ),
                        )
                      : Container(
                          color: const Color(0xFFF3F4F6),
                          child: const Icon(Icons.fastfood, color: Color(0xFFF59E0B), size: 36),
                        ),
                ),
              ),
              // Wooden / Amber Badge on Image
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF78350F).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF92400E)),
                  ),
                  child: Text(
                    badgeText.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              // Red circular indicator dot
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.6),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Content & Actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.domine(
                    color: const Color(0xFF1F2937),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF6B7280),
                    fontSize: 11,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _currency.format(price),
                  style: GoogleFonts.domine(
                    color: const Color(0xFFF59E0B),
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                if (inCart == 0)
                  SizedBox(
                    width: double.infinity,
                    height: 34,
                    child: ElevatedButton(
                      onPressed: () {
                        AppleTheme.hapticFeedback();
                        cart.add(product);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'ADD TO ORDER',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward, size: 12, color: Colors.white),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFF59E0B)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                          onPressed: () {
                            AppleTheme.hapticFeedback();
                            cart.updateQuantity(product.id, inCart - 1);
                          },
                          icon: Icon(
                            inCart == 1 ? LucideIcons.trash2 : LucideIcons.minus,
                            size: 14,
                            color: inCart == 1 ? const Color(0xFFEF4444) : const Color(0xFFB45309),
                          ),
                        ),
                        Text(
                          '$inCart in Cart',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: const Color(0xFFB45309),
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                          onPressed: () {
                            AppleTheme.hapticFeedback();
                            cart.add(product);
                          },
                          icon: const Icon(LucideIcons.plus, size: 14, color: Color(0xFFB45309)),
                        ),
                      ],
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

class _SizzlingCategoryCard extends StatelessWidget {
  final String title;
  final String description;
  final String imageUrl;
  final String badgeText;
  final VoidCallback onTap;

  const _SizzlingCategoryCard({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.badgeText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedImg = ImageUrlHelper.normalize(imageUrl);

    return Container(
      width: 255,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            AppleTheme.hapticFeedback();
            onTap();
          },
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Category Image with Badges
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                    child: SizedBox(
                      height: 135,
                      width: double.infinity,
                      child: normalizedImg != null && normalizedImg.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: normalizedImg,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => Container(color: const Color(0xFFF3F4F6)),
                              errorWidget: (_, _, _) => Container(
                                color: const Color(0xFFF3F4F6),
                                child: const Icon(Icons.fastfood, color: Color(0xFFF59E0B), size: 36),
                              ),
                            )
                          : Container(
                              color: const Color(0xFFF3F4F6),
                              child: const Icon(Icons.fastfood, color: Color(0xFFF59E0B), size: 36),
                            ),
                    ),
                  ),
                  // Wooden / Amber Badge on Image
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF78350F).withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF92400E)),
                      ),
                      child: Text(
                        badgeText.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  // Red circular indicator dot
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFDC2626).withValues(alpha: 0.6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.domine(
                        color: const Color(0xFF1F2937),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF6B7280),
                        fontSize: 11,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactOrderingCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CompactOrderingCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: selected
            ? AppleColors.primaryAccent
            : const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected
              ? AppleColors.primaryAccent
              : const Color(0xFFE5E5E7),
        ),
        boxShadow: [
          if (selected)
            BoxShadow(
              color: AppleColors.primaryAccent.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: selected ? Colors.white : AppleColors.primaryAccent,
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: selected ? Colors.white : AppleColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.88)
                        : AppleColors.mutedText,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final String? deliveryTag;
  final bool? isFreeDelivery;
  final VoidCallback onTap;

  const _LocationOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    this.deliveryTag,
    this.isFreeDelivery,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected
              ? AppleColors.primaryAccent
              : const Color(0xFFE5E5E7),
        ),
      ),
      child: Material(
        color: selected
            ? AppleColors.primaryAccent.withValues(alpha: 0.08)
            : const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selected ? AppleColors.primaryAccent : AppleColors.mutedText,
                  size: 22,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppleColors.textPrimary,
                              ),
                            ),
                          ),
                          if (deliveryTag != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isFreeDelivery == true
                                    ? const Color(0xFFE8F5E9)
                                    : const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                deliveryTag!,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isFreeDelivery == true
                                      ? const Color(0xFF2E7D32)
                                      : const Color(0xFFE65100),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppleColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle, color: AppleColors.primaryAccent, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Realistic Ticket Voucher Card with scalloped edge punch cutouts
class _TicketVoucherCard extends StatelessWidget {
  final String discount;
  final String title;
  final String minSpend;
  final String code;
  final String expiry;
  final bool claimed;
  final bool isUsed;
  final bool isApplied;
  final Color accentColor;
  final VoidCallback onClaim;

  const _TicketVoucherCard({
    required this.discount,
    required this.title,
    required this.minSpend,
    required this.code,
    required this.expiry,
    this.claimed = false,
    this.isUsed = false,
    this.isApplied = false,
    required this.accentColor,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 270,
      height: 105,
      child: ClipPath(
        clipper: _TicketClipper(),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Accent Stripe
              Container(
                width: 6,
                height: double.infinity,
                color: isUsed ? const Color(0xFF9CA3AF) : accentColor,
              ),
              // Voucher Left Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        discount,
                        style: GoogleFonts.inter(
                          color: isUsed ? const Color(0xFF9CA3AF) : accentColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: isUsed ? const Color(0xFF9CA3AF) : AppleColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          decoration: isUsed ? TextDecoration.lineThrough : null,
                          decorationColor: const Color(0xFF4B5563),
                          decorationThickness: 2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$minSpend • $expiry',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: AppleColors.mutedText,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Vertical Dashed Divider
              CustomPaint(
                size: const Size(1, double.infinity),
                painter: _DashedLinePainter(),
              ),
              // Ticket Stub Claim Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        code,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          color: isUsed ? const Color(0xFF9CA3AF) : AppleColors.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 28,
                      child: ElevatedButton(
                        onPressed: (isUsed || isApplied) ? null : onClaim,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isUsed
                              ? const Color(0xFFE5E7EB)
                              : (isApplied ? const Color(0xFF10B981) : accentColor),
                          foregroundColor: isUsed ? const Color(0xFF9CA3AF) : Colors.white,
                          disabledBackgroundColor: isUsed ? const Color(0xFFE5E7EB) : const Color(0xFF10B981),
                          disabledForegroundColor: isUsed ? const Color(0xFF9CA3AF) : Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          isUsed ? 'Used' : (isApplied ? 'Applied' : 'Claim'),
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom Ticket Clipper creating semi-circular notch cutouts on left and right sides
class _TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const radius = 12.0;
    const notchRadius = 8.0;
    final path = Path();

    // Top edge
    path.moveTo(radius, 0);
    path.lineTo(size.width - radius, 0);
    path.arcToPoint(Offset(size.width, radius), radius: const Radius.circular(radius));

    // Right edge with punch notch
    final rightNotchY = size.height * 0.5;
    path.lineTo(size.width, rightNotchY - notchRadius);
    path.arcToPoint(
      Offset(size.width, rightNotchY + notchRadius),
      radius: const Radius.circular(notchRadius),
      clockwise: false,
    );
    path.lineTo(size.width, size.height - radius);
    path.arcToPoint(Offset(size.width - radius, size.height), radius: const Radius.circular(radius));

    // Bottom edge
    path.lineTo(radius, size.height);
    path.arcToPoint(Offset(0, size.height - radius), radius: const Radius.circular(radius));

    // Left edge with punch notch
    final leftNotchY = size.height * 0.5;
    path.lineTo(0, leftNotchY + notchRadius);
    path.arcToPoint(
      Offset(0, leftNotchY - notchRadius),
      radius: const Radius.circular(notchRadius),
      clockwise: false,
    );
    path.lineTo(0, radius);
    path.arcToPoint(Offset(radius, 0), radius: const Radius.circular(radius));

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD0D0D0)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    double dashHeight = 4, dashSpace = 3, startY = 6;
    while (startY < size.height - 6) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
