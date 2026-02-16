import 'package:flutter/material.dart';

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

  Color? _optionColor(NorwegianLetter option) {
    if (_selectedAudioKey != option.audioKey) return null;
    if (_selectedWasCorrect == true) return const Color(0xFF2ED573);
    if (_selectedWasCorrect == false) return const Color(0xFFFF4757);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final round = _session.currentRound;
    final titleStyle = Theme.of(context).textTheme.headlineSmall;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: Colors.white.withValues(alpha: 0.8),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.65)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hvilken bokstav hører du?', style: titleStyle),
                  const SizedBox(height: 8),
                  Text(
                    'Runde ${_session.currentRoundNumber} / ${widget.totalRounds}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Omstarter: ${_session.restartCount}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: _isHandlingAnswer ? null : _playCurrentLetter,
                    icon: const Icon(Icons.volume_up_rounded),
                    label: const Text('Spill lyd igjen'),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Perfekt-modus: feil svar starter runden pa nytt.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
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
                    backgroundColor: _optionColor(letter),
                    textStyle: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
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
