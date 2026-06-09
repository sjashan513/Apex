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
import '../../../../core/env/env.dart';
import '../../../../core/exceptions/domain_exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/ranking_model.dart';
import '../dtos/ranking_dto.dart';
import 'ranking_prompts.dart';

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

  // ── Internal API caller ──────────────────────────────────────────────────

  Future<Map<String, dynamic>> _callApi({
    required String systemPrompt,
    required String userMessage,
  }) async {
    try {
      final response = await ApiClient.instance.post(
        'chat/completions',
        data: {
          'model': Env.openAiModel,
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

  // ── Public interface ─────────────────────────────────────────────────────

  @override
  Future<RankingModel> getRanking(String query) async {
    final json = await _callApi(
      systemPrompt: kListSystemPrompt,
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
      systemPrompt: kListSystemPrompt,
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
      systemPrompt: kDetailSystemPrompt,
      userMessage: userMessage,
    );

    return RankingDto.parseDetail(json);
  }
}
