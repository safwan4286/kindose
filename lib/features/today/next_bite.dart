import '../../models/logs.dart';
import '../../models/user_profile.dart';
import '../../resources/catalog.dart';
import '../../resources/date_utils.dart';
import '../../resources/images.dart';
import '../../services/tracker_service.dart';

/// How much the user can likely eat right now.
enum BiteMode {
  /// Nausea logged: cold, bland, sip-slowly options.
  gentle,

  /// Low appetite (said so, rough day, or the first days after a dose).
  small,

  /// A normal day.
  normal,
}

enum MealSlot { breakfast, lunch, snack, dinner }

/// One food idea on the Next bite card.
class BiteIdea {
  const BiteIdea(
    this.id,
    this.name,
    this.portion,
    this.grams,
    this.icon, {
    required this.src,
    required this.modes,
    required this.slots,
  });

  final String id;
  final String name;
  final String portion;
  final int grams;
  final String icon;
  final FoodSrc src;
  final Set<BiteMode> modes;
  final Set<MealSlot> slots;

  /// Saved on the log entry, like the food library: "Greek yogurt, 1/2 cup".
  /// Tips like "· sip slowly" stay on the card, not in the log.
  String get label => '$name, ${portion.split(' · ').first}';
}

/// What the card shows right now.
class NextBite {
  const NextBite({
    required this.have,
    required this.goal,
    required this.mode,
    required this.slot,
    required this.context,
    required this.lead,
    required this.tip,
    required this.ideas,
    required this.reasons,
  });

  final int have;
  final int goal;
  final BiteMode mode;
  final MealSlot slot;

  /// "Day 2 after your dose · appetite may be low".
  final String context;

  /// "Something small and easy:".
  final String lead;
  final String? tip;

  /// Best first. The card shows 1 (free) or 3 (Plus).
  final List<BiteIdea> ideas;

  /// Plain reasons for the "Why these?" sheet.
  final List<String> reasons;

  int get left => (goal - have).clamp(0, 999);
  bool get goalHit => have >= goal;

  static const Set<MealSlot> _all = {
    MealSlot.breakfast,
    MealSlot.lunch,
    MealSlot.snack,
    MealSlot.dinner,
  };
  static const _b = MealSlot.breakfast;
  static const _l = MealSlot.lunch;
  static const _s = MealSlot.snack;
  static const _d = MealSlot.dinner;
  static const _g = BiteMode.gentle;
  static const _m = BiteMode.small;
  static const _n = BiteMode.normal;

  /// Typical protein for the portion shown. General food ideas, not advice.
  static const List<BiteIdea> pool = [
    BiteIdea(
      'rtd',
      'Ready-to-drink shake',
      '1 bottle · sip slowly',
      30,
      Img3d.whey,
      src: FoodSrc.dairy,
      modes: {_g, _m, _n},
      slots: _all,
    ),
    BiteIdea(
      'shake',
      'Protein shake',
      '1 scoop · sip slowly',
      24,
      Img3d.whey,
      src: FoodSrc.dairy,
      modes: {_g, _m},
      slots: _all,
    ),
    BiteIdea(
      'plantshake',
      'Plant protein shake',
      '1 scoop',
      20,
      Img3d.whey,
      src: FoodSrc.plant,
      modes: {_g, _m, _n},
      slots: _all,
    ),
    BiteIdea(
      'yoghalf',
      'Greek yogurt',
      '1/2 cup, 85 g',
      9,
      Img3d.milk,
      src: FoodSrc.dairy,
      modes: {_g, _m},
      slots: {_b, _s, _d},
    ),
    BiteIdea(
      'yogcup',
      'Greek yogurt',
      '1 cup, 170 g',
      17,
      Img3d.milk,
      src: FoodSrc.dairy,
      modes: {_m, _n},
      slots: {_b, _s},
    ),
    BiteIdea(
      'cottage',
      'Cottage cheese with fruit',
      '1/2 cup',
      14,
      Img3d.cheese,
      src: FoodSrc.dairy,
      modes: {_m, _n},
      slots: {_b, _s},
    ),
    BiteIdea(
      'crackers',
      'Crackers + cottage cheese',
      '1/4 cup',
      7,
      Img3d.bread,
      src: FoodSrc.dairy,
      modes: {_g},
      slots: {_s, _l, _d},
    ),
    BiteIdea(
      'stringcheese',
      'String cheese',
      '1 stick',
      7,
      Img3d.cheese,
      src: FoodSrc.dairy,
      modes: {_m},
      slots: {_s, _l},
    ),
    BiteIdea(
      'milk',
      'Glass of milk',
      '1 cup, 240 ml',
      8,
      Img3d.milk,
      src: FoodSrc.dairy,
      modes: {_g, _m},
      slots: {_b, _s, _d},
    ),
    BiteIdea(
      'oats',
      'Protein oats',
      '1 cup + 1/2 scoop',
      17,
      Img3d.bowl,
      src: FoodSrc.dairy,
      modes: {_m, _n},
      slots: {_b},
    ),
    BiteIdea(
      'bar',
      'Protein bar',
      '1 bar',
      20,
      Img3d.whey,
      src: FoodSrc.dairy,
      modes: {_m, _n},
      slots: {_s},
    ),
    BiteIdea(
      'egg1',
      'Scrambled egg',
      '1 large',
      6,
      Img3d.egg,
      src: FoodSrc.egg,
      modes: {_g, _m},
      slots: {_b, _l},
    ),
    BiteIdea(
      'eggs2',
      'Hard-boiled eggs',
      '2 large',
      12,
      Img3d.egg,
      src: FoodSrc.egg,
      modes: {_m, _n},
      slots: {_s, _l, _b},
    ),
    BiteIdea(
      'eggstoast',
      '2 eggs + toast',
      '2 large, 1 slice',
      16,
      Img3d.egg,
      src: FoodSrc.egg,
      modes: {_n},
      slots: {_b, _l},
    ),
    BiteIdea(
      'chicken',
      'Chicken breast',
      '3.5 oz, 100 g cooked',
      31,
      Img3d.chicken,
      src: FoodSrc.meat,
      modes: {_n},
      slots: {_l, _d},
    ),
    BiteIdea(
      'broth',
      'Chicken soup',
      '1 bowl',
      10,
      Img3d.bowl,
      src: FoodSrc.meat,
      modes: {_g, _m},
      slots: {_l, _d},
    ),
    BiteIdea(
      'turkeywrap',
      'Turkey wrap',
      '3 slices + tortilla',
      14,
      Img3d.meat,
      src: FoodSrc.meat,
      modes: {_n, _m},
      slots: {_l},
    ),
    BiteIdea(
      'beef',
      'Lean beef',
      '3.5 oz, 100 g cooked',
      26,
      Img3d.meat,
      src: FoodSrc.meat,
      modes: {_n},
      slots: {_d},
    ),
    BiteIdea(
      'jerky',
      'Beef jerky',
      '1 oz, 28 g',
      9,
      Img3d.meat,
      src: FoodSrc.meat,
      modes: {_m},
      slots: {_s},
    ),
    BiteIdea(
      'tuna',
      'Tuna salad',
      '1 small can',
      20,
      Img3d.canned,
      src: FoodSrc.fish,
      modes: {_m, _n},
      slots: {_l, _d},
    ),
    BiteIdea(
      'salmon',
      'Salmon',
      '3.5 oz, 100 g cooked',
      22,
      Img3d.fish,
      src: FoodSrc.fish,
      modes: {_n},
      slots: {_l, _d},
    ),
    BiteIdea(
      'whitefish',
      'Baked white fish',
      '3.5 oz, 100 g cooked',
      20,
      Img3d.fish,
      src: FoodSrc.fish,
      modes: {_g, _n},
      slots: {_d},
    ),
    BiteIdea(
      'shrimp',
      'Shrimp',
      '3 oz, 85 g cooked',
      20,
      Img3d.shrimp,
      src: FoodSrc.fish,
      modes: {_n},
      slots: {_l, _d},
    ),
    BiteIdea(
      'lentilsoup',
      'Lentil soup',
      '1 bowl',
      12,
      Img3d.bowl,
      src: FoodSrc.plant,
      modes: {_g, _m, _n},
      slots: {_l, _d},
    ),
    BiteIdea(
      'tofu',
      'Tofu stir-fry',
      '100 g tofu',
      12,
      Img3d.pot,
      src: FoodSrc.plant,
      modes: {_n},
      slots: {_l, _d},
    ),
    BiteIdea(
      'edamame',
      'Edamame',
      '1/2 cup shelled',
      9,
      Img3d.beans,
      src: FoodSrc.plant,
      modes: {_m, _n},
      slots: {_s},
    ),
    BiteIdea(
      'pbtoast',
      'Peanut butter toast',
      '2 tbsp, 1 slice',
      11,
      Img3d.peanuts,
      src: FoodSrc.plant,
      modes: {_m, _n},
      slots: {_b, _s},
    ),
    BiteIdea(
      'soymilk',
      'Soy milk',
      '1 cup, 240 ml',
      7,
      Img3d.milk,
      src: FoodSrc.plant,
      modes: {_g, _m},
      slots: _all,
    ),
    BiteIdea(
      'hummus',
      'Hummus + veggies',
      '1/4 cup',
      5,
      Img3d.salad,
      src: FoodSrc.plant,
      modes: {_m},
      slots: {_s},
    ),
  ];

  static MealSlot slotAt(DateTime now) {
    final m = now.hour * 60 + now.minute;
    if (m < 10 * 60 + 30) return MealSlot.breakfast;
    if (m < 14 * 60 + 30) return MealSlot.lunch;
    if (m < 17 * 60 + 30) return MealSlot.snack;
    return MealSlot.dinner;
  }

  static bool _allowed(BiteIdea i, String? diet) => switch (diet) {
    'veg' || 'egg' || 'jain' => i.src != FoodSrc.meat && i.src != FoodSrc.fish,
    'pesc' => i.src != FoodSrc.meat,
    'vegan' => i.src == FoodSrc.plant,
    _ => true,
  };

  /// Builds the card for [now]. [skip] = ideas already added from the card
  /// today, so a fresh one slides in.
  static NextBite build(
    TrackerService t,
    DateTime now, {
    Set<String> skip = const {},
  }) {
    final p = t.profile.value;
    final day = t.dayLog(now);
    final goal = p?.proteinGoalG ?? 100;
    final have = day.proteinG;
    final slot = slotAt(now);
    final reasons = <String>[
      '${(goal - have).clamp(0, 999)} g protein still to go today',
    ];

    // ------------------------------------------------------------ mode
    var mode = BiteMode.normal;
    String context;
    final nausea = day.nausea != null || day.symptoms.contains('nausea');
    final daysSince = _daysSinceDose(t, p, now);
    if (nausea) {
      mode = BiteMode.gentle;
      context = 'Nausea logged today';
      reasons.add(
        'You logged nausea today, so these are cold, bland or easy to sip',
      );
    } else if (day.appetite == 0 || day.mood == 4) {
      mode = BiteMode.small;
      context = day.appetite == 0 ? 'Appetite low today' : 'A rough day';
      reasons.add(
        'You said today is a low-appetite day, so portions are small',
      );
    } else if (daysSince != null && daysSince <= 2) {
      mode = BiteMode.small;
      context = daysSince == 0
          ? 'Dose day · appetite may be low'
          : 'Day $daysSince after your dose · appetite may be low';
      reasons.add('Appetite is often lower in the first days after a dose');
    } else {
      context = switch (slot) {
        MealSlot.breakfast => 'Breakfast time',
        MealSlot.lunch => 'Lunch time',
        MealSlot.snack => 'Afternoon snack',
        MealSlot.dinner => 'Dinner time',
      };
    }

    final lead = switch (mode) {
      BiteMode.gentle => 'Cold, bland and gentle:',
      BiteMode.small => 'Something small and easy:',
      BiteMode.normal => switch (slot) {
        MealSlot.breakfast => 'A protein-first breakfast:',
        MealSlot.lunch => 'A proper lunch gets you most of the way:',
        MealSlot.snack => 'A snack that counts:',
        MealSlot.dinner => 'Dinner ideas to close the gap:',
      },
    };
    final tip = switch (mode) {
      BiteMode.gentle =>
        'Cold, plain foods are often easier. Skip greasy or very sweet food.',
      BiteMode.small =>
        'Small amounts often, protein first. Sip shakes slowly.',
      BiteMode.normal => null,
    };

    // ----------------------------------------------------------- ideas
    final diet = p?.diet;
    if (diet != null && diet.isNotEmpty && diet != 'nonveg') {
      reasons.add('Matches how you eat (${_dietWord(diet)})');
    }
    final left = (goal - have).clamp(0, 999);
    final favourites = t
        .favouriteFoods(4)
        .map((f) => f.$1.toLowerCase())
        .toList();

    int score(BiteIdea i) {
      var s = 0;
      if (i.modes.contains(mode)) s += 6;
      if (i.slots.contains(slot)) s += 4;
      if (i.grams <= left + 5) s += 2;
      if (mode == BiteMode.normal) s += i.grams ~/ 8;
      if (favourites.any(
        (f) => f.startsWith(i.name.toLowerCase().split(' ').first),
      ))
        s += 2;
      return s;
    }

    final candidates = pool
        .where((i) => _allowed(i, diet) && !skip.contains(i.id))
        .toList();
    final order = {for (final (n, i) in pool.indexed) i.id: n};
    candidates.sort((a, b) {
      final c = score(b).compareTo(score(a));
      return c != 0 ? c : order[a.id]!.compareTo(order[b.id]!);
    });
    // Keep variety: no two ideas with the same name.
    final picked = <BiteIdea>[];
    for (final i in candidates) {
      if (picked.any((x) => x.name == i.name)) continue;
      picked.add(i);
      if (picked.length == 3) break;
    }
    if (favourites.isNotEmpty) reasons.add('Foods you log often come first');

    return NextBite(
      have: have,
      goal: goal,
      mode: mode,
      slot: slot,
      context: context,
      lead: lead,
      tip: tip,
      ideas: picked,
      reasons: reasons,
    );
  }

  /// Days since the last dose for weekly-style schedules (null for daily
  /// tablets or no dose yet).
  static int? _daysSinceDose(TrackerService t, UserProfile? p, DateTime now) {
    if (p == null || p.isDaily) return null;
    final DoseLog? last = t.lastDose;
    if (last == null) return null;
    final d = Dates.daysBetween(last.takenAt, now);
    return d < 0 ? null : d;
  }

  static String _dietWord(String diet) => switch (diet) {
    'pesc' => 'pescatarian',
    'vegan' => 'vegan',
    _ => 'vegetarian',
  };
}
