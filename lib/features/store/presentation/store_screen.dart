import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/store_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/back_button.dart';
import '../../../core/widgets/gradient_background.dart';
import '../../profile/domain/profile_state.dart';
import '../data/store_repository.dart';
import '../domain/store_state.dart';
import 'widgets/store_item_card.dart';

class StoreScreen extends StatefulWidget {
  final ProfileState profileState;
  final StoreRepository storeRepo;

  const StoreScreen({
    super.key,
    required this.profileState,
    required this.storeRepo,
  });

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  late final StoreState _storeState;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _storeState = StoreState(
      repo: widget.storeRepo,
      profileState: widget.profileState,
    );
  }

  @override
  void dispose() {
    _storeState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: ListenableBuilder(
        listenable: Listenable.merge([widget.profileState, _storeState]),
        builder: (context, _) {
          final points = widget.profileState.active?.points ?? 0;
          final category = storeCategories[_tabIndex];

          return Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    AppBackButton(onPressed: () => context.pop()),
                    const SizedBox(width: 12),
                    Text(
                      'Butikk',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.orange, AppColors.orangeDark],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '⭐ $points',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Tabs
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                child: Row(
                  children: List.generate(storeCategories.length, (i) {
                    final cat = storeCategories[i];
                    final selected = i == _tabIndex;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tabIndex = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: EdgeInsets.only(
                            right: i < storeCategories.length - 1 ? 8 : 0,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.white.withValues(alpha: 0.6)
                                : Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(14),
                            border: selected
                                ? Border.all(color: AppColors.orange, width: 2)
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${cat.icon} ${cat.name}',
                            style: TextStyle(
                              fontWeight: selected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 8),
              // Grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: category.columns,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: category.columns == 3 ? 0.85 : 0.9,
                  ),
                  itemCount: category.items.length,
                  itemBuilder: (_, i) {
                    final item = category.items[i];
                    return StoreItemCard(
                      item: item,
                      categoryName: category.name,
                      owned: _storeState.isOwned(item.id),
                      canAfford: _storeState.canAfford(item),
                      onTap: () => _storeState.buy(item),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
