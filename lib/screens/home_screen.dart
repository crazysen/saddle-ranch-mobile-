import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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

class HomeScreen extends StatefulWidget {
  final OpenMenuCallback onOpenMenu;

  const HomeScreen({super.key, required this.onOpenMenu});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  static final List<Map<String, dynamic>> _recentlyOrdered = [
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

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<MenuProvider>();
    final auth = context.watch<AuthProvider>();
    final session = context.watch<OrderSessionProvider>();
    final user = auth.user;

    final userName = user?.fullName.isNotEmpty == true
        ? user!.fullName
        : 'John Daniel';

    return Scaffold(
      backgroundColor: AppleColors.scaffoldBackground,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppleColors.primaryAccent,
          backgroundColor: Colors.white,
          onRefresh: menu.load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header Section matching visual design mockup
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
                      // Delivery Location Dropdown Title
                      Expanded(
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
                                  'Deliver to',
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
                                Text(
                                  userName,
                                  style: GoogleFonts.inter(
                                    color: AppleColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
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
                      // Notification bell icon with badge indicator
                      Stack(
                        children: [
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(
                              LucideIcons.bell,
                              color: AppleColors.textPrimary,
                              size: 22,
                            ),
                          ),
                          Positioned(
                            right: 12,
                            top: 12,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppleColors.primaryAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Search Bar + Filter Icon Button
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
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
                              hintText: 'Search foods, restaurants...',
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
                      const SizedBox(width: 10),
                      Container(
                        width: 48,
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
                        child: IconButton(
                          onPressed: () {
                            widget.onOpenMenu();
                          },
                          icon: const Icon(
                            LucideIcons.slidersHorizontal,
                            color: AppleColors.primaryAccent,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
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
                        iconWidget: const Icon(LucideIcons.pizza, color: Color(0xFFD84315), size: 26),
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

              // "How are you Ordering" Section (Replaces "Popular Place near you")
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Row(
                    children: [
                      Text(
                        'How are you Ordering',
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
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _OrderingModeCard(
                      title: 'Saddle Ranch Dine-In',
                      subtitle: '15-25 min • Table Service • Free WiFi',
                      feeText: 'No waiting for a waiter',
                      rating: 4.9,
                      isVerified: true,
                      selected: session.mode == OrderMode.dineIn,
                      icon: LucideIcons.qrCode,
                      imageUrl:
                          'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=800&q=80',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const QrScannerScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _OrderingModeCard(
                      title: 'Saddle Ranch Pick-Up',
                      subtitle: '10-15 min • Skip the line',
                      feeText: '₱0 Service Fee',
                      rating: 4.8,
                      isVerified: true,
                      selected: session.mode == OrderMode.pickup,
                      icon: LucideIcons.shoppingBag,
                      imageUrl:
                          'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=800&q=80',
                      onTap: () {
                        session.setMode(OrderMode.pickup);
                        widget.onOpenMenu();
                      },
                    ),
                    const SizedBox(height: 12),
                    _OrderingModeCard(
                      title: 'Saddle Ranch Express Delivery',
                      subtitle: '25-35 min • Direct to your door',
                      feeText: '₱49 Delivery fee',
                      rating: 4.7,
                      isVerified: true,
                      selected: session.mode == OrderMode.delivery,
                      icon: LucideIcons.bike,
                      imageUrl:
                          'https://images.unsplash.com/photo-1526367790999-0150786686a2?auto=format&fit=crop&w=800&q=80',
                      onTap: () {
                        session.setMode(OrderMode.delivery);
                        widget.onOpenMenu();
                      },
                    ),
                  ]),
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

class _OrderingModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String feeText;
  final double rating;
  final bool isVerified;
  final bool selected;
  final IconData icon;
  final String imageUrl;
  final VoidCallback onTap;

  const _OrderingModeCard({
    required this.title,
    required this.subtitle,
    required this.feeText,
    required this.rating,
    required this.isVerified,
    required this.selected,
    required this.icon,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? AppleColors.primaryAccent : const Color(0xFFEEEEEE),
          width: selected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: AppleColors.textPrimary,
                              ),
                            ),
                          ),
                          if (isVerified)
                            const Icon(
                              Icons.check_circle,
                              color: AppleColors.primaryAccent,
                              size: 16,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          color: AppleColors.mutedText,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            feeText,
                            style: GoogleFonts.inter(
                              color: AppleColors.mutedText,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F7F8),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 14),
                                const SizedBox(width: 3),
                                Text(
                                  '$rating',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: AppleColors.textPrimary,
                                  ),
                                ),
                              ],
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
      ),
    );
  }
}
