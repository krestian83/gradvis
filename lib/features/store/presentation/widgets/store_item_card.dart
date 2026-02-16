import 'package:flutter/material.dart';

import '../../../../core/constants/store_data.dart';
import '../../../../core/theme/app_colors.dart';

/// Individual store item with preview, name, and price.
class StoreItemCard extends StatelessWidget {
  final StoreItem item;
  final String categoryName;
  final bool owned;
  final bool canAfford;
  final VoidCallback? onTap;

  const StoreItemCard({
    super.key,
    required this.item,
    required this.categoryName,
    required this.owned,
    required this.canAfford,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final affordable = canAfford || owned;

    return GestureDetector(
      onTap: owned ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: affordable ? 1.0 : 0.55,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Preview(item: item, categoryName: categoryName),
              const SizedBox(height: 8),
              Text(
                item.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              if (owned)
                const Text('✅', style: TextStyle(fontSize: 14))
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: canAfford
                        ? AppColors.orange.withValues(alpha: 0.12)
                        : const Color(0x0F2D3047),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '⭐ ${item.price}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: canAfford ? AppColors.orange : AppColors.muted,
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

class _Preview extends StatelessWidget {
  final StoreItem item;
  final String categoryName;

  const _Preview({required this.item, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    // Emoji items: gold gradient circle with emoji
    if (!item.hasPreview) {
      return Container(
        width: 50,
        height: 50,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFE066), Color(0xFFFFB347)],
          ),
        ),
        alignment: Alignment.center,
        child: Text(item.icon, style: const TextStyle(fontSize: 26)),
      );
    }

    final isRammer = categoryName == 'Rammer';
    final gradient = LinearGradient(
      begin: item.vertical ? Alignment.topCenter : Alignment.topLeft,
      end: item.vertical ? Alignment.bottomCenter : Alignment.bottomRight,
      colors: item.previewColors,
    );

    if (isRammer) {
      // Circle preview with white border + smiley inside
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: gradient,
          border: Border.all(color: Colors.white, width: 3),
        ),
        alignment: Alignment.center,
        child: const Text('😊', style: TextStyle(fontSize: 22)),
      );
    }

    // Tema: rounded square
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: gradient,
      ),
    );
  }
}
