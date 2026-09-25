import 'package:flutter/material.dart';

import 'images.dart';

/// Static reference data used across the app. Strengths are the pack sizes
/// printed on each product. Kindose only records what the user's doctor
/// prescribed. It never suggests a dose.
class Medicine {
  const Medicine({
    required this.id,
    required this.name,
    required this.sub,
    required this.color,
    required this.dark,
    required this.strengths,
    this.isTablet = false,
  });

  final String id;
  final String name;
  final String sub;
  final Color color;
  final Color dark;
  final List<double> strengths;
  final bool isTablet;
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

  static const List<Medicine> medicines = [
    Medicine(
      id: 'mounjaro',
      name: 'Mounjaro',
      sub: 'Tirzepatide · weekly',
      color: Color(0xFF8B7CFF),
      dark: Color(0xFF4336D9),
      strengths: [2.5, 5, 7.5, 10, 12.5, 15],
    ),
    Medicine(
      id: 'zepbound',
      name: 'Zepbound',
      sub: 'Tirzepatide · weekly',
      color: Color(0xFFFF9A62),
      dark: Color(0xFFD4581B),
      strengths: [2.5, 5, 7.5, 10, 12.5, 15],
    ),
    Medicine(
      id: 'wegovy',
      name: 'Wegovy',
      sub: 'Semaglutide · weekly',
      color: Color(0xFF5CCBF0),
      dark: Color(0xFF1788B0),
      strengths: [0.25, 0.5, 1, 1.7, 2.4],
    ),
    Medicine(
      id: 'ozempic',
      name: 'Ozempic',
      sub: 'Semaglutide · weekly',
      color: Color(0xFF7BD8B0),
      dark: Color(0xFF2E9C6D),
      strengths: [0.25, 0.5, 1, 2],
    ),
    Medicine(
      id: 'generic',
      name: 'Generic',
      sub: 'Semaglutide · other brands',
      color: Color(0xFFC9E86A),
      dark: Color(0xFF7FA11C),
      strengths: [0.25, 0.5, 1, 1.7, 2.4],
    ),
    Medicine(
      id: 'rybelsus',
      name: 'Rybelsus',
      sub: 'Semaglutide · daily tablet',
      color: Color(0xFFFFFFFF),
      dark: Color(0xFFB9B7D6),
      strengths: [3, 7, 14],
      isTablet: true,
    ),
  ];

  static Medicine medicine(String id) =>
      medicines.firstWhere((m) => m.id == id, orElse: () => medicines.first);

  /// Formats 2.5 → "2.5", 5.0 → "5", 0.25 → "0.25".
  static String mg(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    final s = v.toStringAsFixed(2);
    return s.endsWith('0') ? s.substring(0, s.length - 1) : s;
  }

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
    FocusItem('muscle', 'Keeping my muscle', 'Protein & strength', Img3d.biceps),
    FocusItem('nausea', 'Nausea & stomach', 'Spot your patterns', Img3d.nauseated),
    FocusItem('noise', 'Food noise', 'Cravings & appetite', Img3d.brain),
    FocusItem('remember', 'Never missing a dose', 'Reminders & sites', Img3d.alarm),
    FocusItem('nerves', 'Injection nerves', 'Calm, guided steps', Img3d.anxious),
    FocusItem('cost', 'Cost of treatment', 'Spend & refills', Img3d.moneyBag),
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
