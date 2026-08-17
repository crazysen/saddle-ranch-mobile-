import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_theme.dart';
import '../models/promo_banner.dart';
import '../utils/menu_category.dart';

/// Promotion Banner matching the design mockup layout.
class BannerCarousel extends StatefulWidget {
  final List<PromoBanner> banners;
  final VoidCallback? onSeeAll;
  final ValueChanged<MenuCategory>? onPromoTap;

  const BannerCarousel({
    super.key,
    required this.banners,
    this.onSeeAll,
    this.onPromoTap,
    Duration? autoPlayInterval,
  });

  static const _placeholders = [
    _PromoData(
      title: 'Up to 20% OFF\nyour first order',
      buttonText: 'Order Now',
      category: MenuCategory.sizzling,
      imageUrl:
          'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=800&q=80',
    ),
    _PromoData(
      title: 'Weekend Sizzling\nBarkada Platters',
      buttonText: 'Order Now',
      category: MenuCategory.barkada,
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuASVSO6N3lzIbdlCDT85viSxOZiQKjWADlA5k7ymludjTdSCB7tqV0bZvXRba3-L4gemLyqy9PxmqnYMBnSsxb5yfI_XM-qajS5ZEnS1Am8OBu5uN8_smBFlDdy4xR0UNE8jDFJP8vNSRQcqqDSG4p-oDij5kCvWALcyBZVeuA1QdnqC9a6I5s9l2ba3Zjfe0xSPjMr0jLCAB1z-oJS5xBL9meeUeFsmiMgjQ96VoXotgHsy3Jl3d9NQIv1liJsKeu_sJec2rrkNziY',
    ),
    _PromoData(
      title: 'Sisig Combo Deal\nFree Iced Tea',
      buttonText: 'Claim Deal',
      category: MenuCategory.filipino,
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDt2cP7W6u7Hw-wJCWrbYiEh20Z4b79UCpbKxmmyVbQzw0xlTklDnEKOpEzeymppd9l-ODs0TOelRWM0iLgwF8K_OKfXIBpTO8lSH0yyxPtaMCTQrzQ4ykSkJPDryw9S9IBB1wNoeHFGtHcQDy4MEVr0_tUDss7SKe1fe58XBlXeql1nJ1D2J0zJ0ZFO4qRm213kO813mLEdYdUMjsTD0J2PtB7cz_0FmmDHccmacBmhMyp7a_fJ7teNVsG3sgWyfW24O1p08mnUE9t',
    ),
  ];

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_pageController.hasClients) {
        final next = (_currentIndex + 1) % BannerCarousel._placeholders.length;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = BannerCarousel._placeholders;

    return Column(
      children: [
        SizedBox(
          height: 165,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemCount: items.length,
            itemBuilder: (context, index) {
              final promo = items[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    children: [
                      // Content Row
                      Positioned.fill(
                        child: Row(
                          children: [
                            // Left Text & Button
                            Expanded(
                              flex: 12,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(20, 18, 8, 18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      promo.title,
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 17,
                                        height: 1.25,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    SizedBox(
                                      height: 36,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          widget.onPromoTap?.call(promo.category);
                                          if (widget.onPromoTap == null) {
                                            widget.onSeeAll?.call();
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppleColors.primaryAccent,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 18,
                                            vertical: 0,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                        ),
                                        child: Text(
                                          promo.buttonText,
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Right Food Image Plate
                            Expanded(
                              flex: 10,
                              child: Stack(
                                alignment: Alignment.centerRight,
                                children: [
                                  Positioned(
                                    right: -15,
                                    top: -10,
                                    bottom: -10,
                                    child: AspectRatio(
                                      aspectRatio: 1,
                                      child: ClipOval(
                                        child: CachedNetworkImage(
                                          imageUrl: promo.imageUrl,
                                          fit: BoxFit.cover,
                                          placeholder: (_, _) => Container(
                                            color: const Color(0xFF242424),
                                          ),
                                          errorWidget: (_, _, _) => Container(
                                            color: const Color(0xFF242424),
                                            child: const Icon(
                                              Icons.local_fire_department,
                                              color: AppleColors.primaryAccent,
                                              size: 36,
                                            ),
                                          ),
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
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        // Indicator Dots matching the mockup
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(items.length, (i) {
            final active = i == _currentIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 7,
              width: active ? 18 : 7,
              decoration: BoxDecoration(
                color: active
                    ? AppleColors.primaryAccent
                    : const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _PromoData {
  final String title;
  final String buttonText;
  final MenuCategory category;
  final String imageUrl;

  const _PromoData({
    required this.title,
    required this.buttonText,
    required this.category,
    required this.imageUrl,
  });
}
