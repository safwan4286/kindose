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

/// Where a food's protein comes from, used to filter by diet.
enum FoodSrc { plant, dairy, egg, meat, fish }

class Food {
  const Food(
    this.id,
    this.name,
    this.grams,
    this.icon, {
    this.portion = '',
    this.cat = '',
    this.src = FoodSrc.plant,
  });

  final String id;
  final String name;

  /// Protein in grams for one [portion].
  final int grams;
  final String icon;

  /// "100 g", "1 bowl". Empty when the name already says it.
  final String portion;

  /// Browse category id (see [Catalog.foodCats]).
  final String cat;
  final FoodSrc src;

  /// Saved on log entries: "Greek yogurt, 1 cup, 170 g".
  String get label => portion.isEmpty ? name : '$name, $portion';
}

/// A drink for the water screen. Every millilitre counts toward water.
class Drink {
  const Drink(this.id, this.label, this.ml, {this.dairy = false, this.oz});

  final String id;
  final String label;
  final int ml;
  final bool dairy;

  /// US size in fluid ounces, used instead of [ml] for people who see
  /// water in fl oz (a glass is 8 fl oz there, not 250 ml).
  final double? oz;

  /// Millilitres to log for this person.
  int mlFor(bool useOz) {
    final o = oz;
    return useOz && o != null ? (o * 29.5735).round() : ml;
  }
}

class InjectionSite {
  const InjectionSite(this.id, this.name, this.x, this.y);

  final String id;
  final String name;

  /// Centre of the spot on the 200 × 300 body map (body facing you, so the
  /// user's right side is on the left of the drawing).
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

  /// Rotation order: belly, thighs, arms, alternating sides. Old logs
  /// used 'lbelly' / 'rbelly', which are now the lower belly spots.
  static const List<InjectionSite> sites = [
    InjectionSite('lbelly', 'Lower left belly', 121, 162),
    InjectionSite('rbelly', 'Lower right belly', 79, 162),
    InjectionSite('lthigh', 'Left thigh', 120, 215),
    InjectionSite('rthigh', 'Right thigh', 80, 215),
    InjectionSite('lbellyU', 'Upper left belly', 121, 128),
    InjectionSite('rbellyU', 'Upper right belly', 79, 128),
    InjectionSite('larm', 'Left arm', 151, 112),
    InjectionSite('rarm', 'Right arm', 49, 112),
  ];

  static String siteName(String id) =>
      sites.firstWhere((s) => s.id == id, orElse: () => sites.first).name;

  /// The spot used longest ago. [history] is site ids, newest first.
  /// Spots never used win, in rotation order.
  static String nextSite(List<String> history) {
    var best = sites.first.id;
    var bestAge = -1;
    for (final s in sites) {
      final i = history.indexOf(s.id);
      final age = i == -1 ? 1 << 30 : i;
      if (age > bestAge) {
        best = s.id;
        bestAge = age;
      }
    }
    return best;
  }

  /// "How did it feel?" answers, index = stored value.
  static const List<String> painLabels = [
    'None',
    'A little',
    'Sore',
    'Painful',
  ];

  static const List<Mood> moods = [
    Mood('Great', Img3d.great),
    Mood('Good', Img3d.smile),
    Mood('Okay', Img3d.neutral),
    Mood('Low', Img3d.frown),
    Mood('Rough', Img3d.nauseated),
  ];

  static const List<Food> everydayFoods = [
    Food('egg', '2 eggs', 12, Img3d.egg),
    Food('chicken', 'Chicken, 100 g', 31, Img3d.chicken),
    Food('curd', 'Greek yogurt', 17, Img3d.milk),
    Food('whey', 'Protein shake', 24, Img3d.whey),
    Food('cottage', 'Cottage cheese', 14, Img3d.cheese),
    Food('tuna', 'Tuna, 1 can', 20, Img3d.canned),
  ];

  static const List<Food> vegFoods = [
    Food('curd', 'Greek yogurt', 17, Img3d.milk),
    Food('egg', '2 eggs', 12, Img3d.egg),
    Food('cottage', 'Cottage cheese', 14, Img3d.cheese),
    Food('lentils', 'Lentils, 1/2 cup', 9, Img3d.beans),
    Food('tofu', 'Tofu, 100 g', 12, Img3d.pot),
    Food('whey', 'Protein shake', 24, Img3d.whey),
  ];

  /// Browse chips on the protein screen.
  static const List<(String, String)> foodCats = [
    ('all', 'All'),
    ('dairy', 'Dairy'),
    ('egg', 'Eggs'),
    ('meat', 'Meat'),
    ('fish', 'Fish & seafood'),
    ('beans', 'Beans & lentils'),
    ('soy', 'Soy & tofu'),
    ('shake', 'Shakes & bars'),
    ('meal', 'Everyday'),
    ('snack', 'Snacks'),
  ];

  /// Protein food library. Typical amounts for the portion shown; labels
  /// and recipes vary, which the screen says. Portions show both US cups /
  /// ounces and metric where people use either.
  static const List<Food> foods = [
    // Dairy
    Food(
      'curd',
      'Greek yogurt',
      17,
      Img3d.milk,
      portion: '1 cup, 170 g',
      cat: 'dairy',
      src: FoodSrc.dairy,
    ),
    Food(
      'cottage',
      'Cottage cheese',
      14,
      Img3d.cheese,
      portion: '1/2 cup, 113 g',
      cat: 'dairy',
      src: FoodSrc.dairy,
    ),
    Food(
      'skyr',
      'Skyr',
      15,
      Img3d.milk,
      portion: '1 pot, 150 g',
      cat: 'dairy',
      src: FoodSrc.dairy,
    ),
    Food(
      'milk',
      'Milk',
      8,
      Img3d.milk,
      portion: '1 cup, 240 ml',
      cat: 'dairy',
      src: FoodSrc.dairy,
    ),
    Food(
      'cheese',
      'Cheese',
      7,
      Img3d.cheese,
      portion: '1 oz, 28 g',
      cat: 'dairy',
      src: FoodSrc.dairy,
    ),
    Food(
      'stringcheese',
      'String cheese',
      7,
      Img3d.cheese,
      portion: '1 stick',
      cat: 'snack',
      src: FoodSrc.dairy,
    ),
    // Eggs
    Food(
      'egg',
      'Eggs',
      12,
      Img3d.egg,
      portion: '2 large',
      cat: 'egg',
      src: FoodSrc.egg,
    ),
    Food(
      'eggwhite',
      'Egg whites',
      11,
      Img3d.egg,
      portion: '3 whites',
      cat: 'egg',
      src: FoodSrc.egg,
    ),
    // Meat
    Food(
      'chicken',
      'Chicken breast',
      31,
      Img3d.chicken,
      portion: '100 g (3.5 oz) cooked',
      cat: 'meat',
      src: FoodSrc.meat,
    ),
    Food(
      'turkey',
      'Turkey slices',
      10,
      Img3d.meat,
      portion: '3 slices, 56 g',
      cat: 'meat',
      src: FoodSrc.meat,
    ),
    Food(
      'beef',
      'Lean beef',
      26,
      Img3d.meat,
      portion: '100 g (3.5 oz) cooked',
      cat: 'meat',
      src: FoodSrc.meat,
    ),
    Food(
      'jerky',
      'Beef jerky',
      9,
      Img3d.meat,
      portion: '1 oz, 28 g',
      cat: 'snack',
      src: FoodSrc.meat,
    ),
    // Fish & seafood
    Food(
      'salmon',
      'Salmon',
      22,
      Img3d.fish,
      portion: '100 g (3.5 oz) cooked',
      cat: 'fish',
      src: FoodSrc.fish,
    ),
    Food(
      'tuna',
      'Tuna, canned',
      20,
      Img3d.canned,
      portion: '1 small can, drained',
      cat: 'fish',
      src: FoodSrc.fish,
    ),
    Food(
      'whitefish',
      'White fish',
      20,
      Img3d.fish,
      portion: '100 g (3.5 oz) cooked',
      cat: 'fish',
      src: FoodSrc.fish,
    ),
    Food(
      'shrimp',
      'Shrimp / prawns',
      20,
      Img3d.shrimp,
      portion: '85 g (3 oz) cooked',
      cat: 'fish',
      src: FoodSrc.fish,
    ),
    // Beans & lentils
    Food(
      'lentils',
      'Lentils',
      9,
      Img3d.beans,
      portion: '1/2 cup cooked',
      cat: 'beans',
    ),
    Food(
      'chickpeas',
      'Chickpeas',
      7,
      Img3d.beans,
      portion: '1/2 cup',
      cat: 'beans',
    ),
    Food(
      'blackbeans',
      'Black beans',
      8,
      Img3d.beans,
      portion: '1/2 cup',
      cat: 'beans',
    ),
    Food('hummus', 'Hummus', 5, Img3d.bowl, portion: '1/4 cup', cat: 'beans'),
    // Soy & tofu
    Food('tofu', 'Tofu, firm', 12, Img3d.pot, portion: '100 g', cat: 'soy'),
    Food('tempeh', 'Tempeh', 16, Img3d.pot, portion: '85 g (3 oz)', cat: 'soy'),
    Food(
      'edamame',
      'Edamame',
      9,
      Img3d.beans,
      portion: '1/2 cup shelled',
      cat: 'soy',
    ),
    Food(
      'soymilk',
      'Soy milk',
      7,
      Img3d.milk,
      portion: '1 cup, 240 ml',
      cat: 'soy',
    ),
    // Shakes & bars
    Food(
      'whey',
      'Protein shake',
      24,
      Img3d.whey,
      portion: '1 scoop',
      cat: 'shake',
      src: FoodSrc.dairy,
    ),
    Food(
      'rtd',
      'Ready-to-drink shake',
      30,
      Img3d.whey,
      portion: '1 bottle',
      cat: 'shake',
      src: FoodSrc.dairy,
    ),
    Food(
      'plant',
      'Plant protein shake',
      20,
      Img3d.whey,
      portion: '1 scoop',
      cat: 'shake',
    ),
    Food(
      'bar',
      'Protein bar',
      20,
      Img3d.whey,
      portion: '1 bar',
      cat: 'shake',
      src: FoodSrc.dairy,
    ),
    // Everyday
    Food(
      'oats',
      'Oatmeal',
      5,
      Img3d.bowl,
      portion: '1 cup cooked',
      cat: 'meal',
    ),
    Food(
      'bread',
      'Wholegrain bread',
      4,
      Img3d.bread,
      portion: '1 slice',
      cat: 'meal',
    ),
    Food('pasta', 'Pasta', 8, Img3d.bowl, portion: '1 cup cooked', cat: 'meal'),
    Food(
      'quinoa',
      'Quinoa',
      8,
      Img3d.bowl,
      portion: '1 cup cooked',
      cat: 'meal',
    ),
    Food('rice', 'Rice', 4, Img3d.bowl, portion: '1 cup cooked', cat: 'meal'),
    // Snacks
    Food(
      'pb',
      'Peanut butter',
      7,
      Img3d.peanuts,
      portion: '2 tbsp',
      cat: 'snack',
    ),
    Food(
      'almonds',
      'Almonds',
      6,
      Img3d.peanuts,
      portion: '1 oz, 28 g',
      cat: 'snack',
    ),
    Food(
      'peanuts',
      'Peanuts',
      7,
      Img3d.peanuts,
      portion: '1 oz, 28 g',
      cat: 'snack',
    ),
  ];

  /// [foods] allowed for a diet: 'nonveg' (everything), 'pesc'
  /// (pescatarian), 'veg' (vegetarian, with dairy and eggs), 'vegan'.
  /// Older saved values: 'egg' and 'jain' are read as vegetarian.
  static List<Food> foodsFor(String? diet) => foods.where((f) {
    switch (diet) {
      case 'veg' || 'egg' || 'jain':
        return f.src != FoodSrc.meat && f.src != FoodSrc.fish;
      case 'pesc':
        return f.src != FoodSrc.meat;
      case 'vegan':
        return f.src == FoodSrc.plant;
      default:
        return true;
    }
  }).toList();

  /// True for diets without meat or fish.
  static bool isMeatFree(String? diet) =>
      diet == 'veg' || diet == 'vegan' || diet == 'egg' || diet == 'jain';

  /// Browse chips that have at least one food for this diet.
  static List<(String, String)> foodCatsFor(String? diet) {
    final list = foodsFor(diet);
    return foodCats
        .where((c) => c.$1 == 'all' || list.any((f) => f.cat == c.$1))
        .toList();
  }

  /// The library food a saved label came from ("Greek yogurt, 1 cup" or
  /// the Today chip name "Greek yogurt"), or null.
  static Food? foodByLabel(String label) {
    for (final f in foods) {
      if (f.label == label || f.name == label || label.startsWith('${f.name},'))
        return f;
    }
    return null;
  }

  static const List<Drink> waterSizes = [
    Drink('glass', 'Glass', 250, oz: 8),
    Drink('bottle', 'Bottle', 500, oz: 16.9),
    Drink('litre', 'Large bottle', 1000, oz: 32),
  ];

  static const List<Drink> otherDrinks = [
    Drink('tea', 'Tea', 240, dairy: true, oz: 8),
    Drink('coffee', 'Coffee', 240, oz: 8),
    Drink('milk', 'Milk', 240, dairy: true, oz: 8),
    Drink('sparkling', 'Sparkling water', 330, oz: 12),
    Drink('electrolyte', 'Electrolyte drink', 500, oz: 16.9),
    Drink('coconut', 'Coconut water', 330, oz: 11),
  ];

  /// One-tap protein foods for Today, matched to how the user eats
  /// (see [foodsFor]; empty = everyday list).
  static List<Food> quickFoods(String? diet) => switch (diet) {
    'veg' || 'egg' || 'jain' => const [
      Food('curd', 'Greek yogurt', 17, Img3d.milk),
      Food('egg', '2 eggs', 12, Img3d.egg),
      Food('cottage', 'Cottage cheese', 14, Img3d.cheese),
      Food('lentils', 'Lentils, 1/2 cup', 9, Img3d.beans),
      Food('whey', 'Protein shake', 24, Img3d.whey),
    ],
    'pesc' => const [
      Food('egg', '2 eggs', 12, Img3d.egg),
      Food('salmon', 'Salmon, 100 g', 22, Img3d.fish),
      Food('curd', 'Greek yogurt', 17, Img3d.milk),
      Food('tuna', 'Tuna, 1 can', 20, Img3d.canned),
      Food('whey', 'Protein shake', 24, Img3d.whey),
    ],
    'vegan' => const [
      Food('tofu', 'Tofu, 100 g', 12, Img3d.pot),
      Food('edamame', 'Edamame, 1/2 cup', 9, Img3d.beans),
      Food('lentils', 'Lentils, 1/2 cup', 9, Img3d.beans),
      Food('plant', 'Plant protein shake', 20, Img3d.whey),
      Food('pb', 'Peanut butter, 2 tbsp', 7, Img3d.peanuts),
    ],
    _ => const [
      Food('egg', '2 eggs', 12, Img3d.egg),
      Food('chicken', 'Chicken, 100 g', 31, Img3d.chicken),
      Food('curd', 'Greek yogurt', 17, Img3d.milk),
      Food('cottage', 'Cottage cheese', 14, Img3d.cheese),
      Food('whey', 'Protein shake', 24, Img3d.whey),
    ],
  };

  /// Short, general tips for Today, grouped by what the user asked help
  /// with. Friendly habits only, never medical instructions.
  static const Map<String, List<String>> tips = {
    'muscle': [
      'Start each meal with the protein. Smaller appetite means the first bites count most.',
      'Spread protein over the day. 25–30 g per meal is easier than one big serving.',
      'A short strength workout 2–3 times a week helps you keep muscle while you lose weight.',
    ],
    'nausea': [
      'Eat slowly and stop at "just full". Big meals are the usual trigger.',
      'Greasy and very sweet foods are harder on the stomach this week.',
      'Sip water through the day instead of large amounts at once.',
    ],
    'noise': [
      'Notice when food thoughts get loud. Logging it helps you see the pattern.',
      'Keep an easy protein snack ready for the moments cravings show up.',
    ],
    'remember': [
      'Keep your pen or tablets somewhere you see on dose day.',
      'Logging right after you take it keeps your schedule exact.',
    ],
    'nerves': [
      'Take a slow breath out as you inject. Many people find it helps.',
      'Same calm spot, same time each week. Routine makes it easier.',
    ],
    'progress': [
      'Weigh in at the same time of day, like after waking up, for a fair trend.',
      'Weekly averages tell the story better than any single day.',
    ],
    'cost': [
      'Note when you open a new pen so refills never catch you off guard.',
    ],
  };

  static const List<String> doseDayTips = [
    'Smaller meals and plenty of water today can make the next two days feel easier.',
    'Protein first, go light on fried food today.',
  ];

  static const List<FocusItem> focusItems = [
    FocusItem(
      'muscle',
      'Keeping my muscle',
      'Protein to protect muscle',
      Img3d.biceps,
    ),
    FocusItem(
      'nausea',
      'Nausea and stomach',
      'Spot your patterns',
      Img3d.nauseated,
    ),
    FocusItem('noise', 'Food noise', 'Cravings and appetite', Img3d.brain),
    FocusItem(
      'remember',
      'Never missing a dose',
      'Reminders and injection sites',
      Img3d.alarm,
    ),
    FocusItem(
      'nerves',
      'Injection nerves',
      'Calm, guided steps',
      Img3d.anxious,
    ),
    FocusItem(
      'progress',
      'Seeing my progress',
      'Weight trend and weekly check-ins',
      Img3d.chartDown,
    ),
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
    'bloat': 'Bloating',
    'vomit': 'Vomiting',
  };

  /// Side-effect chips on the check-in, in order (nausea has its own row).
  static const List<String> checkInEffects = [
    'tired',
    'constip',
    'heartburn',
    'bloat',
    'burping',
    'diarrhoea',
    'vomit',
    'headache',
    'dizzy',
  ];

  /// Words for a side-effect level (index 1–3).
  static const List<String> levelWords = ['', 'mild', 'moderate', 'severe'];
}
