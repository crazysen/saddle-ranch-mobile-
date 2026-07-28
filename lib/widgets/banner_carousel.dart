import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/promo_banner.dart';
import '../utils/menu_category.dart';

/// Simple sideways-draggable promo placeholders (4 cards) with images.
class BannerCarousel extends StatelessWidget {
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
    _PromoPlaceholder(
      title: 'Weekend Sizzling Specials',
      subtitle: 'Up to 15% off barkada platters',
      badge: 'HOT',
      category: MenuCategory.barkada,
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuASVSO6N3lzIbdlCDT85viSxOZiQKjWADlA5k7ymludjTdSCB7tqV0bZvXRba3-L4gemLyqy9PxmqnYMBnSsxb5yfI_XM-qajS5ZEnS1Am8OBu5uN8_smBFlDdy4xR0UNE8jDFJP8vNSRQcqqDSG4p-oDij5kCvWALcyBZVeuA1QdnqC9a6I5s9l2ba3Zjfe0xSPjMr0jLCAB1z-oJS5xBL9meeUeFsmiMgjQ96VoXotgHsy3Jl3d9NQIv1liJsKeu_sJec2rrkNziY',
    ),
    _PromoPlaceholder(
      title: 'Sisig Night Combo',
      subtitle: 'Free iced tea on ₱499+',
      badge: 'DEAL',
      category: MenuCategory.filipino,
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDt2cP7W6u7Hw-wJCWrbYiEh20Z4b79UCpbKxmmyVbQzw0xlTklDnEKOpEzeymppd9l-ODs0TOelRWM0iLgwF8K_OKfXIBpTO8lSH0yyxPtaMCTQrzQ4ykSkJPDryw9S9IBB1wNoeHFGtHcQDy4MEVr0_tUDss7SKe1fe58XBlXeql1nJ1D2J0zJ0ZFO4qRm213kO813mLEdYdUMjsTD0J2PtB7cz_0FmmDHccmacBmhMyp7a_fJ7teNVsG3sgWyfW24O1p08mnUE9t',
    ),
    _PromoPlaceholder(
      title: 'Bulalo Steak Feast',
      subtitle: 'Share for 2–3 people',
      badge: 'NEW',
      category: MenuCategory.filipino,
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCatSLXJ-mynm_AwjLXsdG9xKbMwziehShgiNtyXaX2NZEeZFhSXaTmHMgLuACAitSC3WZ0g_9lSTavvnqO4eKFlaC0pnnA9OngEMtRicl0vfSF2_t4WqzxTKxW-H-X0i_tppiClzEOZ-fAuu1ezCbRVOcdVdwZHokttY1ATDIO4BuA185dwrm0QDuPpYjQ7qD9ybH5bl0WPn1wHJ3S5pB6JuCOoocWTfZ95cB0Lfqx1KbjbUwqGJxkhwxmqypEJta64yq1PajT3oWC',
    ),
    _PromoPlaceholder(
      title: 'House Red Iced Tea',
      subtitle: 'Chilled pitcher for the barkada',
      badge: 'DRINKS',
      category: MenuCategory.drinks,
      imageUrl:
          'https://images.unsplash.com/photo-1556679343-c7306c197cfe?auto=format&fit=crop&w=800&q=80',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 12),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onSeeAll,
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'Promos for you',
                      style: TextStyle(
                        color: Color(0xFF1A1A1B),
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
              if (onSeeAll != null)
                IconButton(
                  onPressed: onSeeAll,
                  icon: const Icon(Icons.chevron_right, color: AppColors.muted),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _placeholders.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final promo = _placeholders[index];
              return SizedBox(
                width: 280,
                child: _PromoCard(
                  data: promo,
                  onTap: () {
                    onPromoTap?.call(promo.category);
                    if (onPromoTap == null) onSeeAll?.call();
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PromoPlaceholder {
  final String title;
  final String subtitle;
  final String badge;
  final String imageUrl;
  final MenuCategory category;

  const _PromoPlaceholder({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.imageUrl,
    required this.category,
  });
}

class _PromoCard extends StatelessWidget {
  final _PromoPlaceholder data;
  final VoidCallback? onTap;

  const _PromoCard({required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: data.imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(
                color: AppColors.surfaceAlt,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.amber,
                ),
              ),
              errorWidget: (_, _, _) => Container(
                color: AppColors.surfaceAlt,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.local_fire_department,
                  color: AppColors.amber,
                  size: 40,
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.75),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.amber,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  data.badge,
                  style: const TextStyle(
                    color: AppColors.onAmber,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
