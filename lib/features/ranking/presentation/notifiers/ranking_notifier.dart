/// Architectural role: AsyncNotifier.
/// Owns the complete ranking session lifecycle.
/// The single entry point from the presentation layer into the domain.
/// Widgets call methods here — they never touch the repository directly.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/exceptions/domain_exceptions.dart';
import '../../domain/models/ranking_model.dart';
import '../../domain/providers/ranking_providers.dart';

// ── Domain state ───────────────────────────────────────────────────────────

/// Represents every possible successful outcome of the ranking session.
/// AsyncLoading and AsyncError are handled by AsyncValue — not modelled here.
sealed class RankingState {
  const RankingState();
}

/// The initial state. No query has been submitted.
final class IdleState extends RankingState {
  const IdleState();
}

/// A valid ranking query succeeded. Holds the full ranking model.
final class RankingResultState extends RankingState {
  const RankingResultState({required this.model});
  final RankingModel model;
}

/// The query was nonsense or off-topic. Holds the humor payload.
final class HumorState extends RankingState {
  const HumorState({required this.payload});
  final HumorPayload payload;
}

// ── Archetype detection ────────────────────────────────────────────────────

/// Client-side keyword classifier.
/// Fires before the API call to drive the loading screen accent color.
/// Returns 'TECHNICAL' as the default per Design Contract §01.
String _detectArchetype(String query) {
  final lower = query.toLowerCase();

  const mediaKeywords = [
    'book',
    'film',
    'game',
    'movie',
    'album',
    'series',
    'song',
    'show',
    'anime',
    'podcast',
  ];
  const geographicKeywords = [
    'cafe',
    'hotel',
    'city',
    'restaurant',
    'travel',
    'place',
    'bar',
    'beach',
    'country',
    'town',
  ];

  if (mediaKeywords.any((k) => lower.contains(k))) return 'MEDIA';
  if (geographicKeywords.any((k) => lower.contains(k))) return 'GEOGRAPHIC';
  return 'TECHNICAL';
}

class RankingNotifier extends AutoDisposeAsyncNotifier<RankingState> {
  /// Called once when the notifier is first created.
  /// Returns the initial idle state — no API call happens here.
  @override
  Future<RankingState> build() async {
    return const IdleState();
  }

  /// Primary entry point. Called by the UI when the user submits a query.
  /// Drives the full state machine from idle → loading → result/humor/error.
  Future<void> submitQuery(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final archetype = _detectArchetype(trimmed);
    ref.read(detectedArchetypeProvider.notifier).state = archetype;

    state = const AsyncLoading();

    try {
      final repository = ref.read(rankingRepositoryProvider);
      final result = await repository.getRanking(trimmed);
      state = AsyncData(RankingResultState(model: result));
    } on NonsenseException catch (e) {
      final payload = HumorPayload(
        message: e.message,
        suggestions: e.suggestions,
      );
      state = AsyncData(HumorState(payload: payload));
    } on DomainException catch (e, st) {
      state = AsyncError(e, st);
    } catch (e, st) {
      state = AsyncError(
        const ValidationException(),
        st,
      );
    }
  }

  /// Resets the session back to idle. Called when the user clears the query.
  void reset() {
    ref.read(detectedArchetypeProvider.notifier).state = 'TECHNICAL';
    state = const AsyncData(IdleState());
  }

  /// Retries the last query. Called from the error state retry button.
  Future<void> retry(String query) async {
    await submitQuery(query);
  }
}
