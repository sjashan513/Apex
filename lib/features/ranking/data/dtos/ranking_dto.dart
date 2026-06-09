/// Architectural role: Data Transfer Object.
/// Parses raw OpenAI JSON responses into domain models.
/// This is the only file in the codebase aware of the API's JSON structure.
/// Throws [ValidationException] on any structural mismatch — never returns partial data.
///
/// parse()       — Trip 1: top-level list response → RankingModel | HumorPayload
/// parseDetail() — Trip 2: single-item detail response → RankingItemDetail
///                 One parser, works for all archetypes and all query types.
library;

import '../../domain/models/ranking_model.dart';
import '../../../../core/exceptions/domain_exceptions.dart';

abstract final class RankingDto {
  // ── Trip 1: List response ──────────────────────────────────────────────────

  /// Parses the top-level API response into either a [RankingModel] or [HumorPayload].
  /// Throws [ValidationException] if the structure is missing required fields.
  static Object parse(Map<String, dynamic> json) {
    try {
      final type = json['type'] as String?;
      if (type == null) throw const ValidationException();
      if (type == 'humor') return _parseHumor(json);
      return _parseRanking(json, type);
    } on ValidationException {
      rethrow;
    } catch (_) {
      throw const ValidationException();
    }
  }

  // ── Trip 2: Detail response ────────────────────────────────────────────────

  /// Parses a single-item enriched detail response into a [RankingItemDetail].
  /// Archetype-agnostic — the same parser handles MEDIA, GEOGRAPHIC, and TECHNICAL.
  /// The [specs] array is model-generated and varies per item and query context.
  static RankingItemDetail parseDetail(Map<String, dynamic> json) {
    try {
      _requireFields(json, [
        'title',
        'overview',
        'specs',
        'highlights',
        'pros',
        'cons',
        'bestFor',
      ]);

      final rawSpecs = json['specs'] as List<dynamic>;
      final specs = rawSpecs.map((s) {
        final entry = s as Map<String, dynamic>;
        final label = entry['label'] as String?;
        final value = entry['value'] as String?;
        if (label == null || value == null) throw const ValidationException();
        return SpecEntry(label: label, value: value);
      }).toList();

      return RankingItemDetail(
        title: json['title'] as String,
        overview: json['overview'] as String,
        specs: specs,
        highlights: _castStringList(json['highlights']),
        pros: _castStringList(json['pros']),
        cons: _castStringList(json['cons']),
        bestFor: _castStringList(json['bestFor']),
      );
    } on ValidationException {
      rethrow;
    } catch (_) {
      throw const ValidationException();
    }
  }

  // ── Humor ──────────────────────────────────────────────────────────────────

  static HumorPayload _parseHumor(Map<String, dynamic> json) {
    final message = json['message'] as String?;
    final rawSuggestions = json['suggestions'] as List<dynamic>?;
    if (message == null || rawSuggestions == null) {
      throw const ValidationException();
    }
    return HumorPayload(
      message: message,
      suggestions: rawSuggestions
          .map((suggestedQuery) => SuggestedQuery(
                query: suggestedQuery['query'] as String,
                archetype: suggestedQuery['archetype'] as String,
              ))
          .toList(),
    );
  }

  // ── Ranking list ───────────────────────────────────────────────────────────

  static RankingModel _parseRanking(Map<String, dynamic> json, String type) {
    final query = json['query'] as String?;
    final title = json['title'] as String?;
    final rawItems = json['items'] as List<dynamic>?;
    if (query == null || title == null || rawItems == null) {
      throw const ValidationException();
    }

    final archetype = type.toUpperCase();
    final items = rawItems.map((raw) {
      final item = raw as Map<String, dynamic>;
      return switch (archetype) {
        'MEDIA' => _parseMediaItem(item),
        'GEOGRAPHIC' => _parseGeographicItem(item),
        'TECHNICAL' => _parseTechnicalItem(item),
        _ => throw const ValidationException(),
      };
    }).toList();

    return switch (archetype) {
      'MEDIA' => MediaRanking(query: query, title: title, items: items),
      'GEOGRAPHIC' =>
        GeographicRanking(query: query, title: title, items: items),
      'TECHNICAL' => TechnicalRanking(query: query, title: title, items: items),
      _ => throw const ValidationException(),
    };
  }

  // ── List item parsers ──────────────────────────────────────────────────────

  static MediaItem _parseMediaItem(Map<String, dynamic> j) {
    _requireFields(j, [
      'rank',
      'title',
      'description',
      'primaryColorHex',
      'secondaryColorHex',
      'iconIdentifier',
      'creator',
      'releaseYear',
      'duration',
      'rating',
    ]);
    return MediaItem(
      rank: j['rank'] as int,
      title: j['title'] as String,
      description: j['description'] as String,
      primaryColorHex: j['primaryColorHex'] as String,
      secondaryColorHex: j['secondaryColorHex'] as String,
      iconIdentifier: j['iconIdentifier'] as String,
      imageUrl: j['imageUrl'] as String?,
      creator: j['creator'] as String,
      releaseYear: j['releaseYear'] as int,
      duration: j['duration'] as String,
      rating: (j['rating'] as num).toDouble(),
    );
  }

  static GeographicItem _parseGeographicItem(Map<String, dynamic> j) {
    _requireFields(j, [
      'rank',
      'title',
      'description',
      'primaryColorHex',
      'secondaryColorHex',
      'iconIdentifier',
      'latitude',
      'longitude',
      'priceIndex',
      'accessibility',
    ]);
    return GeographicItem(
      rank: j['rank'] as int,
      title: j['title'] as String,
      description: j['description'] as String,
      primaryColorHex: j['primaryColorHex'] as String,
      secondaryColorHex: j['secondaryColorHex'] as String,
      iconIdentifier: j['iconIdentifier'] as String,
      imageUrl: j['imageUrl'] as String?,
      latitude: (j['latitude'] as num).toDouble(),
      longitude: (j['longitude'] as num).toDouble(),
      priceIndex: j['priceIndex'] as String,
      accessibility: j['accessibility'] as String,
    );
  }

  static TechnicalItem _parseTechnicalItem(Map<String, dynamic> j) {
    _requireFields(j, [
      'rank',
      'title',
      'description',
      'primaryColorHex',
      'secondaryColorHex',
      'iconIdentifier',
      'performanceScore',
      'vram',
      'tdpWattage',
      'price',
    ]);
    return TechnicalItem(
      rank: j['rank'] as int,
      title: j['title'] as String,
      description: j['description'] as String,
      primaryColorHex: j['primaryColorHex'] as String,
      secondaryColorHex: j['secondaryColorHex'] as String,
      iconIdentifier: j['iconIdentifier'] as String,
      imageUrl: j['imageUrl'] as String?,
      performanceScore: (j['performanceScore'] as num).toDouble(),
      vram: j['vram'] as String,
      tdpWattage: j['tdpWattage'] as String,
      price: j['price'] as String,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static List<String> _castStringList(dynamic raw) {
    if (raw is! List) throw const ValidationException();
    return raw.cast<String>();
  }

  static void _requireFields(Map<String, dynamic> json, List<String> fields) {
    for (final field in fields) {
      if (json[field] == null) {
        throw ValidationException(
          message:
              'Missing required field: "$field". Schema validation failed.',
        );
      }
    }
  }
}
