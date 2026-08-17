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

final _currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 0);

typedef OpenMenuCallback = void Function({MenuCategory? category});

final List<Map<String, dynamic>> _savedAddresses = [
  {
    'title': 'Home - Bulihan, Silang',
    'subtitle': 'Phase 3 Block 12, Bulihan, Silang, Cavite',
    'icon': LucideIcons.house,
    'mode': OrderMode.delivery,
    'isBulihan': true,
  },
  {
    'title': 'Office - Dasmariñas',
    'subtitle': 'Aguinaldo Highway, Dasmariñas, Cavite',
    'icon': LucideIcons.building,
    'mode': OrderMode.delivery,
    'isBulihan': false,
  },
  {
    'title': 'Saddle Ranch Silang Main',
    'subtitle': 'Bulihan, Silang, Cavite',
    'icon': LucideIcons.mapPin,
    'mode': OrderMode.pickup,
    'isBulihan': true,
  },
];

final List<Map<String, dynamic>> _notifications = [
  {
    'id': '1',
    'title': 'Order #SR-10492 Sizzling!',
    'body': 'Your Sizzling Pork Sisig and Garlic Rice are hot on the grill!',
    'time': '2m ago',
    'icon': LucideIcons.flame,
    'isOrder': true,
    'unread': true,
  },
  {
    'id': '2',
    'title': 'Rider En Route #SR-10381',
    'body': 'Rider Marco is on his way with your Bulalo Steak Feast.',
    'time': '25m ago',
    'icon': LucideIcons.bike,
    'isOrder': true,
    'unread': true,
  },
  {
    'id': '3',
    'title': 'Voucher Unlocked!',
    'body': 'Exclusive ₱100 OFF coupon added to your wallet.',
    'time': '1h ago',
    'icon': LucideIcons.ticket,
    'isOrder': false,
    'unread': true,
  },
];

final List<Map<String, dynamic>> _vouchers = [
  {
    'id': 'v1',
    'discount': '₱100 OFF',
    'title': 'Sizzling Special',
    'minSpend': 'Min. spend ₱500',
    'code': 'SIZZLE100',
    'expiry': 'Valid till Aug 31',
    'claimed': false,
    'color': const Color(0xFFFF6B00),
  },
  {
    'id': 'v2',
    'discount': '15% OFF',
    'title': 'Barkada Feast',
    'minSpend': 'Min. spend ₱1,200',
    'code': 'BARKADA15',
    'expiry': 'Platter orders only',
    'claimed': false,
    'color': const Color(0xFFD84315),
  },
  {
    'id': 'v3',
    'discount': 'FREE DRINK',
    'title': 'Red Iced Tea Pitcher',
    'minSpend': 'On any meal deal',
    'code': 'FREEDRINK',
    'expiry': 'Valid today only',
    'claimed': false,
    'color': const Color(0xFF0288D1),
  },
];

final List<Map<String, dynamic>> _recentlyOrdered = [
  {
    'name': 'Sizzling Pork Sisig',
    'price': 280.0,
    'rating': 4.8,
    'category': MenuCategory.filipino,
    'image':
        'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=800&q=80',
  },
  {
    'name': 'Bulalo Steak Feast',
    'price': 490.0,
    'rating': 4.7,
    'category': MenuCategory.filipino,
    'image':
        'https://lh3.googleusercontent.com/aida-public/AB6AXuCatSLXJ-mynm_AwjLXsdG9xKbMwziehShgiNtyXaX2NZEeZFhSXaTmHMgLuACAitSC3WZ0g_9lSTavvnqO4eKFlaC0pnnA9OngEMtRicl0vfSF2_t4WqzxTKxW-H-X0i_tppiClzEOZ-fAuu1ezCbRVOcdVdwZHokttY1ATDIO4BuA185dwrm0QDuPpYjQ7qD9ybH5bl0WPn1wHJ3S5pB6JuCOoocWTfZ95cB0Lfqx1KbjbUwqGJxkhwxmqypEJta64yq1PajT3oWC',
  },
  {
    'name': 'Sizzling Pepper Rice',
    'price': 220.0,
    'rating': 4.9,
    'category': MenuCategory.sizzling,
    'image':
        'https://lh3.googleusercontent.com/aida-public/AB6AXuDt2cP7W6u7Hw-wJCWrbYiEh20Z4b79UCpbKxmmyVbQzw0xlTklDnEKOpEzeymppd9l-ODs0TOelRWM0iLgwF8K_OKfXIBpTO8lSH0yyxPtaMCTQrzQ4ykSkJPDryw9S9IBB1wNoeHFGtHcQDy4MEVr0_tUDss7SKe1fe58XBlXeql1nJ1D2J0zJ0ZFO4qRm213kO813mLEdYdUMjsTD0J2PtB7cz_0FmmDHccmacBmhMyp7a_fJ7teNVsG3sgWyfW24O1p08mnUE9t',
  },
];

class HomeScreen extends StatefulWidget {
  final OpenMenuCallback onOpenMenu;

  const HomeScreen({super.key, required this.onOpenMenu});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedLocation = 'Home - Bulihan, Silang';
  int _unreadNotifications = 3;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showAddAddressDialog(BuildContext parentCtx) {
    final cityCtrl = TextEditingController(text: 'Silang, Cavite');
    final barangayCtrl = TextEditingController();
    final streetCtrl = TextEditingController();
    final labelCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final combined =
                '${barangayCtrl.text} ${cityCtrl.text} ${streetCtrl.text}'.toLowerCase();
            final isBulihan = combined.contains('bulihan');

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(dialogCtx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
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
                      Text(
                        'Add New Delivery Location',
                        style: GoogleFonts.domine(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppleColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Live Dynamic Delivery Fee Banner
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isBulihan
                              ? const Color(0xFFE8F5E9) // Soft Green
                              : const Color(0xFFFFF3E0), // Soft Amber
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isBulihan
                                ? const Color(0xFF81C784)
                                : const Color(0xFFFFB74D),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              isBulihan ? LucideIcons.truck : LucideIcons.bike,
                              color: isBulihan
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFFE65100),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isBulihan
                                        ? 'FREE Delivery Fee (Bulihan Area, Silang)'
                                        : 'Delivery via Lalamove',
                                    style: GoogleFonts.inter(
                                      color: isBulihan
                                          ? const Color(0xFF1B5E20)
                                          : const Color(0xFFBF360C),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    isBulihan
                                        ? 'Your address qualifies for 100% Free Delivery!'
                                        : 'Deliveries outside Bulihan Area are dispatched via Lalamove (customer pays actual rider delivery fee upon arrival).',
                                    style: GoogleFonts.inter(
                                      color: isBulihan
                                          ? const Color(0xFF2E7D32)
                                          : const Color(0xFFD84315),
                                      fontSize: 11,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Municipality / City
                      TextFormField(
                        controller: cityCtrl,
                        onChanged: (_) => setDialogState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Municipality / City *',
                          hintText: 'e.g. Silang, Dasmariñas, Tagaytay',
                          prefixIcon: Icon(LucideIcons.building2),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Please enter municipality or city'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      // Barangay / Zone
                      TextFormField(
                        controller: barangayCtrl,
                        onChanged: (_) => setDialogState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Barangay / Zone *',
                          hintText: 'e.g. Bulihan, Biga 1, San Vicente',
                          prefixIcon: Icon(LucideIcons.mapPin),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Please enter barangay or zone'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      // Street Address / House No. / Landmark *
                      TextFormField(
                        controller: streetCtrl,
                        onChanged: (_) => setDialogState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Street Address / House No. / Landmark *',
                          hintText: 'e.g. Blk 14 Lot 2 Phase 3, near Church',
                          prefixIcon: Icon(LucideIcons.home),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Please enter street address or landmark'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      // Address Label (Optional)
                      TextFormField(
                        controller: labelCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Address Label (Optional)',
                          hintText: 'e.g. Home, Work, Apartment',
                          prefixIcon: Icon(LucideIcons.tag),
                        ),
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            if (formKey.currentState?.validate() == true) {
                              final title = labelCtrl.text.trim().isNotEmpty
                                  ? labelCtrl.text.trim()
                                  : '${barangayCtrl.text.trim()}, ${cityCtrl.text.trim()}';
                              final subtitle =
                                  '${streetCtrl.text.trim()}, ${barangayCtrl.text.trim()}, ${cityCtrl.text.trim()}';

                              setState(() {
                                _savedAddresses.insert(0, {
                                  'title': title,
                                  'subtitle': subtitle,
                                  'icon': LucideIcons.mapPin,
                                  'mode': OrderMode.delivery,
                                  'isBulihan': isBulihan,
                                });
                                _selectedLocation = title;
                              });

                              context.read<OrderSessionProvider>().setMode(OrderMode.delivery);

                              Navigator.pop(dialogCtx);
                              Navigator.pop(parentCtx);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isBulihan
                                        ? 'Address "$title" saved with FREE delivery!'
                                        : 'Address "$title" saved (Lalamove delivery).',
                                  ),
                                  backgroundColor: isBulihan
                                      ? const Color(0xFF2E7D32)
                                      : AppleColors.primaryAccent,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppleColors.primaryAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Save & Deliver Here',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showLocationPicker() {
    final session = context.read<OrderSessionProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
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
                Text(
                  'Select Delivery Location',
                  style: GoogleFonts.domine(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppleColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
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
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showAddAddressDialog(ctx),
                    icon: const Icon(LucideIcons.plus, size: 16, color: AppleColors.primaryAccent),
                    label: const Text('Add New Delivery Location'),
                  ),
                ),
              ],
            ),
          ),
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
                          setState(() {
                            _unreadNotifications = 0;
                            for (var n in _notifications) {
                              n['unread'] = false;
                            }
                          });
                          Navigator.pop(ctx);
                        },
                        child: const Text('Mark all read'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.separated(
                      controller: controller,
                      itemCount: _notifications.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final notif = _notifications[index];
                        final isUnread = notif['unread'] as bool;

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isUnread
                                ? AppleColors.primaryAccent.withValues(alpha: 0.06)
                                : const Color(0xFFF9F9FB),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isUnread
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
                                  notif['icon'] as IconData,
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
                                          notif['title'] as String,
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                            color: AppleColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          notif['time'] as String,
                                          style: GoogleFonts.inter(
                                            color: AppleColors.mutedText,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      notif['body'] as String,
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

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<MenuProvider>();
    final auth = context.watch<AuthProvider>();
    final session = context.watch<OrderSessionProvider>();
    final user = auth.user;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final userName = user?.fullName.isNotEmpty == true
        ? user!.fullName
        : 'John Daniel';

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
          onRefresh: menu.load,
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
                                userName[0].toUpperCase(),
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
                                    session.isDineIn ? 'Dine-In Location' : 'Deliver to',
                                    style: GoogleFonts.inter(
                                      color: AppleColors.mutedText,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      displayLocation,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        color: AppleColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.keyboard_arrow_down,
                                    color: AppleColors.primaryAccent,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Functional Notification Bell Button
                      Stack(
                        children: [
                          IconButton(
                            onPressed: _showNotificationsSheet,
                            icon: const Icon(
                              LucideIcons.bell,
                              color: AppleColors.textPrimary,
                              size: 22,
                            ),
                          ),
                          if (_unreadNotifications > 0)
                            Positioned(
                              right: 10,
                              top: 10,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppleColors.primaryAccent,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  '$_unreadNotifications',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 9,
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

              // Full Width Search Bar ("Search menu...")
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
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
                      onChanged: (val) {
                        menu.setSearch(val);
                      },
                      decoration: InputDecoration(
                        hintText: 'Search menu...',
                        hintStyle: GoogleFonts.inter(
                          color: AppleColors.mutedText,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          LucideIcons.search,
                          color: AppleColors.mutedText,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                ),
              ),

              // Category Icons (Below Search) - Sizzling, Filipino Cousines, Barkada, Rice and Drinks
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _CategoryCard(
                        title: 'Sizzling',
                        iconWidget: const Icon(LucideIcons.flame, color: Color(0xFFE65100), size: 28),
                        onTap: () => widget.onOpenMenu(category: MenuCategory.sizzling),
                      ),
                      _CategoryCard(
                        title: 'Filipino Cousines',
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

              // Promotion Banner Carousel
              SliverToBoxAdapter(
                child: BannerCarousel(
                  banners: menu.banners,
                  onSeeAll: () => widget.onOpenMenu(),
                  onPromoTap: (cat) => widget.onOpenMenu(category: cat),
                ),
              ),

              // Recently Ordered Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Row(
                    children: [
                      Text(
                        'Recently Ordered',
                        style: GoogleFonts.inter(
                          color: AppleColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => widget.onOpenMenu(),
                        child: Text(
                          'See all',
                          style: GoogleFonts.inter(
                            color: AppleColors.primaryAccent,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 195,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _recentlyOrdered.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final item = _recentlyOrdered[index];
                      return SizedBox(
                        width: 155,
                        child: GestureDetector(
                          onTap: () => widget.onOpenMenu(category: item['category'] as MenuCategory),
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
                                  child: CachedNetworkImage(
                                    imageUrl: item['image'] as String,
                                    height: 105,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    placeholder: (_, _) => Container(color: AppleColors.cardSurface),
                                    errorWidget: (_, _, _) => Container(
                                      color: AppleColors.cardSurface,
                                      child: const Icon(Icons.fastfood, color: AppleColors.mutedText),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name'] as String,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: AppleColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _currency.format(item['price']),
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                              color: AppleColors.textPrimary,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              const Icon(Icons.star, color: Colors.amber, size: 14),
                                              const SizedBox(width: 2),
                                              Text(
                                                '${item['rating']}',
                                                style: GoogleFonts.inter(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                  color: AppleColors.mutedText,
                                                ),
                                              ),
                                            ],
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

              // Vouchers Section directly below "How are you ordering"
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
                  child: SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _vouchers.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        final v = _vouchers[index];
                        final isClaimed = v['claimed'] as bool;

                        return _TicketVoucherCard(
                          discount: v['discount'] as String,
                          title: v['title'] as String,
                          minSpend: v['minSpend'] as String,
                          code: v['code'] as String,
                          expiry: v['expiry'] as String,
                          claimed: isClaimed,
                          accentColor: v['color'] as Color,
                          onClaim: () {
                            Clipboard.setData(ClipboardData(text: v['code'] as String));
                            setState(() {
                              v['claimed'] = true;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Voucher code ${v['code']} copied & applied!'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        );
                      },
                    ),
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
