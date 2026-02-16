import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gradvis_v2/features/game/domain/game_interface.dart';
import 'package:gradvis_v2/features/game/games/reading/trinn1/alphabet_sound_quiz/application/alphabet_audio_player.dart';
import 'package:gradvis_v2/features/game/games/reading/trinn1/alphabet_sound_quiz/domain/alphabet_quiz_engine.dart';
import 'package:gradvis_v2/features/game/games/reading/trinn1/alphabet_sound_quiz/domain/norwegian_letters.dart';
import 'package:gradvis_v2/features/game/games/reading/trinn1/alphabet_sound_quiz/presentation/alphabet_sound_quiz_game.dart';

class _FakeAlphabetAudioPlayer implements AlphabetAudioPlayer {
  int letterPlays = 0;
  int successPlays = 0;
  int wrongPlays = 0;

  @override
  Future<void> playLetter(String audioKey) async {
    letterPlays += 1;
  }

  @override
  Future<void> playSuccess() async {
    successPlays += 1;
  }

  @override
  Future<void> playWrong() async {
    wrongPlays += 1;
  }

  @override
  Future<void> dispose() async {}
}

class _FixedRoundProvider implements AlphabetRoundProvider {
  final AlphabetRound _round;

  _FixedRoundProvider(this._round);

  @override
  AlphabetRound nextRound() => _round;
}

Future<void> _pumpGame(
  WidgetTester tester, {
  required AlphabetRoundProvider roundProvider,
  required AlphabetAudioPlayer audioPlayer,
  required ValueChanged<GameResult> onComplete,
  int totalRounds = 12,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AlphabetSoundQuizGame(
          onComplete: onComplete,
          roundProvider: roundProvider,
          audioPlayer: audioPlayer,
          feedbackDelay: Duration.zero,
          totalRounds: totalRounds,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  final a = norwegianLetters.firstWhere((letter) => letter.upper == 'A');
  final b = norwegianLetters.firstWhere((letter) => letter.upper == 'B');
  final c = norwegianLetters.firstWhere((letter) => letter.upper == 'C');
  final d = norwegianLetters.firstWhere((letter) => letter.upper == 'D');
  final round = AlphabetRound(target: a, options: [a, b, c, d]);

  testWidgets('shows uppercase options and restarts on wrong answer', (
    tester,
  ) async {
    final audio = _FakeAlphabetAudioPlayer();
    GameResult? result;

    await _pumpGame(
      tester,
      roundProvider: _FixedRoundProvider(round),
      audioPlayer: audio,
      onComplete: (value) => result = value,
    );

    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('D'), findsOneWidget);
    expect(find.text('Runde 1 / 12'), findsOneWidget);
    expect(find.text('Omstarter: 0'), findsOneWidget);

    await tester.tap(find.text('B'));
    await tester.pumpAndSettle();

    expect(find.text('Runde 1 / 12'), findsOneWidget);
    expect(find.text('Omstarter: 1'), findsOneWidget);
    expect(audio.wrongPlays, 1);
    expect(result, isNull);
  });

  testWidgets('emits completion result after 12 correct answers', (
    tester,
  ) async {
    final audio = _FakeAlphabetAudioPlayer();
    GameResult? result;
    var completeCalls = 0;

    await _pumpGame(
      tester,
      roundProvider: _FixedRoundProvider(round),
      audioPlayer: audio,
      onComplete: (value) {
        completeCalls += 1;
        result = value;
      },
    );

    for (var i = 0; i < 12; i++) {
      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();
    }

    expect(completeCalls, 1);
    expect(result?.stars, 3);
    expect(result?.pointsEarned, 14);
    expect(audio.successPlays, 12);
  });
}
