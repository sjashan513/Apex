/// Architectural role: Domain provider for per-item detail (State 4).
/// Extracted from item_detail_screen.dart where it was incorrectly co-located
/// with presentation code. Providers are domain constructs — they belong here
/// alongside rankingRepositoryProvider and rankingNotifierProvider.
///
/// @throws Exception if the requested item index is out of bounds.
/// @throws DomainException (forwarded from repository) on API failure.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ranking_model.dart';
import 'ranking_providers.dart';
import '../../presentation/notifiers/ranking_notifier.dart';

/// Fetches enriched per-item metadata for the detail screen (Trip 2).
///
/// Keyed by (itemIndex, archetype) so distinct items get distinct cache
/// entries and autoDispose cleans them up when the detail screen is popped.
final itemDetailProvider = FutureProvider.autoDispose
    .family<RankingItemDetail, (int, String)>((ref, params) async {
  final (index, archetype) = params;

  final rankingState = ref.read(rankingNotifierProvider);
  final item = rankingState.maybeWhen(
    data: (state) {
      if (state is! RankingResultState) return null;
      if (index >= state.model.items.length) return null;
      return state.model.items[index];
    },
    orElse: () => null,
  );

  if (item == null) throw Exception('Item not found at index $index');

  final repository = ref.read(rankingRepositoryProvider);
  return repository.getItemDetail(item, archetype);
});
