/// Metadata for each grade level (Trinn 1–4).
const trinnInfo = [
  TrinnData(num: 1, age: '5–6 år', desc: 'Bokstaver, tall og farger'),
  TrinnData(num: 2, age: '6–7 år', desc: 'Lesing, regning og enkle ord'),
  TrinnData(num: 3, age: '7–8 år', desc: 'Grammatikk, ganging og setninger'),
  TrinnData(num: 4, age: '8–9 år', desc: 'Analyse, store tall og tekst'),
];

class TrinnData {
  final int num;
  final String age;
  final String desc;

  const TrinnData({required this.num, required this.age, required this.desc});
}
