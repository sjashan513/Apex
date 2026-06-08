/// Architectural role: Repository Implementation.
/// The single point of contact between the app and the OpenAI API.
/// Translates raw HTTP responses into domain models.
/// Translates raw HTTP failures into DomainExceptions.
/// Nothing above this layer ever sees a Dio error, a status code, or raw JSON.
///
/// Trip 1 — getRanking(): slim 10-item list payload (~900 tokens, 7–10s)
/// Trip 2 — getItemDetail(): unified enriched payload (~300 tokens, 2–4s)
///           One prompt handles all archetypes — specs array adapts to query context.
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

  static const String _listSystemPrompt = '''
You are a ranking engine. Your only job is to return a valid JSON object.

RULES:
1. If the query is a valid ranking request, return a ranking JSON object.
2. If the query is nonsense, off-topic, or cannot produce a meaningful top-10 list, return a humor JSON object.
3. Never return anything except a raw JSON object. No markdown. No explanation. No code fences.

VALID RANKING RESPONSE FORMAT:
{
  "type": "MEDIA" | "GEOGRAPHIC" | "TECHNICAL",
  "query": "<original query>",
  "title": "<descriptive list title>",
  "items": [
    {
      "rank": 1,
      "title": "<item name>",
      "description": "<2 sentence description>",
      "primaryColorHex": "<hex color reflecting item aesthetic>",
      "secondaryColorHex": "<hex color reflecting item aesthetic>",
      "iconIdentifier": "<one of: book, map-pin, cpu>",
      "imageUrl": null,
      "creator": "<for MEDIA: author/director/studio>",
      "releaseYear": <for MEDIA: integer year>,
      "duration": "<for MEDIA: e.g. 312 pages, 2h 17m>",
      "rating": <for MEDIA: float 0.0-10.0>,
      "latitude": <for GEOGRAPHIC: float>,
      "longitude": <for GEOGRAPHIC: float>,
      "priceIndex": "<for GEOGRAPHIC: € | €€ | €€€ | €€€€>",
      "accessibility": "<for GEOGRAPHIC: opening hours or access notes>",
      "performanceScore": <for TECHNICAL: float 0.0-100.0>,
      "vram": "<for TECHNICAL: e.g. 16GB GDDR6 — use N/A if not applicable>",
      "tdpWattage": "<for TECHNICAL: e.g. 320W — use N/A if not applicable>",
      "price": "<for TECHNICAL: e.g. \$1,199 or Free>"
    }
  ]
}

HUMOR RESPONSE FORMAT (use when query is nonsense or off-topic):
{
  "type": "humor",
  "message": "<witty one-liner explaining why this cannot be ranked>",
  "suggestions": ["<valid query 1>", "<valid query 2>", "<valid query 3>", "<valid query 4>"]
}

TYPE CLASSIFICATION:
- MEDIA: books, films, games, albums, shows, anime, podcasts, composers, artists
- GEOGRAPHIC: places, cities, cafes, restaurants, hotels, beaches, trails, countries
- TECHNICAL: everything else — hardware, software, languages, frameworks, cars, tools
''';

  // ── Trip 2: Unified detail system prompt ───────────────────────────────────
  //
  // The key insight: rather than three archetype-specific prompts with hardcoded
  // field names, one prompt instructs the model to generate contextually appropriate
  // specs for whatever the item actually is.
  //
  // A GPU gets: VRAM, TDP, Architecture, Bus Width.
  // Python gets: Paradigm, Typing discipline, First appeared, Creator.
  // A beach gets: Water temp, Wave conditions, Nearest airport, Best season.
  // A restaurant gets: Cuisine, Signature dish, Reservation policy, Dress code.
  //
  // The Flutter layer renders a generic spec grid from the array.
  // No field names are hardcoded anywhere in the codebase.

  static const String _detailSystemPrompt = '''
You are a detail analyst. Given an item name and its context, return a rich JSON object with deep information.
Never return anything except a raw JSON object. No markdown. No explanation. No code fences.

RESPONSE FORMAT:
{
  "title": "<exact item name>",
  "overview": "<3 to 4 sentences of rich, specific context — more expansive than a basic description>",
  "specs": [
    { "label": "<contextually appropriate label>", "value": "<specific value>" },
    { "label": "<contextually appropriate label>", "value": "<specific value>" },
    { "label": "<contextually appropriate label>", "value": "<specific value>" },
    { "label": "<contextually appropriate label>", "value": "<specific value>" },
    { "label": "<contextually appropriate label>", "value": "<specific value>" },
    { "label": "<contextually appropriate label>", "value": "<specific value>" }
  ],
  "highlights": ["<standout fact or feature 1>", "<standout fact or feature 2>", "<standout fact or feature 3>"],
  "pros": ["<genuine strength 1>", "<genuine strength 2>", "<genuine strength 3>"],
  "cons": ["<genuine weakness or limitation 1>", "<genuine weakness or limitation 2>"],
  "bestFor": ["<specific use case or audience 1>", "<specific use case or audience 2>", "<specific use case or audience 3>"]
}

SPEC GENERATION RULES:
- Generate exactly 6 spec entries.
- Choose labels that are most meaningful and specific to what this item actually is.
- Examples by category (do not limit yourself to these):
  GPU → VRAM, TDP, Architecture, Bus Width, Memory BW, Shader Cores
  Programming language → Creator, First appeared, Paradigm, Typing, Primary use, Latest version
  Book → Author, Published, Pages, Genre, Publisher, Language
  Restaurant → Cuisine, Price range, Reservation, Hours, Signature dish, Neighbourhood
  Beach → Country, Water temp, Wave type, Best season, Nearest airport, Facilities
  Car → Manufacturer, Engine, 0-100 km/h, Range/tank, Power, MSRP
- Be accurate. Be specific. Never use "N/A" as a spec value — if a field doesn't apply, pick a different field.

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
  /// A GPU gets hardware specs. Python gets language specs. A café gets venue specs.
  /// Expected response time: 2–4 seconds. Expected token cost: ~300 tokens.
  @override
  Future<RankingItemDetail> getItemDetail(
    RankingItem item,
    String archetype,
  ) async {
    // Pass title, rank, and the original query context so the model
    // knows exactly what kind of item it's enriching.
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
