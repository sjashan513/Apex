/// Architectural role: Dependency Injection Graph.
/// Declares all Riverpod providers for the ranking feature.
/// This is the only file that knows which concrete implementation
/// backs the RankingRepository interface.
/// Every consumer references the abstract interface type — never the implementation.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/ranking_repo.dart';
import '../../presentation/notifiers/ranking_notifier.dart';

// ── Repository provider ────────────────────────────────────────────────────

/// Provides the single shared instance of [RankingRepository].
/// Exposes the abstract interface — the [OpenAiRankingRepository] implementation
/// is invisible to all consumers. Swap implementations here without touching
/// any other file.
final rankingRepositoryProvider = Provider<RankingRepository>((ref) {
  return const OpenAiRankingRepository();
});

// ── Notifier provider ──────────────────────────────────────────────────────

/// Provides the [RankingNotifier] and exposes its state as [AsyncValue<RankingState>].
/// autoDispose: true — the notifier is created when the ranking feature is
/// entered and disposed when the user navigates away. No memory leak.
final rankingNotifierProvider =
    AsyncNotifierProvider.autoDispose<RankingNotifier, RankingState>(
  RankingNotifier.new,
);

// ── Archetype detection provider ───────────────────────────────────────────

/// Holds the client-side detected archetype string for the current query.
/// Fires before the API call — drives the loading screen accent color.
/// Defaults to 'TECHNICAL' per the Design Contract.
final detectedArchetypeProvider = StateProvider.autoDispose<String>((ref) {
  return 'TECHNICAL';
});
