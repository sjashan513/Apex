/// Architectural role: Domain Entity.
/// Defines the strict polymorphic structure of all ranking responses.
/// Enforces the Zero-Degradation standard by requiring fallback styling
/// properties on every item. Sealed hierarchies guarantee exhaustive
/// switch handling at every consumer site.
///
/// Trip 1 models: RankingModel + RankingItem hierarchy (slim list payload)
/// Trip 2 models: RankingItemDetail (unified, query-aware enrichment payload)
library;

// ── Ranking model hierarchy (Trip 1) ──────────────────────────────────────

sealed class RankingModel {
  const RankingModel({
    required this.query,
    required this.title,
    required this.items,
  });

  final String query;
  final String title;
  final List<RankingItem> items;
}

final class MediaRanking extends RankingModel {
  const MediaRanking({
    required super.query,
    required super.title,
    required super.items,
  });
}

final class GeographicRanking extends RankingModel {
  const GeographicRanking({
    required super.query,
    required super.title,
    required super.items,
  });
}

final class TechnicalRanking extends RankingModel {
  const TechnicalRanking({
    required super.query,
    required super.title,
    required super.items,
  });
}

// ── Ranking item hierarchy (Trip 1) ───────────────────────────────────────

/// Base class for all ranking list items.
/// Enforces the hybrid styling bundle required for image hallucination fallbacks.
sealed class RankingItem {
  const RankingItem({
    required this.rank,
    required this.title,
    required this.description,
    required this.primaryColorHex,
    required this.secondaryColorHex,
    required this.iconIdentifier,
    this.imageUrl,
  });

  final int rank;
  final String title;
  final String description;
  final String? imageUrl;
  final String primaryColorHex;
  final String secondaryColorHex;
  final String iconIdentifier;
}

final class MediaItem extends RankingItem {
  const MediaItem({
    required super.rank,
    required super.title,
    required super.description,
    required super.primaryColorHex,
    required super.secondaryColorHex,
    required super.iconIdentifier,
    super.imageUrl,
    required this.creator,
    required this.releaseYear,
    required this.duration,
    required this.rating,
  });

  final String creator;
  final int releaseYear;
  final String duration;
  final double rating;
}

final class GeographicItem extends RankingItem {
  const GeographicItem({
    required super.rank,
    required super.title,
    required super.description,
    required super.primaryColorHex,
    required super.secondaryColorHex,
    required super.iconIdentifier,
    super.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.priceIndex,
    required this.accessibility,
  });

  final double latitude;
  final double longitude;
  final String priceIndex;
  final String accessibility;
}

final class TechnicalItem extends RankingItem {
  const TechnicalItem({
    required super.rank,
    required super.title,
    required super.description,
    required super.primaryColorHex,
    required super.secondaryColorHex,
    required super.iconIdentifier,
    super.imageUrl,
    required this.performanceScore,
    required this.vram,
    required this.tdpWattage,
    required this.price,
  });

  final double performanceScore;
  final String vram;
  final String tdpWattage;
  final String price;
}

// ── Detail model (Trip 2) — unified, query-aware ───────────────────────────

/// A single key-value specification entry.
/// The model generates whatever label/value pairs are contextually relevant.
/// A GPU gets VRAM and TDP. Python gets paradigm and typing discipline.
/// A beach gets water temperature and wave conditions.
/// No field names are hardcoded — the schema adapts to any query.
final class SpecEntry {
  const SpecEntry({required this.label, required this.value});
  final String label;
  final String value;
}

/// Unified enriched detail payload for any item, any archetype, any query.
/// Returned by Trip 2. One class covers all archetypes — no sealed subclasses.
/// The [specs] list is model-generated and contextually appropriate per item.
final class RankingItemDetail {
  const RankingItemDetail({
    required this.title,
    required this.overview,
    required this.specs,
    required this.highlights,
    required this.pros,
    required this.cons,
    required this.bestFor,
  });

  /// The exact item name — matches Trip 1 title.
  final String title;

  /// 3–4 sentence deep dive. More expansive than Trip 1 description.
  final String overview;

  /// Contextually generated key-value pairs.
  /// Rendered as a spec grid — label in eyebrow style, value in body.
  final List<SpecEntry> specs;

  /// 3–4 standout features or facts about this item.
  final List<String> highlights;

  /// Strengths of this item.
  final List<String> pros;

  /// Weaknesses or limitations.
  final List<String> cons;

  /// Who this item is best suited for, or in what context it excels.
  final List<String> bestFor;
}

// ── Humor payload ──────────────────────────────────────────────────────────

/// Returned by the API when the query is nonsense or off-topic.
/// Contains a witty rejection message and redirect chips.
final class HumorPayload {
  const HumorPayload({
    required this.message,
    required this.suggestions,
  });

  final String message;
  final List<SuggestedQuery> suggestions;
}

final class SuggestedQuery {
  const SuggestedQuery({
    required this.query,
    required this.archetype,
  });
  final String query;
  final String archetype; // 'MEDIA' | 'GEOGRAPHIC' | 'TECHNICAL'
}
