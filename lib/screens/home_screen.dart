import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/menu_provider.dart';
import '../providers/order_session_provider.dart';
import '../utils/menu_category.dart';
import '../widgets/banner_carousel.dart';
import 'qr_scanner_screen.dart';

import '../models/order_result.dart';
import '../models/voucher.dart';
import '../services/api_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadVouchers();
    _loadActiveOrders();
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

  Future<void> _loadActiveOrders() async {
    try {
      final list = await _api.trackOrders(all: true);
      if (mounted) {
        setState(() {
          _activeOrders = list;
          _unreadNotifications = list.where((o) => o.status != 'completed' && o.status != 'cancelled').length;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
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
                          final messenger = ScaffoldMessenger.of(context);
                          await session.autoDetectBranch();
                          menu.setBranch(session.branch);
                          setPickerState(() {});
                          if (!mounted) return;
                          final branchName = session.branch == 'Bulihan' ? 'Bulihan Main (Silang)' : 'Dasmariñas Branch';
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Auto-detected closest branch: $branchName'),
                              backgroundColor: const Color(0xFFF59E0B),
                              duration: const Duration(seconds: 2),
                            ),
                          );
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
                              final isPreparing = order.status == 'preparing';

                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isPreparing
                                      ? AppleColors.primaryAccent.withValues(alpha: 0.06)
                                      : const Color(0xFFF9F9FB),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isPreparing
                                        ? AppleColors.primaryAccent.withValues(alpha: 0.25)
                                        : const Color(0xFFEEEEEE),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppleColors.primaryAccent.withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isPreparing ? LucideIcons.flame : LucideIcons.receipt,
                                        color: AppleColors.primaryAccent,
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
                                                style: GoogleFonts.inter(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 14,
                                                  color: AppleColors.textPrimary,
                                                ),
                                              ),
                                              Text(
                                                order.createdAt ?? 'Active',
                                                style: GoogleFonts.inter(
                                                  color: AppleColors.mutedText,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${order.statusLabel} • ${order.orderType.toUpperCase()} (${order.branch} branch)',
                                            style: GoogleFonts.inter(
                                              color: AppleColors.textBody,
                                              fontSize: 12,
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
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

    final popularProducts = menu.products;

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
                        backgroundImage: user?.photoUrl != null && user!.photoUrl!.isNotEmpty
                            ? CachedNetworkImageProvider(user.photoUrl!)
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
              // Category Icons (Below Search) - Sizzling, Filipino Cuisines, Barkada, Rice and Drinks
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _CategoryCard(
                        title: 'Sizzling',
                        iconWidget: const Icon(LucideIcons.flame, color: Color(0xFFE65100), size: 28),
                        onTap: () => widget.onOpenMenu(category: MenuCategory.sizzling),
                      ),
                      _CategoryCard(
                        title: 'Filipino Cuisines',
                        iconWidget: const Icon(LucideIcons.utensilsCrossed, color: Color(0xFF2E7D32), size: 26),
                        onTap: () => widget.onOpenMenu(category: MenuCategory.filipino),
                      ),
                      _CategoryCard(
                        title: 'Barkada',
                        iconWidget: const Icon(Icons.rice_bowl, color: Color(0xFFD84315), size: 28),
                        onTap: () => widget.onOpenMenu(category: MenuCategory.barkada),
                      ),
                      _CategoryCard(
                        title: 'Rice and Drinks',
                        iconWidget: const Icon(LucideIcons.cupSoda, color: Color(0xFF0288D1), size: 26),
                        onTap: () => widget.onOpenMenu(category: MenuCategory.drinks),
                      ),
                    ],
                  ),
                ),
              ),

              // Promotion Banner Carousel (Live from Render database)
              SliverToBoxAdapter(
                child: BannerCarousel(
                  banners: menu.banners,
                  onSeeAll: () => widget.onOpenMenu(),
                  onBannerTap: () => widget.onOpenMenu(),
                ),
              ),

              // Sizzling Menu Highlights Section (Loaded from Database)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Row(
                    children: [
                      Text(
                        'Sizzling Highlights',
                        style: GoogleFonts.inter(
                          color: AppleColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 195,
                  child: popularProducts.isEmpty
                      ? Center(
                          child: menu.loading
                              ? const CircularProgressIndicator(color: AppleColors.primaryAccent)
                              : Text('No menu items available', style: GoogleFonts.inter(color: AppleColors.mutedText)),
                        )
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: popularProducts.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 14),
                          itemBuilder: (context, index) {
                            final item = popularProducts[index];
                            final price = item.priceForBranch(session.branch);

                            return SizedBox(
                              width: 155,
                              child: GestureDetector(
                                onTap: () => widget.onOpenMenu(),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFF0F0F0)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                        child: item.imagePath != null && item.imagePath!.isNotEmpty
                                            ? CachedNetworkImage(
                                                imageUrl: item.imagePath!,
                                                height: 105,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                placeholder: (_, _) => Container(color: AppleColors.cardSurface),
                                                errorWidget: (_, _, _) => Container(
                                                  color: AppleColors.cardSurface,
                                                  child: const Icon(Icons.fastfood, color: AppleColors.mutedText),
                                                ),
                                              )
                                            : Container(
                                                height: 105,
                                                color: AppleColors.cardSurface,
                                                child: const Center(child: Icon(Icons.restaurant, color: AppleColors.mutedText)),
                                              ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                                color: AppleColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              _currency.format(price),
                                              style: GoogleFonts.inter(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 14,
                                                color: AppleColors.primaryAccent,
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
                          },
                        ),
                ),
              ),

              // "How are you Ordering" Section WITHOUT "See All"
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Text(
                    'How are you Ordering',
                    style: GoogleFonts.inter(
                      color: AppleColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
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

                                  return _TicketVoucherCard(
                                    discount: v.discountLabel,
                                    title: v.code,
                                    minSpend: v.minSpend > 0 ? 'Min. ₱${v.minSpend.toInt()}' : 'No min. spend',
                                    code: v.code,
                                    expiry: v.branch.toLowerCase() == 'all'
                                        ? 'All Branches'
                                        : '${v.branch} branch only',
                                    claimed: v.isUsed,
                                    accentColor: index % 2 == 0 ? const Color(0xFFFF6B00) : const Color(0xFF0288D1),
                                    onClaim: () {
                                      Clipboard.setData(ClipboardData(text: v.code));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Voucher code "${v.code}" copied to clipboard!'),
                                          duration: const Duration(seconds: 2),
                                          backgroundColor: AppleColors.primaryAccent,
                                        ),
                                      );
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
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final Widget iconWidget;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.iconWidget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEBEBEB)),
            ),
            child: Center(child: iconWidget),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 76,
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: GoogleFonts.inter(
                color: AppleColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                height: 1.15,
              ),
            ),
          ),
        ],
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
  final Color accentColor;
  final VoidCallback onClaim;

  const _TicketVoucherCard({
    required this.discount,
    required this.title,
    required this.minSpend,
    required this.code,
    required this.expiry,
    required this.claimed,
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
                color: accentColor,
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
                          color: accentColor,
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
                          color: AppleColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
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
                          color: AppleColors.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 28,
                      child: ElevatedButton(
                        onPressed: claimed ? null : onClaim,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: claimed ? Colors.grey[400] : accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          claimed ? 'Applied' : 'Claim',
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
