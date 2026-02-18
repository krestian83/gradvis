enum ShowcaseTopicFamily { geometry, measurement, algorithmicThinking }

class MathHelperShowcaseQuestion {
  final ShowcaseTopicFamily topicFamily;
  final String operation;
  final List<num> operands;
  final int correctAnswer;
  final List<int> options;
  final String prompt;
  final String helpLabel;

  const MathHelperShowcaseQuestion({
    required this.topicFamily,
    required this.operation,
    this.operands = const [],
    required this.correctAnswer,
    required this.options,
    required this.prompt,
    required this.helpLabel,
  });
}

class MathHelperShowcaseEngine {
  const MathHelperShowcaseEngine();

  List<MathHelperShowcaseQuestion> buildQuestions() {
    return const [
      MathHelperShowcaseQuestion(
        topicFamily: ShowcaseTopicFamily.geometry,
        operation: 'triangleSides',
        correctAnswer: 3,
        options: [2, 3, 4, 5],
        prompt: 'Hvor mange sider har en trekant?',
        helpLabel: 'Tell sidene i en trekant',
      ),
      MathHelperShowcaseQuestion(
        topicFamily: ShowcaseTopicFamily.geometry,
        operation: 'cubeFaces',
        correctAnswer: 6,
        options: [4, 5, 6, 8],
        prompt: 'Hvor mange flater har en kube?',
        helpLabel: 'Kube: tell antall flater',
      ),
      MathHelperShowcaseQuestion(
        topicFamily: ShowcaseTopicFamily.measurement,
        operation: 'areaUnits',
        operands: [4, 3],
        correctAnswer: 12,
        options: [8, 10, 12, 14],
        prompt: 'Hva er arealet av 4 x 3 ruter?',
        helpLabel: 'Areal med enhetsruter: 4 x 3',
      ),
      MathHelperShowcaseQuestion(
        topicFamily: ShowcaseTopicFamily.measurement,
        operation: 'volumeUnits',
        operands: [3, 2, 2],
        correctAnswer: 12,
        options: [8, 10, 12, 14],
        prompt: 'Hva er volumet av 3 x 2 x 2 enhetskuber?',
        helpLabel: 'Volum med enhetskuber: 3 x 2 x 2',
      ),
      MathHelperShowcaseQuestion(
        topicFamily: ShowcaseTopicFamily.algorithmicThinking,
        operation: 'stepSequence',
        operands: [3, 1, 4, 2],
        correctAnswer: 1,
        options: [1, 2, 3, 4],
        prompt: 'Hvilket steg skal vaere nummer 1?',
        helpLabel: 'Sorter stegene: 3, 1, 4, 2',
      ),
      MathHelperShowcaseQuestion(
        topicFamily: ShowcaseTopicFamily.algorithmicThinking,
        operation: 'logicFlow',
        operands: [4, 3],
        correctAnswer: 2,
        options: [1, 2],
        prompt: 'Hvilket utfall blir markert som riktig?',
        helpLabel: 'Folg logikkflyten til riktig utfall',
      ),
    ];
  }
}
