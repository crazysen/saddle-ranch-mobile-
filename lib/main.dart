import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
import 'theme/apple_theme.dart';
import 'utils/deep_link_parser.dart';
import 'utils/menu_category.dart';
import 'widgets/glass_cart_bar.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
    setState(() => _index = 1);
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartProvider>().itemCount;

    return Scaffold(
      backgroundColor: AppleColors.scaffoldBackground,
      body: Stack(
        children: [
          IndexedStack(
            index: _index,
            children: [
              HomeScreen(onOpenMenu: _openMenu),
              const MenuScreen(),
              const CartScreen(),
              const AccountScreen(),
            ],
          ),
          // Sticky Glass Cart Bar overlay when not on Cart screen
          if (_index != 2 && cartCount > 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: GlassCartBar(
                onTapViewCart: () {
                  setState(() => _index = 2);
                },
              ),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppleColors.pureWhite,
        surfaceTintColor: AppleColors.pureWhite,
        shadowColor: Colors.black12,
        elevation: 8,
        indicatorColor: AppleColors.primaryAccent.withValues(alpha: 0.15),
        selectedIndex: _index,
        onDestinationSelected: (i) {
          AppleTheme.hapticFeedback();
          setState(() => _index = i);
        },
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            color: selected ? AppleColors.primaryAccent : AppleColors.mutedText,
          );
        }),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined, color: AppleColors.mutedText),
            selectedIcon: Icon(Icons.home, color: AppleColors.primaryAccent),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined, color: AppleColors.mutedText),
            selectedIcon: Icon(Icons.restaurant_menu, color: AppleColors.primaryAccent),
            label: 'Menu',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_bag_outlined, color: AppleColors.mutedText),
            ),
            selectedIcon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_bag, color: AppleColors.primaryAccent),
            ),
            label: 'Cart',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline, color: AppleColors.mutedText),
            selectedIcon: Icon(Icons.person, color: AppleColors.primaryAccent),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
