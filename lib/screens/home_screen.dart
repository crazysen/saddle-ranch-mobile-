import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/cart_provider.dart';
import '../providers/menu_provider.dart';
import '../providers/order_session_provider.dart';
import '../utils/menu_category.dart';
import '../widgets/banner_carousel.dart';
import '../widgets/table_banner.dart';
import 'qr_scanner_screen.dart';

typedef OpenMenuCallback = void Function({MenuCategory? category});

class HomeScreen extends StatelessWidget {
  final OpenMenuCallback onOpenMenu;

  const HomeScreen({super.key, required this.onOpenMenu});

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<MenuProvider>();
    final cart = context.watch<CartProvider>();
    final session = context.watch<OrderSessionProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        color: AppColors.amber,
        backgroundColor: Colors.white,
        onRefresh: menu.load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              centerTitle: false,
              title: Text(
                'Saddle Ranch',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  color: const Color(0xFF3F2000),
                  letterSpacing: 0.2,
                ),
              ),
              actions: [
                IconButton(
                  tooltip: 'Scan table QR',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
                    );
                  },
                  icon: const Icon(Icons.qr_code_scanner, color: AppColors.amber),
                ),
                if (cart.itemCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Center(
                      child: Text(
                        '${cart.itemCount}',
                        style: const TextStyle(
                          color: AppColors.amber,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  session.isDineIn
                      ? 'Order from your table — no waiting for a waiter.'
                      : 'The Wild West of Sizzling Steaks',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: TableBanner()),
            SliverToBoxAdapter(
              child: BannerCarousel(
                banners: menu.banners,
                onSeeAll: () => onOpenMenu(),
                onPromoTap: (category) => onOpenMenu(category: category),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                child: Row(
                  children: [
                    const Text(
                      'How are you ordering?',
                      style: TextStyle(
                        color: Color(0xFF1A1A1B),
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => onOpenMenu(),
                      child: const Text('Full menu'),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _ModeCard(
                        icon: Icons.qr_code_2,
                        title: 'Dine-In',
                        subtitle: 'Scan table QR',
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
                      child: _ModeCard(
                        icon: Icons.shopping_bag_outlined,
                        title: 'Pick-Up',
                        subtitle: 'Order ahead',
                        selected: session.mode == OrderMode.pickup,
                        onTap: () {
                          session.setMode(OrderMode.pickup);
                          onOpenMenu();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ModeCard(
                        icon: Icons.delivery_dining,
                        title: 'Delivery',
                        subtitle: 'To your door',
                        selected: session.mode == OrderMode.delivery,
                        onTap: () {
                          session.setMode(OrderMode.delivery);
                          onOpenMenu();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 10),
                child: Text(
                  'Browse by category',
                  style: TextStyle(
                    color: Color(0xFF1A1A1B),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.35,
                ),
                delegate: SliverChildListDelegate([
                  _CategoryTile(
                    title: 'Sizzling',
                    subtitle: 'Rice meals',
                    icon: Icons.local_fire_department,
                    onTap: () => onOpenMenu(category: MenuCategory.sizzling),
                  ),
                  _CategoryTile(
                    title: 'Filipino',
                    subtitle: 'Heritage',
                    icon: Icons.restaurant,
                    onTap: () => onOpenMenu(category: MenuCategory.filipino),
                  ),
                  _CategoryTile(
                    title: 'Barkada',
                    subtitle: 'Sharing',
                    icon: Icons.groups_2,
                    onTap: () => onOpenMenu(category: MenuCategory.barkada),
                  ),
                  _CategoryTile(
                    title: 'Drinks',
                    subtitle: '& extra rice',
                    icon: Icons.local_cafe,
                    onTap: () => onOpenMenu(category: MenuCategory.drinks),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.amber : const Color(0xFFF7F7F8),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.amber : const Color(0xFFE5E5E7),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: selected ? AppColors.onAmber : AppColors.amber, size: 22),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  color: selected ? AppColors.onAmber : const Color(0xFF1A1A1B),
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: selected
                      ? AppColors.onAmber.withValues(alpha: 0.85)
                      : AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F7F8),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E5E7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.amber),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF1A1A1B),
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
