/// Card definitions and loader. The 70-card data lives in
/// `assets/data/cards.json` (single source of truth, copied unchanged
/// from the legacy Kotlin project so behaviour stays identical).
library;

class CardDef {
  final String id;
  final String titleEn;
  final String titleId;
  final String flavorEn;
  final String flavorId;
  final String effect;
  final bool isLuck;

  const CardDef({
    required this.id,
    required this.titleEn,
    required this.titleId,
    required this.flavorEn,
    required this.flavorId,
    required this.effect,
    this.isLuck = false,
  });

  factory CardDef.fromJson(Map<String, dynamic> j) => CardDef(
        id: j['id'] as String,
        titleEn: j['titleEn'] as String,
        titleId: j['titleId'] as String,
        flavorEn: j['flavorEn'] as String,
        flavorId: j['flavorId'] as String,
        effect: j['effect'] as String,
        isLuck: j['isLuck'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'titleEn': titleEn,
        'titleId': titleId,
        'flavorEn': flavorEn,
        'flavorId': flavorId,
        'effect': effect,
        'isLuck': isLuck,
      };
}

class CardLibrary {
  final List<CardDef> events;
  final List<CardDef> goodLuck;
  final List<CardDef> badLuck;

  const CardLibrary({
    required this.events,
    required this.goodLuck,
    required this.badLuck,
  });

  factory CardLibrary.fromJson(Map<String, dynamic> j) => CardLibrary(
        events: ((j['events'] as List?) ?? [])
            .map((e) => CardDef.fromJson(e as Map<String, dynamic>))
            .toList(),
        goodLuck: ((j['goodLuck'] as List?) ?? [])
            .map((e) => CardDef.fromJson(e as Map<String, dynamic>))
            .toList(),
        badLuck: ((j['badLuck'] as List?) ?? [])
            .map((e) => CardDef.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// Find a card by ID across all three piles.
  CardDef? findById(String id) {
    for (final c in events) {
      if (c.id == id) return c;
    }
    for (final c in goodLuck) {
      if (c.id == id) return c;
    }
    for (final c in badLuck) {
      if (c.id == id) return c;
    }
    return null;
  }
}
