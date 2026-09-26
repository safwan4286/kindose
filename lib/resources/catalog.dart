import 'package:flutter/material.dart';

import 'images.dart';

/// Static reference data used across the app. Strengths are the doses on
/// each product's label. Kindose only records what the user's doctor
/// prescribed. It never suggests a dose.

/// Sections on the medication question.
enum MedGroup { tirzepatide, semaglutide, other, notListed }

class Medicine {
  const Medicine({
    required this.id,
    required this.name,
    required this.sub,
    required this.group,
    required this.strengths,
    this.mark,
    this.pickTitle,
    this.form = 'pen',
    this.everyDays = 7,
    this.color = const Color(0xFFD6F84C),
    this.dark = const Color(0xFF15142B),
  });

  final String id;

  /// Name shown around the app ("Mounjaro").
  final String name;

  /// Second line on the medication question ("Weekly pen").
  final String sub;
  final MedGroup group;

  /// Label strengths in mg, lowest first. Empty when unknown.
  final List<double> strengths;

  /// "®" after brand names, null for generic and compounded.
  final String? mark;

  /// Title on the medication question when it differs from [name].
  final String? pickTitle;

  /// Default form: 'pen', 'vial' or 'tablet'.
  final String form;

  /// Default days between doses (7 weekly, 1 daily).
  final int everyDays;

  /// Pen illustration colours.
  final Color color;
  final Color dark;

  bool get isTablet => form == 'tablet';

  /// Active ingredient in lower case, or null when unknown.
  String? get molecule => switch (group) {
        MedGroup.tirzepatide => 'tirzepatide',
        MedGroup.semaglutide => 'semaglutide',
        MedGroup.other => sub.split(' · ').first.toLowerCase(),
        MedGroup.notListed => null,
      };
  String get title => pickTitle ?? name;
}

class Food {
  const Food(this.id, this.name, this.grams, this.icon);

  final String id;
  final String name;
  final int grams;
  final String icon;
}

class InjectionSite {
  const InjectionSite(this.id, this.name, this.x, this.y);

  final String id;
  final String name;

  /// Position on the 160 × 250 body map.
  final double x;
  final double y;
}

class Mood {
  const Mood(this.label, this.icon);

  final String label;
  final String icon;
}

class FocusItem {
  const FocusItem(this.id, this.title, this.sub, this.icon);

  final String id;
  final String title;
  final String sub;
  final String icon;
}

class Catalog {
  Catalog._();

  static const List<double> _tirzepatide = [2.5, 5, 7.5, 10, 12.5, 15];
  static const List<double> _semaWeekly = [0.25, 0.5, 1, 1.7, 2, 2.4];

  /// Order here is the order on the medication question.
  static const List<Medicine> medicines = [
    Medicine(
      id: 'mounjaro',
      name: 'Mounjaro',
      mark: '®',
      sub: 'Weekly pen',
      group: MedGroup.tirzepatide,
      strengths: _tirzepatide,
      color: Color(0xFF8B7CFF),
      dark: Color(0xFF4336D9),
    ),
    Medicine(
      id: 'zepbound',
      name: 'Zepbound',
      mark: '®',
      sub: 'Weekly pen or vial',
      group: MedGroup.tirzepatide,
      strengths: _tirzepatide,
      color: Color(0xFFFF9A62),
      dark: Color(0xFFD4581B),
    ),
    Medicine(
      id: 'ctirz',
      name: 'Tirzepatide',
      pickTitle: 'Compounded tirzepatide',
      sub: 'Weekly · vial and syringe',
      group: MedGroup.tirzepatide,
      strengths: _tirzepatide,
      form: 'vial',
    ),
    Medicine(
      id: 'ozempic',
      name: 'Ozempic',
      mark: '®',
      sub: 'Weekly pen',
      group: MedGroup.semaglutide,
      strengths: [0.25, 0.5, 1, 2],
      color: Color(0xFF7BD8B0),
      dark: Color(0xFF2E9C6D),
    ),
    Medicine(
      id: 'wegovy',
      name: 'Wegovy',
      mark: '®',
      sub: 'Weekly pen',
      group: MedGroup.semaglutide,
      strengths: [0.25, 0.5, 1, 1.7, 2.4, 7.2],
      color: Color(0xFF5CCBF0),
      dark: Color(0xFF1788B0),
    ),
    Medicine(
      id: 'wegovypill',
      name: 'Wegovy pill',
      mark: '®',
      sub: 'Daily tablet',
      group: MedGroup.semaglutide,
      strengths: [1.5, 4, 9, 25],
      form: 'tablet',
      everyDays: 1,
    ),
    Medicine(
      id: 'rybelsus',
      name: 'Rybelsus',
      mark: '®',
      sub: 'Daily tablet',
      group: MedGroup.semaglutide,
      strengths: [1.5, 3, 4, 7, 9, 14],
      form: 'tablet',
      everyDays: 1,
      color: Color(0xFFFFFFFF),
      dark: Color(0xFFB9B7D6),
    ),
    // Kept as 'generic' so profiles saved before this list still load.
    Medicine(
      id: 'generic',
      name: 'Semaglutide',
      pickTitle: 'Generic semaglutide',
      sub: 'Other brands of semaglutide',
      group: MedGroup.semaglutide,
      strengths: _semaWeekly,
      color: Color(0xFFC9E86A),
      dark: Color(0xFF7FA11C),
    ),
    Medicine(
      id: 'csema',
      name: 'Semaglutide',
      pickTitle: 'Compounded semaglutide',
      sub: 'Weekly · vial and syringe',
      group: MedGroup.semaglutide,
      strengths: _semaWeekly,
      form: 'vial',
    ),
    Medicine(
      id: 'foundayo',
      name: 'Foundayo',
      mark: '®',
      sub: 'Orforglipron · daily tablet',
      group: MedGroup.other,
      strengths: [0.8, 2.5, 5.5, 9, 14.5, 17.2],
      form: 'tablet',
      everyDays: 1,
    ),
    Medicine(
      id: 'saxenda',
      name: 'Saxenda',
      mark: '®',
      sub: 'Liraglutide · daily pen',
      group: MedGroup.other,
      strengths: [0.6, 1.2, 1.8, 2.4, 3],
      everyDays: 1,
    ),
    Medicine(
      id: 'trulicity',
      name: 'Trulicity',
      mark: '®',
      sub: 'Dulaglutide · weekly pen',
      group: MedGroup.other,
      strengths: [0.75, 1.5, 3, 4.5],
    ),
    // The user types the name; see UserProfile.customMedicine.
    Medicine(
      id: other,
      name: 'GLP-1',
      pickTitle: 'Something else',
      sub: 'Type its name',
      group: MedGroup.notListed,
      strengths: [],
    ),
    Medicine(
      id: undecided,
      name: 'GLP-1',
      pickTitle: "I haven't decided yet",
      sub: 'You can add it later',
      group: MedGroup.notListed,
      strengths: [],
    ),
  ];

  static const String other = 'other';
  static const String undecided = 'undecided';

  static Medicine medicine(String id) =>
      medicines.firstWhere((m) => m.id == id, orElse: () => medicines.first);

  /// Name to show in the app. For "Something else" this is what the user
  /// typed, falling back to "GLP-1".
  static String medicineName(String id, [String? custom]) {
    final typed = custom?.trim() ?? '';
    if (id == other && typed.isNotEmpty) return typed;
    return medicine(id).name;
  }

  /// Formats 2.5 → "2.5", 5.0 → "5", 0.25 → "0.25".
  static String mg(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    final s = v.toStringAsFixed(2);
    return s.endsWith('0') ? s.substring(0, s.length - 1) : s;
  }

  /// "2.5 mg", or "dose not set" when the user chose "I don't know yet"
  /// (stored as 0).
  static String mgLabel(double v) => v > 0 ? '${mg(v)} mg' : 'dose not set';

  /// Forms to offer on the dose question when the medicine comes in more
  /// than one. Empty means the medicine's own form is used.
  static List<String> formsFor(String medicineId) => switch (medicineId) {
        'zepbound' => const ['pen', 'vial'],
        Catalog.other || Catalog.undecided => const ['pen', 'vial', 'tablet'],
        _ => const [],
      };

  static const List<String> forms = ['pen', 'auto', 'vial', 'tablet'];

  static String formLabel(String id) {
    switch (id) {
      case 'auto':
        return 'Auto-pen';
      case 'vial':
        return 'Vial';
      case 'tablet':
        return 'Tablet';
      default:
        return 'Pen';
    }
  }

  static const List<InjectionSite> sites = [
    InjectionSite('lbelly', 'Left belly', 80, 110),
    InjectionSite('rbelly', 'Right belly', 50, 110),
    InjectionSite('lthigh', 'Left thigh', 81, 182),
    InjectionSite('rthigh', 'Right thigh', 49, 182),
    InjectionSite('larm', 'Left arm', 114, 86),
    InjectionSite('rarm', 'Right arm', 16, 86),
  ];

  static String siteName(String id) =>
      sites.firstWhere((s) => s.id == id, orElse: () => sites.first).name;

  /// The site after [lastId] in the rotation.
  static String nextSite(String? lastId) {
    if (lastId == null) return sites.first.id;
    final i = sites.indexWhere((s) => s.id == lastId);
    return sites[(i + 1) % sites.length].id;
  }

  static const List<Mood> moods = [
    Mood('Great', Img3d.great),
    Mood('Good', Img3d.smile),
    Mood('Okay', Img3d.neutral),
    Mood('Meh', Img3d.frown),
    Mood('Rough', Img3d.nauseated),
  ];

  static const List<Food> everydayFoods = [
    Food('egg', '2 eggs', 12, Img3d.egg),
    Food('chicken', 'Chicken, 100 g', 31, Img3d.chicken),
    Food('dal', 'Dal, 1 bowl', 8, Img3d.dal),
    Food('whey', 'Whey shake', 24, Img3d.whey),
    Food('curd', 'Greek yogurt', 17, Img3d.milk),
    Food('paneer', 'Paneer, 100 g', 19, Img3d.paneer),
  ];

  static const List<Food> vegFoods = [
    Food('paneer', 'Paneer, 100 g', 19, Img3d.paneer),
    Food('soya', 'Soya curry, 50 g', 26, Img3d.pot),
    Food('dal', 'Dal, 1 bowl', 8, Img3d.dal),
    Food('whey', 'Whey shake', 24, Img3d.whey),
    Food('curd', 'Greek yogurt', 17, Img3d.milk),
    Food('rajma', 'Rajma rice', 12, Img3d.curryRice),
  ];

  static const List<FocusItem> focusItems = [
    FocusItem('muscle', 'Keeping my muscle', 'Protein and strength', Img3d.biceps),
    FocusItem('nausea', 'Nausea and stomach', 'Spot your patterns', Img3d.nauseated),
    FocusItem('noise', 'Food noise', 'Cravings and appetite', Img3d.brain),
    FocusItem('remember', 'Never missing a dose', 'Reminders and injection sites', Img3d.alarm),
    FocusItem('nerves', 'Injection nerves', 'Calm, guided steps', Img3d.anxious),
    FocusItem('progress', 'Seeing my progress', 'Weight trend and weekly check-ins', Img3d.chartDown),
    FocusItem('cost', 'Cost of treatment', 'Spend and refills', Img3d.moneyBag),
  ];

  static const Map<String, String> symptoms = {
    'nausea': 'Nausea',
    'tired': 'Tiredness',
    'constip': 'Constipation',
    'heartburn': 'Heartburn',
    'diarrhoea': 'Diarrhoea',
    'headache': 'Headache',
    'burping': 'Burping',
    'dizzy': 'Dizziness',
  };
}
