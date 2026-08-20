import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_theme.dart';
import '../models/promo_banner.dart';
import '../theme/apple_theme.dart';
import '../utils/menu_category.dart';

/// Promotion Banner Carousel matching Saddle Ranch Web 1:1
class BannerCarousel extends StatefulWidget {
  final List<PromoBanner> banners;
  final VoidCallback? onSeeAll;
  final VoidCallback? onBannerTap;
  final ValueChanged<MenuCategory>? onPromoTap;
  final Duration? autoPlayInterval;

  const BannerCarousel({
    super.key,
    required this.banners,
    this.onSeeAll,
    this.onBannerTap,
    this.onPromoTap,
    this.autoPlayInterval,
  });

  static const placeholders = <PromoBanner>[];

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
    final interval = widget.autoPlayInterval ?? const Duration(seconds: 5);
    _timer = Timer.periodic(interval, (_) {
      final bannerCount = widget.banners.isNotEmpty ? widget.banners.length : 1;
      if (_pageController.hasClients && bannerCount > 1) {
        final next = (_currentIndex + 1) % bannerCount;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 400),
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
    final banners = widget.banners;

    if (banners.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2C2C2E)),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFFFFA000)),
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 165,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final promo = banners[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: () {
                    AppleTheme.hapticFeedback();
                    widget.onBannerTap?.call();
                    widget.onSeeAll?.call();
                  },
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: const Color(0xFF141416),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background Food Banner Image
                        if (promo.imagePath != null && promo.imagePath!.isNotEmpty)
                          CachedNetworkImage(
                            imageUrl: promo.imagePath!,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => Container(color: const Color(0xFF1C1C1E)),
                            errorWidget: (_, _, _) => Container(
                              color: const Color(0xFF1C1C1E),
                              child: const Icon(Icons.fastfood, color: Color(0xFFFFA000), size: 40),
                            ),
                          )
                        else
                          Container(
                            color: const Color(0xFF1C1C1E),
                            child: const Icon(Icons.fastfood, color: Color(0xFFFFA000), size: 40),
                          ),

                        // Gradient Scrim Overlay for high readability
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.black.withValues(alpha: 0.85),
                                Colors.black.withValues(alpha: 0.45),
                                Colors.black.withValues(alpha: 0.1),
                              ],
                            ),
                          ),
                        ),

                        // Text & CTA overlay
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (promo.branch.isNotEmpty && promo.branch.toLowerCase() != 'all')
                                Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFA000),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${promo.branch.toUpperCase()} BRANCH',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 9,
                                      color: Colors.black,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              Text(
                                promo.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.domine(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 34,
                                child: ElevatedButton(
                                  onPressed: () {
                                    AppleTheme.hapticFeedback();
                                    widget.onBannerTap?.call();
                                    widget.onSeeAll?.call();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFFA000),
                                    foregroundColor: Colors.black,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    'Order Now',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                      letterSpacing: 0.3,
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
            },
          ),
        ),
        if (banners.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(banners.length, (i) {
              final active = i == _currentIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 6,
                width: active ? 18 : 6,
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFFFFA000)
                      : const Color(0xFFE0E0E0).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
