/// Everything about the paywall discount offer that should be changeable
/// without an app update. Today it comes from [OfferConfig.defaults];
/// later the same JSON comes from the backend (Firebase Remote Config
/// key `paywall_offer`), parsed with [OfferConfig.fromJson].
///
/// Example backend JSON (every key optional, missing keys use defaults):
/// ```json
/// {
///   "enabled": true,
///   "product_id": "plus_yearly_offer40",
///   "discount_percent": 40,
///   "offer_price": "$23.99",
///   "regular_price": "$39.99",
///   "per_month": "$2.00/mo",
///   "price_note": "for your first year, then $39.99/year",
///   "title": "A welcome offer\nfor your first year",
///   "subtitle": "One time only. You won't see this offer again.",
///   "fine_print": "$23.99 today for 12 months, then $39.99/year. Cancel anytime.",
///   "cta": "Get 40% off",
///   "perks": ["All-time charts and history", "Side-effect patterns", "Share your doctor report"],
///   "max_shows": 1,
///   "cooldown_days": 30,
///   "min_paywall_closes": 1,
///   "show_in_onboarding": true,
///   "show_in_app": true
/// }
/// ```
class OfferConfig {
  const OfferConfig({
    required this.enabled,
    required this.productId,
    required this.discountPercent,
    required this.offerPrice,
    required this.regularPrice,
    required this.perMonth,
    required this.priceNote,
    required this.title,
    required this.subtitle,
    required this.finePrint,
    required this.cta,
    required this.perks,
    required this.maxShows,
    required this.cooldownDays,
    required this.minPaywallCloses,
    required this.showInOnboarding,
    required this.showInApp,
  });

  /// Master switch. False = paywall close just closes.
  final bool enabled;

  /// Store product / offer to buy (RevenueCat). Real prices will come
  /// from the store for this product; the price strings below are the
  /// fallback until then.
  final String productId;

  final int discountPercent;
  final String offerPrice;
  final String regularPrice;
  final String perMonth;

  /// Line under the price, e.g. "for your first year, then $39.99/year".
  final String priceNote;

  final String title;

  /// Shown under the title. Only say "one time" when [maxShows] is 1,
  /// so the screen never claims something untrue.
  final String subtitle;
  final String finePrint;
  final String cta;
  final List<String> perks;

  /// How many times one person can ever see the offer (0 = no limit).
  final int maxShows;

  /// Days to wait before showing it again (when [maxShows] allows).
  final int cooldownDays;

  /// Show only after the paywall was closed this many times (1 = first).
  final int minPaywallCloses;

  /// Where it may appear: the paywall at the end of onboarding, and the
  /// paywall opened from inside the app.
  final bool showInOnboarding;
  final bool showInApp;

  static const OfferConfig defaults = OfferConfig(
    enabled: true,
    productId: 'plus_yearly_offer40',
    discountPercent: 40,
    offerPrice: r'$23.99',
    regularPrice: r'$39.99',
    perMonth: r'$2.00/mo',
    priceNote: r'for your first year, then $39.99/year',
    title: 'A welcome offer\nfor your first year',
    subtitle: "One time only. You won't see this offer again.",
    finePrint: r'$23.99 today for 12 months, then $39.99/year. Cancel anytime.',
    cta: 'Get 40% off',
    perks: ['All-time charts and history', 'Side-effect patterns', 'Share your doctor report'],
    maxShows: 1,
    cooldownDays: 30,
    minPaywallCloses: 1,
    showInOnboarding: true,
    showInApp: true,
  );

  /// Reads backend JSON. Wrong types or missing keys fall back to
  /// [defaults], so a bad config can never break the paywall.
  factory OfferConfig.fromJson(Map<String, dynamic> j) {
    const d = defaults;
    T pick<T>(String key, T fallback) {
      final v = j[key];
      return v is T ? v : fallback;
    }

    int pickInt(String key, int fallback, {int min = 0, int max = 1000}) {
      final v = j[key];
      final n = v is num ? v.round() : fallback;
      return n.clamp(min, max);
    }

    final perks = j['perks'];
    return OfferConfig(
      enabled: pick('enabled', d.enabled),
      productId: pick('product_id', d.productId),
      discountPercent: pickInt('discount_percent', d.discountPercent, min: 1, max: 90),
      offerPrice: pick('offer_price', d.offerPrice),
      regularPrice: pick('regular_price', d.regularPrice),
      perMonth: pick('per_month', d.perMonth),
      priceNote: pick('price_note', d.priceNote),
      title: pick('title', d.title),
      subtitle: pick('subtitle', d.subtitle),
      finePrint: pick('fine_print', d.finePrint),
      cta: pick('cta', d.cta),
      perks: perks is List ? perks.whereType<String>().take(5).toList() : d.perks,
      maxShows: pickInt('max_shows', d.maxShows),
      cooldownDays: pickInt('cooldown_days', d.cooldownDays, max: 3650),
      minPaywallCloses: pickInt('min_paywall_closes', d.minPaywallCloses, min: 1, max: 100),
      showInOnboarding: pick('show_in_onboarding', d.showInOnboarding),
      showInApp: pick('show_in_app', d.showInApp),
    );
  }
}
