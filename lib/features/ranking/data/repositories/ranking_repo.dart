/// Architectural role: Repository Implementation.
/// The single point of contact between the app and the OpenAI API.
/// Translates raw HTTP responses into domain models.
/// Translates raw HTTP failures into DomainExceptions.
/// Nothing above this layer ever sees a Dio error, a status code, or raw JSON.
library;

import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/exceptions/domain_exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/ranking_model.dart';
import '../dtos/ranking_dto.dart';

/// Abstract interface — defined in the domain layer's contract.
/// The Riverpod provider exposes THIS type, never the implementation.
/// This is what makes the repository mockable in tests without touching production code.
abstract interface class RankingRepository {
  Future<RankingModel> getRanking(String query);
  Future<HumorPayload> getHumorFallback(String query);
}

/// Concrete OpenAI implementation of [RankingRepository].
/// This class is never referenced directly outside of the Riverpod provider declaration.
final class OpenAiRankingRepository implements RankingRepository {
  const OpenAiRankingRepository();

  // ── System prompt ──────────────────────────────────────────────────────────

  static const String _systemPrompt = '''
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
      "vram": "<for TECHNICAL: e.g. 16GB>",
      "tdpWattage": "<for TECHNICAL: e.g. 320W>",
      "price": "<for TECHNICAL: e.g. \$1,199>"
    }
    // ... 10 items total, ranked 1-10
  ]
}
''';

  // ── API call ───────────────────────────────────────────────────────────────

  Future<Object> _callApi(String query) async {
    try {
      final response = await ApiClient.instance.post(
        'chat/completions',
        data: {
          'model': 'gpt-4o-mini',
          'response_format': {'type': 'json_object'},
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            {'role': 'user', 'content': query},
          ],
        },
      );

      final content =
          response.data['choices'][0]['message']['content'] as String;
      final json = _parseJson(content);
      return RankingDto.parse(json);
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
    final result = await _callApi(query);
    if (result is RankingModel) return result;
    throw const ValidationException();
  }

  @override
  Future<HumorPayload> getHumorFallback(String query) async {
    final result = await _callApi(query);
    if (result is HumorPayload) return result;
    throw const ValidationException();
  }
}
