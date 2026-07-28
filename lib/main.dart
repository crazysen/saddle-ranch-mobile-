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
import 'utils/deep_link_parser.dart';
import 'utils/menu_category.dart';

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
        theme: AppTheme.light,
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
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(onOpenMenu: _openMenu),
          const MenuScreen(),
          const CartScreen(),
          const AccountScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shadowColor: Colors.black26,
        elevation: 8,
        indicatorColor: AppColors.amber.withValues(alpha: 0.2),
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? AppColors.amberSoft : AppColors.muted,
          );
        }),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined, color: AppColors.muted),
            selectedIcon: Icon(Icons.home, color: AppColors.amber),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined, color: AppColors.muted),
            selectedIcon: Icon(Icons.restaurant_menu, color: AppColors.amber),
            label: 'Menu',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_bag_outlined, color: AppColors.muted),
            ),
            selectedIcon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_bag, color: AppColors.amber),
            ),
            label: 'Cart',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline, color: AppColors.muted),
            selectedIcon: Icon(Icons.person, color: AppColors.amber),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
