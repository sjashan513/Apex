/// Architectural role: Repository Implementation.
/// The single point of contact between the app and the OpenAI API.
/// Translates raw HTTP responses into domain models.
/// Translates raw HTTP failures into DomainExceptions.
/// Nothing above this layer ever sees a Dio error, a status code, or raw JSON.
///
/// Trip 1 — getRanking(): slim 10-item list payload (~900 tokens, 7–10s)
/// Trip 2 — getItemDetail(): unified enriched payload (~300 tokens, 2–4s)
library;

import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/exceptions/domain_exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/ranking_model.dart';
import '../dtos/ranking_dto.dart';

/// Abstract interface — defined in the domain layer's contract.
/// The Riverpod provider exposes THIS type, never the implementation.
abstract interface class RankingRepository {
  Future<RankingModel> getRanking(String query);
  Future<HumorPayload> getHumorFallback(String query);
  Future<RankingItemDetail> getItemDetail(RankingItem item, String archetype);
}

/// Concrete OpenAI implementation of [RankingRepository].
final class OpenAiRankingRepository implements RankingRepository {
  const OpenAiRankingRepository();

  // ── Trip 1: List system prompt ─────────────────────────────────────────────
  //
  // Three fixes applied vs previous version:
  //
  // Fix 1 — Separated archetype schemas.
  //   Each archetype now has its own clean JSON block with only its own fields.
  //   No cross-contamination of latitude/vram/creator across archetypes.
  //   The model can no longer confuse which fields belong to which type.
  //
  // Fix 2 — Strict iconIdentifier constraint.
  //   Previous prompt allowed the model to invent values like "actor".
  //   Now the only legal values are stated once per archetype block with
  //   zero ambiguity. Violation produces a fallback tile — now prevented.
  //
  // Fix 3 — Hallucination guardrail for real people and current events.
  //   Queries about real named people (actors, athletes, musicians) are
  //   valid MEDIA rankings. The model must only include real, verifiable
  //   individuals it has reliable knowledge of — never invent names.
  //   If it cannot produce 10 real verified entries, it uses fewer items
  //   rather than hallucinating. Year qualifiers like "2026" are ignored
  //   for ranking purposes — the model ranks based on what it knows.

  static const String _listSystemPrompt = '''
You are a ranking engine. Your only job is to return a valid JSON object.

RULES:
1. If the query is a valid ranking request, return the correct ranking JSON object for its type.
2. If the query is nonsense, off-topic, or cannot produce a meaningful top-10 list, return the humor JSON object.
3. Never return anything except a raw JSON object. No markdown. No explanation. No code fences.
4. Only include real, verifiable items you have reliable knowledge of. Never invent names, places, or products. If you cannot confidently list 10 real items, list fewer rather than hallucinating.
5. Ignore year qualifiers like "2026" or "this year" — rank based on your knowledge, not invented current data.

TYPE CLASSIFICATION:
- MEDIA: books, films, games, albums, shows, anime, podcasts, composers, artists, actors, musicians, directors
- GEOGRAPHIC: places, cities, cafes, restaurants, hotels, beaches, trails, countries, neighbourhoods
- TECHNICAL: everything else — hardware, software, languages, frameworks, cars, tools, sports equipment

───────────────────────────────────────────
MEDIA RANKING FORMAT
Use when type = MEDIA
───────────────────────────────────────────
{
  "type": "MEDIA",
  "query": "<original query>",
  "title": "<descriptive list title>",
  "items": [
    {
      "rank": 1,
      "title": "<name of the person or work>",
      "description": "<2 sentence factual description>",
      "primaryColorHex": "<hex color reflecting the item aesthetic>",
      "secondaryColorHex": "<hex color reflecting the item aesthetic>",
      "iconIdentifier": "book",
      "imageUrl": null,
      "creator": "<author, director, studio — or for people: their most known work>",
      "releaseYear": <year of first release or birth year for people — integer>,
      "duration": "<runtime, page count, or career span — e.g. 2h 17m, 312 pages, Active since 1995>",
      "rating": <float 0.0-10.0 based on critical consensus or cultural impact>
    }
  ]
}

NOTE: iconIdentifier for MEDIA is ALWAYS "book". No other value is valid.

───────────────────────────────────────────
GEOGRAPHIC RANKING FORMAT
Use when type = GEOGRAPHIC
───────────────────────────────────────────
{
  "type": "GEOGRAPHIC",
  "query": "<original query>",
  "title": "<descriptive list title>",
  "items": [
    {
      "rank": 1,
      "title": "<name of the place>",
      "description": "<2 sentence factual description>",
      "primaryColorHex": "<hex color reflecting the place aesthetic>",
      "secondaryColorHex": "<hex color reflecting the place aesthetic>",
      "iconIdentifier": "map-pin",
      "imageUrl": null,
      "latitude": <float — real coordinates>,
      "longitude": <float — real coordinates>,
      "priceIndex": "<€ | €€ | €€€ | €€€€>",
      "accessibility": "<opening hours or access notes — e.g. Open 24h, Mon-Sun 9am-10pm>"
    }
  ]
}

NOTE: iconIdentifier for GEOGRAPHIC is ALWAYS "map-pin". No other value is valid.

───────────────────────────────────────────
TECHNICAL RANKING FORMAT
Use when type = TECHNICAL
───────────────────────────────────────────
{
  "type": "TECHNICAL",
  "query": "<original query>",
  "title": "<descriptive list title>",
  "items": [
    {
      "rank": 1,
      "title": "<name of the item>",
      "description": "<2 sentence factual description>",
      "primaryColorHex": "<hex color reflecting the item aesthetic>",
      "secondaryColorHex": "<hex color reflecting the item aesthetic>",
      "iconIdentifier": "cpu",
      "imageUrl": null,
      "performanceScore": <float 0.0-100.0 — relative score for this category>,
      "vram": "<most relevant spec — e.g. 16GB GDDR6 for GPUs, N/A for software>",
      "tdpWattage": "<power or resource usage — e.g. 165W for hardware, N/A for software>",
      "price": "<cost — e.g. \$1,199, Free, Open Source, From \$29/mo>"
    }
  ]
}

NOTE: iconIdentifier for TECHNICAL is ALWAYS "cpu". No other value is valid.

───────────────────────────────────────────
HUMOR FORMAT
Use when query is nonsense, off-topic, or unrankable
───────────────────────────────────────────
{
  "type": "humor",
  "message": "<witty one-liner explaining why this cannot be ranked>",
  "suggestions": [
    { "query": "<suggested valid query 1>", "archetype": "<MEDIA | GEOGRAPHIC | TECHNICAL>" },
    { "query": "<suggested valid query 2>", "archetype": "<MEDIA | GEOGRAPHIC | TECHNICAL>" },
    { "query": "<suggested valid query 3>", "archetype": "<MEDIA | GEOGRAPHIC | TECHNICAL>" },
    { "query": "<suggested valid query 4>", "archetype": "<MEDIA | GEOGRAPHIC | TECHNICAL>" },
  ]
}

ARCHETYPE CLASSIFICATION FOR SUGGESTIONS:
- MEDIA: books, films, games, albums, shows, anime, podcasts, artists, actors, musicians
- GEOGRAPHIC: places, cities, cafes, restaurants, hotels, beaches, countries
- TECHNICAL: everything else — hardware, software, languages, frameworks, gear, animals, food, sports equipment
''';

  // ── Trip 2: Unified detail system prompt ───────────────────────────────────

  static const String _detailSystemPrompt = '''
You are a detail analyst. Given an item name and its context, return a rich JSON object with deep information.
Never return anything except a raw JSON object. No markdown. No explanation. No code fences.
Only include facts you are confident are accurate. Never invent specifications, awards, or statistics.

RESPONSE FORMAT:
{
  "title": "<exact item name>",
  "overview": "<3 to 4 sentences of rich, specific context — more expansive than a basic description>",
  "specs": [
    { "label": "<contextually appropriate label>", "value": "<specific accurate value>" },
    { "label": "<contextually appropriate label>", "value": "<specific accurate value>" },
    { "label": "<contextually appropriate label>", "value": "<specific accurate value>" },
    { "label": "<contextually appropriate label>", "value": "<specific accurate value>" },
    { "label": "<contextually appropriate label>", "value": "<specific accurate value>" },
    { "label": "<contextually appropriate label>", "value": "<specific accurate value>" }
  ],
  "highlights": ["<standout fact or feature 1>", "<standout fact or feature 2>", "<standout fact or feature 3>"],
  "pros": ["<genuine strength 1>", "<genuine strength 2>", "<genuine strength 3>"],
  "cons": ["<genuine weakness or limitation 1>", "<genuine weakness or limitation 2>"],
  "bestFor": ["<specific use case or audience 1>", "<specific use case or audience 2>", "<specific use case or audience 3>"]
}

SPEC GENERATION RULES:
- Generate exactly 6 spec entries.
- Choose labels that are most meaningful and specific to what this item actually is.
- Examples by category (adapt freely — these are not exhaustive):
  GPU        → VRAM, TDP, Architecture, Bus Width, Memory BW, Shader Cores
  Language   → Creator, First appeared, Paradigm, Typing, Primary use, Latest stable
  Book       → Author, Published, Pages, Genre, Publisher, Awards
  Actor      → Nationality, Born, Active since, Notable films, Awards, Genre
  Restaurant → Cuisine, Price range, Reservation, Hours, Signature dish, Neighbourhood
  Beach      → Country, Water temp, Wave type, Best season, Nearest airport, Facilities
  Car        → Manufacturer, Engine, 0-100 km/h, Range, Power output, MSRP
- Never use "N/A" as a spec value. If a field is not applicable, pick a different, relevant field.
- Be accurate. Do not invent values you are not confident about.

Be honest about pros and cons. Do not over-praise.
''';

  // ── Internal API caller ────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _callApi({
    required String systemPrompt,
    required String userMessage,
  }) async {
    try {
      final response = await ApiClient.instance.post(
        'chat/completions',
        data: {
          'model': 'gpt-4.1-nano',
          'response_format': {'type': 'json_object'},
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userMessage},
          ],
        },
      );
      final content =
          response.data['choices'][0]['message']['content'] as String;
      return _parseJson(content);
    } on DioException catch (e) {
      _handleDioError(e);
    } on DomainException {
      rethrow;
    } catch (_) {
      throw const ValidationException();
    }
  }

  Map<String, dynamic> _parseJson(String content) {
    try {
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      throw const ValidationException();
    }
  }

  Never _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      throw const TimeoutException();
    }
    final statusCode = e.response?.statusCode;
    if (statusCode == 401 || statusCode == 429) {
      throw const QuotaException();
    }
    throw const ValidationException();
  }

  // ── Public interface ───────────────────────────────────────────────────────

  @override
  Future<RankingModel> getRanking(String query) async {
    final json = await _callApi(
      systemPrompt: _listSystemPrompt,
      userMessage: query,
    );
    final result = RankingDto.parse(json);
    if (result is RankingModel) return result;
    if (result is HumorPayload) {
      throw NonsenseException(
          message: result.message, suggestions: result.suggestions);
    }
    throw const ValidationException();
  }

  @override
  Future<HumorPayload> getHumorFallback(String query) async {
    final json = await _callApi(
      systemPrompt: _listSystemPrompt,
      userMessage: query,
    );
    final result = RankingDto.parse(json);
    if (result is HumorPayload) return result;
    throw const ValidationException();
  }

  /// Trip 2 — enriches a single [item] with deep, contextually appropriate metadata.
  /// The detail prompt adapts its spec fields to whatever the item actually is.
  @override
  Future<RankingItemDetail> getItemDetail(
    RankingItem item,
    String archetype,
  ) async {
    final userMessage = 'Item: ${item.title}\n'
        'Rank: #${item.rank}\n'
        'Category: $archetype\n'
        'Context: ${item.description}';

    final json = await _callApi(
      systemPrompt: _detailSystemPrompt,
      userMessage: userMessage,
    );

    return RankingDto.parseDetail(json);
  }
}
