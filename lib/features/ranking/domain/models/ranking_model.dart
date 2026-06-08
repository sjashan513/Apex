/// Architectural role: Domain Entity.
/// Defines the strict polymorphic structure of all ranking responses.
/// Enforces the Zero-Degradation standard by requiring fallback styling
/// properties on every item. Sealed hierarchies guarantee exhaustive
/// switch handling at every consumer site.
library;

// ── Ranking model hierarchy ────────────────────────────────────────────────

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

// ── Ranking item hierarchy ─────────────────────────────────────────────────

/// Base class for all ranking items.
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

// ── Humor payload ──────────────────────────────────────────────────────────

/// Returned by the API when the query is nonsense or off-topic.
/// Contains a witty rejection message and redirect chips.
final class HumorPayload {
  const HumorPayload({
    required this.message,
    required this.suggestions,
  });

  final String message;
  final List<String> suggestions;
}
