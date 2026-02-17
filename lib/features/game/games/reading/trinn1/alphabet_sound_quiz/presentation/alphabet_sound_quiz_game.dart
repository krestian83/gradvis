import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/widgets/glass_card.dart';
import '../../../../../../../core/widgets/progress_bar.dart';
import '../../../../../domain/game_interface.dart';
import '../application/alphabet_audio_player.dart';
import '../application/alphabet_session_controller.dart';
import '../domain/alphabet_quiz_engine.dart';
import '../domain/norwegian_letters.dart';

class AlphabetSoundQuizGame extends StatefulWidget implements GameWidget {
  @override
  final ValueChanged<GameResult> onComplete;

  final int totalRounds;
  final Duration feedbackDelay;
  final AlphabetAudioPlayer? audioPlayer;
  final AlphabetRoundProvider? roundProvider;

  const AlphabetSoundQuizGame({
    super.key,
    required this.onComplete,
    this.totalRounds = 12,
    this.feedbackDelay = const Duration(milliseconds: 450),
    this.audioPlayer,
    this.roundProvider,
  });

  @override
  State<AlphabetSoundQuizGame> createState() => _AlphabetSoundQuizGameState();
}

class _AlphabetSoundQuizGameState extends State<AlphabetSoundQuizGame> {
  late final AlphabetSessionController _session;
  late final AlphabetAudioPlayer _audioPlayer;
  late final bool _ownsAudioPlayer;

  bool _isHandlingAnswer = false;
  bool _hasCompleted = false;
  String? _selectedAudioKey;
  bool? _selectedWasCorrect;

  @override
  void initState() {
    super.initState();
    _session = AlphabetSessionController(
      roundProvider:
          widget.roundProvider ??
          AlphabetQuizEngine(letters: norwegianLetters, optionCount: 4),
      totalRounds: widget.totalRounds,
    );
    _audioPlayer = widget.audioPlayer ?? AssetAlphabetAudioPlayer();
    _ownsAudioPlayer = widget.audioPlayer == null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playCurrentLetter();
    });
  }

  @override
  void dispose() {
    if (_ownsAudioPlayer) {
      _audioPlayer.dispose();
    }
    super.dispose();
  }

  Future<void> _playCurrentLetter() async {
    await _audioPlayer.playLetter(_session.currentRound.target.audioKey);
  }

  Future<void> _onOptionPressed(NorwegianLetter option) async {
    if (_isHandlingAnswer || _hasCompleted) return;

    final wasCorrect = _session.isCorrectAnswer(option);
    setState(() {
      _isHandlingAnswer = true;
      _selectedAudioKey = option.audioKey;
      _selectedWasCorrect = wasCorrect;
    });

    if (wasCorrect) {
      await _audioPlayer.playSuccess();
      await Future<void>.delayed(widget.feedbackDelay);

      final completed = _session.advanceAfterCorrectAnswer();
      if (!mounted) return;

      if (completed) {
        _hasCompleted = true;
        final reward = _session.reward;
        widget.onComplete(
          GameResult(stars: reward.stars, pointsEarned: reward.points),
        );
        return;
      }
    } else {
      await _audioPlayer.playWrong();
      await Future<void>.delayed(widget.feedbackDelay);
      _session.restartFromWrongAnswer();
      if (!mounted) return;
    }

    await _playCurrentLetter();
    if (!mounted) return;

    setState(() {
      _isHandlingAnswer = false;
      _selectedAudioKey = null;
      _selectedWasCorrect = null;
    });
  }

  bool _isSelectedOption(NorwegianLetter option) =>
      _selectedAudioKey == option.audioKey;

  Color _optionBackgroundColor(NorwegianLetter option) {
    if (!_isSelectedOption(option)) return AppColors.cardBgStrong;
    if (_selectedWasCorrect == true) return AppColors.green;
    if (_selectedWasCorrect == false) return AppColors.heartFilled;
    return AppColors.cardBgStrong;
  }

  Color _optionBorderColor(NorwegianLetter option) {
    if (!_isSelectedOption(option)) return AppColors.glassBorder;
    if (_selectedWasCorrect == true) return AppColors.greenLight;
    if (_selectedWasCorrect == false) return AppColors.heartFilled;
    return AppColors.glassBorder;
  }

  Color _optionForegroundColor(NorwegianLetter option) {
    if (_isSelectedOption(option) && _selectedWasCorrect != null) {
      return Colors.white;
    }
    return AppColors.heading;
  }

  @override
  Widget build(BuildContext context) {
    final round = _session.currentRound;
    final theme = Theme.of(context);
    final roundProgress = (_session.currentRoundNumber / widget.totalRounds)
        .clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassCard(
            padding: const EdgeInsets.all(16),
            borderRadius: 20,
            opacity: 0.6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hvilken bokstav hører du?',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Runde ${_session.currentRoundNumber} / ${widget.totalRounds}',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                ProgressBar(fraction: roundProgress),
                const SizedBox(height: 12),
                _QuizActionButton(
                  onTap: _isHandlingAnswer ? null : _playCurrentLetter,
                  icon: Icons.volume_up_rounded,
                  label: 'Spill lyd igjen',
                ),
                const SizedBox(height: 8),
                Text(
                  'Perfekt-modus: feil svar starter runden på nytt.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 2),
                Text(
                  'Omstarter: ${_session.restartCount}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.9,
              children: round.options.map((letter) {
                return FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _optionBackgroundColor(letter),
                    disabledBackgroundColor: _optionBackgroundColor(letter),
                    foregroundColor: _optionForegroundColor(letter),
                    disabledForegroundColor: _optionForegroundColor(letter),
                    elevation: 0,
                    side: BorderSide(
                      color: _optionBorderColor(letter),
                      width: 1.5,
                    ),
                    textStyle: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 36,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: _isHandlingAnswer
                      ? null
                      : () => _onOptionPressed(letter),
                  child: Text(letter.upper),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizActionButton extends StatelessWidget {
  final VoidCallback? onTap;
  final IconData icon;
  final String label;

  const _QuizActionButton({
    required this.onTap,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1.0 : 0.55,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.orange, AppColors.orangeDark],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.orange.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
