import 'subject.dart';

/// A single level node in the curriculum map.
class LevelNode {
  final String icon;
  final String label;

  const LevelNode({required this.icon, required this.label});
}

/// Level nodes per subject per trinn. No game data — just structure.
const Map<Subject, Map<int, List<LevelNode>>> curriculumData = {
  Subject.reading: {
    1: [
      LevelNode(icon: '🅰️', label: 'Aa-Bb'),
      LevelNode(icon: '🔤', label: 'Cc-Dd'),
      LevelNode(icon: '✏️', label: 'Ord'),
      LevelNode(icon: '📕', label: 'Setning'),
      LevelNode(icon: '📚', label: 'Les'),
    ],
    2: [
      LevelNode(icon: '🔗', label: 'Sml.ord'),
      LevelNode(icon: '📖', label: 'Lese'),
      LevelNode(icon: '❓', label: 'Spørs.'),
      LevelNode(icon: '📝', label: 'Fortell'),
      LevelNode(icon: '🎵', label: 'Dikt'),
    ],
    3: [
      LevelNode(icon: '📐', label: 'Gramm.'),
      LevelNode(icon: '🔀', label: 'Synonym'),
      LevelNode(icon: '📄', label: 'Sakprosa'),
      LevelNode(icon: '📖', label: 'Sjanger'),
      LevelNode(icon: '✍️', label: 'Skriving'),
    ],
    4: [
      LevelNode(icon: '📚', label: 'Sjanger'),
      LevelNode(icon: '🔍', label: 'Analyse'),
      LevelNode(icon: '✅', label: 'Rettskr.'),
      LevelNode(icon: '📝', label: 'Avsnitt'),
      LevelNode(icon: '⭐', label: 'Anmeld.'),
    ],
  },
  Subject.math: {
    1: [
      LevelNode(icon: '🍎', label: '1+1'),
      LevelNode(icon: '🍊', label: '2+3'),
      LevelNode(icon: '🍋', label: '5+?'),
      LevelNode(icon: '🍇', label: '10−?'),
      LevelNode(icon: '🔢', label: 'Telle'),
    ],
    2: [
      LevelNode(icon: '➕', label: '+/− 20'),
      LevelNode(icon: '✖️', label: '×2'),
      LevelNode(icon: '🔷', label: 'Former'),
      LevelNode(icon: '🕐', label: 'Klokka'),
      LevelNode(icon: '📏', label: 'Måling'),
    ],
    3: [
      LevelNode(icon: '✖️', label: '×3–5'),
      LevelNode(icon: '➗', label: 'Dele'),
      LevelNode(icon: '🥧', label: 'Brøk'),
      LevelNode(icon: '📐', label: 'Geometri'),
      LevelNode(icon: '🧩', label: 'Problem'),
    ],
    4: [
      LevelNode(icon: '✖️', label: 'Tabellrush'),
      LevelNode(icon: '🔢', label: 'Plussbro'),
      LevelNode(icon: '🔸', label: 'Minusjakt'),
      LevelNode(icon: '📐', label: 'Areal'),
      LevelNode(icon: '📊', label: 'Statistikk'),
    ],
  },
  Subject.english: {
    1: [
      LevelNode(icon: '👋', label: 'Hello'),
      LevelNode(icon: '🎨', label: 'Colors'),
      LevelNode(icon: '🔢', label: 'Numbers'),
      LevelNode(icon: '🐾', label: 'Animals'),
      LevelNode(icon: '🫀', label: 'Body'),
    ],
    2: [
      LevelNode(icon: '👨\u200d👩\u200d👧', label: 'Family'),
      LevelNode(icon: '🍕', label: 'Food'),
      LevelNode(icon: '📅', label: 'Days'),
      LevelNode(icon: '🌤️', label: 'Weather'),
      LevelNode(icon: '🏫', label: 'School'),
    ],
    3: [
      LevelNode(icon: '🏃', label: 'Verbs'),
      LevelNode(icon: '💬', label: 'Sentences'),
      LevelNode(icon: '📖', label: 'Reading'),
      LevelNode(icon: '✍️', label: 'Writing'),
      LevelNode(icon: '🗣️', label: 'Talking'),
    ],
    4: [
      LevelNode(icon: '📐', label: 'Grammar'),
      LevelNode(icon: '📚', label: 'Stories'),
      LevelNode(icon: '⏪', label: 'Past t.'),
      LevelNode(icon: '📝', label: 'Vocab'),
      LevelNode(icon: '🧠', label: 'Compreh.'),
    ],
  },
  Subject.science: {
    1: [
      LevelNode(icon: '🌸', label: 'Planter'),
      LevelNode(icon: '🐛', label: 'Dyr'),
      LevelNode(icon: '🌤️', label: 'Vær'),
      LevelNode(icon: '💧', label: 'Vann'),
      LevelNode(icon: '🌍', label: 'Jorda'),
    ],
    2: [
      LevelNode(icon: '🦋', label: 'Livssykl.'),
      LevelNode(icon: '🧲', label: 'Magnet'),
      LevelNode(icon: '☀️', label: 'Sol/måne'),
      LevelNode(icon: '🪨', label: 'Stein'),
      LevelNode(icon: '♻️', label: 'Resirk.'),
    ],
    3: [
      LevelNode(icon: '🔬', label: 'Celler'),
      LevelNode(icon: '⚡', label: 'Energi'),
      LevelNode(icon: '🌋', label: 'Vulkan'),
      LevelNode(icon: '🫁', label: 'Kroppen'),
      LevelNode(icon: '🌊', label: 'Økosys.'),
    ],
    4: [
      LevelNode(icon: '🧪', label: 'Kjemi'),
      LevelNode(icon: '🔭', label: 'Rommet'),
      LevelNode(icon: '⚡', label: 'Strøm'),
      LevelNode(icon: '🧬', label: 'Arv'),
      LevelNode(icon: '🌡️', label: 'Klima'),
    ],
  },
};
