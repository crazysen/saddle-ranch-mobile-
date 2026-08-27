import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/menu_provider.dart';
import 'providers/order_session_provider.dart';
import 'screens/account_screen.dart';
import 'screens/auth_gate.dart';
import 'screens/cart_screen.dart';
import 'screens/home_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/orders_screen.dart';
import 'theme/apple_theme.dart';
import 'utils/deep_link_parser.dart';
import 'utils/menu_category.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // LOCAL DEV: import core/config/api_config.dart and set
  // ApiConfig.overrideBaseUrl = 'http://127.0.0.1:8000/api/v1';

  runApp(const SaddleRanchApp());
}

class SaddleRanchApp extends StatelessWidget {
  const SaddleRanchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..bootstrap()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderSessionProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()..load()),
      ],
      child: MaterialApp(
        title: 'Saddle Ranch',
        debugShowCheckedModeBanner: false,
        theme: AppleTheme.light,
        home: const AuthGate(child: MainShell()),
      ),
    );
  }
}

class AppTabController {
  static void Function(int index)? switchTab;
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  StreamSubscription<Uri>? _linkSub;
  final _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    AppTabController.switchTab = (int idx) {
      if (mounted) {
        setState(() => _index = idx);
      }
    };
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handleUri(initial);
    } catch (_) {}

    _linkSub = _appLinks.uriLinkStream.listen(_handleUri);
  }

  void _handleUri(Uri uri) {
    if (!mounted) return;
    if (!isDineInLink(uri) && extractTableFromUri(uri) == null) return;

    final table = extractTableFromUri(uri);
    if (table == null) return;

    context.read<OrderSessionProvider>().startDineInFromTable(table);
    setState(() => _index = 1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Welcome to Table ${table.padLeft(2, '0')}'),
      ),
    );
  }

  void _openMenu({MenuCategory? category}) {
    AppleTheme.hapticFeedback();
    if (category != null) {
      context.read<MenuProvider>().setCategory(category);
    } else {
      context.read<MenuProvider>().setCategory(MenuCategory.all);
    }
    // Navigate to full menu overlay
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MenuScreen(
          onOrderPlaced: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
            setState(() => _index = 1); // Navigate to Orders screen
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartProvider>().itemCount;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppleColors.scaffoldBackground,
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: _index,
            children: [
              HomeScreen(onOpenMenu: _openMenu),
              const OrdersScreen(),
              const CartScreen(),
              const AccountScreen(),
            ],
          ),

          // Custom Floating Bottom Navigation Bar with Safe Area inset for Android & iOS
          Positioned(
            left: 16,
            right: 16,
            bottom: 16 + bottomInset,
            child: Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(36),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: LucideIcons.house,
                    label: 'Home',
                    selected: _index == 0,
                    onTap: () {
                      AppleTheme.hapticFeedback();
                      setState(() => _index = 0);
                    },
                  ),
                  _NavItem(
                    icon: LucideIcons.receiptText,
                    label: 'Orders',
                    selected: _index == 1,
                    onTap: () {
                      AppleTheme.hapticFeedback();
                      setState(() => _index = 1);
                    },
                  ),
                  _NavItem(
                    icon: LucideIcons.shoppingBag,
                    label: 'Cart',
                    badgeCount: cartCount,
                    selected: _index == 2,
                    onTap: () {
                      AppleTheme.hapticFeedback();
                      setState(() => _index = 2);
                    },
                  ),
                  _NavItem(
                    icon: LucideIcons.user,
                    label: 'Profile',
                    selected: _index == 3,
                    onTap: () {
                      AppleTheme.hapticFeedback();
                      setState(() => _index = 3);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final int badgeCount;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: selected
                  ? AppleColors.primaryAccent.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: selected
                      ? AppleColors.primaryAccent
                      : AppleColors.mutedText,
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -8,
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
                        '$badgeCount',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              color: selected
                  ? AppleColors.primaryAccent
                  : AppleColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}
