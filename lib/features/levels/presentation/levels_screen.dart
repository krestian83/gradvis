import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/curriculum_data.dart';
import '../../../core/constants/subject.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/back_button.dart';
import '../../../core/widgets/gradient_background.dart';
import '../../game/domain/game_interface.dart';
import '../../profile/domain/profile_state.dart';
import '../domain/level_repository.dart';
import '../domain/levels_state.dart';
import 'widgets/level_node_widget.dart';

class LevelsScreen extends StatefulWidget {
  final ProfileState profileState;
  final LevelRepository levelRepo;
  final Subject subject;

  const LevelsScreen({
    super.key,
    required this.profileState,
    required this.levelRepo,
    required this.subject,
  });

  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen> {
  late final LevelsState _levelsState;

  @override
  void initState() {
    super.initState();
    final profile = widget.profileState.active!;
    _levelsState = LevelsState(
      repo: widget.levelRepo,
      profileId: profile.id,
      subject: widget.subject,
      trinn: profile.trinn,
    );
  }

  @override
  void dispose() {
    _levelsState.dispose();
    super.dispose();
  }

  static const _offsets = [0.0, 44.0, -34.0, 48.0, -14.0];

  Future<void> _openLevel(int levelIndex) async {
    final result = await context.push<GameResult>(
      RouteNames.gamePath(widget.subject.name, levelIndex),
    );
    if (!mounted || result == null) return;

    await _levelsState.complete(levelIndex, result.stars);
    await widget.profileState.addPoints(result.pointsEarned);
  }

  @override
  Widget build(BuildContext context) {
    final trinn = widget.profileState.active!.trinn;
    final nodes = curriculumData[widget.subject]![trinn]!;

    return GradientBackground(
      child: ListenableBuilder(
        listenable: _levelsState,
        builder: (context, _) {
          final mastery = _levelsState.mastery;
          final currentIdx = _levelsState.currentIndex;

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
                      widget.subject.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.subject.displayName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            'Trinn $trinn – ${(mastery * 100).round()}%',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Level path
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: List.generate(nodes.length, (i) {
                      final reversedIndex = nodes.length - 1 - i;
                      final node = nodes[reversedIndex];
                      final progress = _levelsState.levels[reversedIndex];
                      final isCurrent = reversedIndex == currentIdx;
                      final isLocked = reversedIndex > currentIdx;
                      final offset = _offsets[reversedIndex % _offsets.length];

                      return Column(
                        children: [
                          // Connector line (above node, except first)
                          if (i > 0)
                            Container(
                              width: 4,
                              height: 18,
                              decoration: BoxDecoration(
                                color: progress.done || isCurrent
                                    ? widget.subject.color
                                    : AppColors.connectorUndone,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          Transform.translate(
                            offset: Offset(offset, 0),
                            child: LevelNodeWidget(
                              node: node,
                              progress: progress,
                              subject: widget.subject,
                              isCurrent: isCurrent,
                              isLocked: isLocked,
                              onTap: () {
                                _openLevel(reversedIndex);
                              },
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
