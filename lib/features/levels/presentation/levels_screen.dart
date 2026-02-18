import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/curriculum_data.dart';
import '../../../core/constants/subject.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/back_button.dart';
import '../../../core/widgets/gradient_background.dart';
import '../../game/domain/game_interface.dart';
import '../../game/domain/game_registry.dart';
import '../../profile/domain/profile_state.dart';
import '../data/level_progress_model.dart';
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

  List<int> _visibleLevelIndexes(int trinn, List<LevelNode> nodes) {
    return List.generate(nodes.length, (i) => i).where((levelIndex) {
      final slot = GameSlot(
        subject: widget.subject,
        trinn: trinn,
        level: levelIndex,
      );
      return GameRegistry.instance.hasGame(slot);
    }).toList();
  }

  int _currentVisibleLevelIndex(
    List<LevelProgress> levels,
    List<int> visibleIndexes,
  ) {
    if (visibleIndexes.isEmpty) return -1;
    for (final levelIndex in visibleIndexes) {
      if (!levels[levelIndex].done) return levelIndex;
    }
    return visibleIndexes.last;
  }

  double _visibleMastery(List<LevelProgress> levels, List<int> visibleIndexes) {
    if (visibleIndexes.isEmpty) return 0;
    final total = visibleIndexes.length * 3;
    final earned = visibleIndexes.fold<int>(
      0,
      (sum, levelIndex) => sum + levels[levelIndex].stars,
    );
    return earned / total;
  }

  int _totalVisibleStars(List<LevelProgress> levels, List<int> visibleIndexes) {
    return visibleIndexes.fold<int>(
      0,
      (sum, levelIndex) => sum + levels[levelIndex].stars,
    );
  }

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
    final visibleLevelIndexes = _visibleLevelIndexes(trinn, nodes);

    return GradientBackground(
      child: ListenableBuilder(
        listenable: _levelsState,
        builder: (context, _) {
          final levels = _levelsState.levels;
          final mastery = _visibleMastery(levels, visibleLevelIndexes);
          final currentLevelIndex = _currentVisibleLevelIndex(
            levels,
            visibleLevelIndexes,
          );
          final totalStars = _totalVisibleStars(levels, visibleLevelIndexes);
          final maxStars = visibleLevelIndexes.length * 3;

          return Column(
            children: [
              _LevelsHeader(
                subject: widget.subject,
                trinn: trinn,
                totalStars: totalStars,
                maxStars: maxStars,
                onBack: () => context.pop(),
              ),
              _MasteryBar(subject: widget.subject, mastery: mastery),
              const SizedBox(height: 14),
              Expanded(
                child: _LevelGrid(
                  subject: widget.subject,
                  nodes: nodes,
                  levels: levels,
                  levelIndexes: visibleLevelIndexes,
                  currentLevelIndex: currentLevelIndex,
                  onOpenLevel: _openLevel,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LevelsHeader extends StatelessWidget {
  final Subject subject;
  final int trinn;
  final int totalStars;
  final int maxStars;
  final VoidCallback onBack;

  const _LevelsHeader({
    required this.subject,
    required this.trinn,
    required this.totalStars,
    required this.maxStars,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final headingStyle = Theme.of(context).textTheme.headlineSmall;
    final subStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
      color: subject.color,
      fontWeight: FontWeight.w800,
    );
    final starsStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
      color: subject.color,
      fontWeight: FontWeight.w900,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Row(
        children: [
          AppBackButton(onPressed: onBack),
          const SizedBox(width: 10),
          _SubjectBadge(subject: subject),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subject.displayName, style: headingStyle),
                Text('Trinn $trinn', style: subStyle),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: subject.lightBg.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star_rounded,
                  size: 16,
                  color: AppColors.starFilled,
                ),
                const SizedBox(width: 4),
                Text('$totalStars/$maxStars', style: starsStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectBadge extends StatelessWidget {
  final Subject subject;

  const _SubjectBadge({required this.subject});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: subject.lightBg,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(subject.icon, style: const TextStyle(fontSize: 24)),
    );
  }
}

class _MasteryBar extends StatelessWidget {
  final Subject subject;
  final double mastery;

  const _MasteryBar({required this.subject, required this.mastery});

  @override
  Widget build(BuildContext context) {
    final value = mastery.clamp(0.0, 1.0).toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 8,
          child: Stack(
            children: [
              ColoredBox(color: Colors.white.withValues(alpha: 0.45)),
              FractionallySizedBox(
                widthFactor: value,
                alignment: Alignment.centerLeft,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [subject.color, subject.colorB],
                    ),
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

class _LevelGrid extends StatelessWidget {
  final Subject subject;
  final List<LevelNode> nodes;
  final List<LevelProgress> levels;
  final List<int> levelIndexes;
  final int currentLevelIndex;
  final ValueChanged<int> onOpenLevel;

  const _LevelGrid({
    required this.subject,
    required this.nodes,
    required this.levels,
    required this.levelIndexes,
    required this.currentLevelIndex,
    required this.onOpenLevel,
  });

  @override
  Widget build(BuildContext context) {
    if (levelIndexes.isEmpty) {
      final style = Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(color: AppColors.subtitle);
      return Center(
        child: Text('Ingen nivåer tilgjengelig ennå.', style: style),
      );
    }

    final cards = levelIndexes.map((levelIndex) {
      final node = nodes[levelIndex];
      final progress = levels[levelIndex];
      final isCurrent = levelIndex == currentLevelIndex;

      return LevelNodeWidget(
        node: node,
        progress: progress,
        subject: subject,
        isCurrent: isCurrent,
        onTap: () => onOpenLevel(levelIndex),
      );
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 20),
      child: Column(children: _buildRows(cards)),
    );
  }

  List<Widget> _buildRows(List<Widget> cards) {
    final rows = <Widget>[];

    for (var i = 0; i < cards.length; i += 2) {
      final isLastOdd = i == cards.length - 1;

      if (rows.isNotEmpty) {
        rows.add(const SizedBox(height: 14));
      }

      if (isLastOdd) {
        rows.add(cards[i]);
        continue;
      }

      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cards[i]),
            const SizedBox(width: 14),
            Expanded(child: cards[i + 1]),
          ],
        ),
      );
    }

    return rows;
  }
}
