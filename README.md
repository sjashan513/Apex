# Apex — Dynamic Ranking Engine

Apex is a mobile-first Flutter application that converts natural language comparison queries into polished, archetype-specific top-10 visual dashboards. It bypasses conversational chat interfaces entirely, routing unstructured text through a strict classification and rendering pipeline into one of three specialized visual layouts.

---

## Architecture

Feature-first Clean Architecture with unidirectional data flow and immutable state.

```
User Query → Client-side Archetype Detection → OpenAI API (JSON mode)
           → DTO Schema Validation → Domain Model → Polymorphic Visual Dashboard
```

**State management:** Riverpod (`AsyncNotifierProvider.autoDispose`, `Provider`, `StateProvider`). Feature providers are auto-disposed on navigation — no stale state accumulates across sessions. Global scope is restricted to environment config and routing only.

**Navigation:** GoRouter with declarative named routes. Navigation is a domain consequence observed via `ref.listen` — never an imperative side-effect inside a `build` method.

**Network:** A single Dio client with an uncompromising 18-second timeout applied across connect, receive, and send. No request survives beyond this window.

**Widget contract:** Widgets are pure view functions. Zero business logic, zero async operations, zero `ref.read` calls inside `build`.

**Repository pattern:** `RankingRepository` is an abstract interface exposed by the Riverpod provider. `OpenAiRankingRepository` is invisible to all consumers. Swapping the backend requires changing one line in `ranking_providers.dart`.

---

## Presentation Archetypes

The engine classifies every query client-side before the API call, adapting the loading accent color, dashboard chrome, and card metadata schema to the detected content type.

| Archetype | Accent | Visual Priority | Key Fields |
|---|---|---|---|
| `MEDIA` | Purple `#7F77DD` | Cover art, Playfair typography | Creator, Release year, Duration, Rating |
| `GEOGRAPHIC` | Teal `#1D9E75` | Location context, accessibility | Coordinates, Price index, Hours |
| `TECHNICAL` | Amber `#EF9F27` | Performance metrics, spec density | Benchmark score, VRAM, TDP, Price |

Default: any query not matching MEDIA or GEOGRAPHIC keywords resolves to TECHNICAL.

---

## State Machine

Six discrete states. Silent failures are architecturally impossible — every transition has an explicit trigger and an explicit recovery path.

| State | Screen | Trigger In | Trigger Out |
|---|---|---|---|
| 1 — Idle | Home | App launch, reset | Submit query |
| 2 — Executing | Loading | Query submitted | Success / Nonsense / Failure |
| 3 — Dashboard | Ranking list | API success + schema valid | Tap item / Clear |
| 4 — Detail | Item modal | Tap card | Dismiss |
| 5 — Humor Fallback | Rejection UI | Nonsense query detected | Chip tap / Clear |
| 6 — Error | Diagnostic UI | Timeout / Validation / Quota | Retry / Clear |

State 2 is a composite state — it cycles through progressive micro-copy (`Analyzing intent` → `Structuring schema` → `Awaiting inference`) at calibrated intervals to prevent UI hang anxiety during the 7–10 second inference window.

---

## Zero-Degradation Fallbacks

Apex is engineered to produce a coherent UI regardless of LLM payload quality.

**Hybrid Fallback Tile** — Every ranked item carries LLM-generated `primaryColorHex` and `secondaryColorHex` values alongside an optional `imageUrl`. The tile attempts three layers in order: cached network image → LLM `LinearGradient` → hardcoded archetype anchor color. Crossfades at 300ms easeOutCubic. A 404 or malformed URL never produces a broken placeholder.

**Strict DTO validation** — `RankingDto.parse()` runs a structural schema check on every API response. A missing field throws `ValidationException` immediately. Partial domain objects never reach the UI.

**Humor interception** — Off-topic or unrankable queries are caught by the API's own classification logic and returned as a typed humor payload, not an error. The notifier routes this to `AsyncData(HumorState)` — not `AsyncError` — because a witty rejection is a valid outcome, not a failure.

**18-second guillotine** — Client-side timeout enforced at the Dio layer. If the OpenAI socket does not resolve within 18 seconds, the connection aborts and `TimeoutException` propagates to the error UI with a contextual diagnostic message.

---

## Design System

Dark-first zinc palette. Two font weights. Three archetype accents. Particles on shell screens only.

**Canvas:** `#09090B` · **Surface:** `#18181B` · **Raised:** `#27272A` · **Border:** `#3F3F46`

**Typography:** Inter 400/500 across all UI. Playfair Display 400 for MEDIA archetype card titles only, bundled as a local asset.

**Motion:** 150ms fast / 250ms standard / 400ms slow. `easeOutCubic` entry, `easeInCubic` exit. 40ms stagger per ranking card.

**Particle canvas:** 52 nodes, bounce physics, connection lines at max 0.10 opacity. Renders on States 1, 2, 5, 6. Never on States 3 or 4.

---

## Project Structure

```
lib/
├── core/
│   ├── env/
│   │   └── env.dart                       — .env loader, openAiKey + openAiModel getters
│   ├── network/
│   │   └── api_client.dart                — Dio singleton, 18-second timeout
│   ├── exceptions/
│   │   └── domain_exceptions.dart         — Sealed: Timeout · Validation · Quota · Nonsense
│   └── routing/
│       └── app_router.dart                — GoRouter, 3 named routes
│
├── design_system/
│   ├── theme/
│   │   ├── app_colors.dart
│   │   └── app_typography.dart
│   └── components/
│       ├── particle_canvas.dart
│       ├── hybrid_fallback_tile.dart
│       ├── micro_state_text.dart
│       ├── shell_logo_mark.dart
│       ├── eyebrow_divider.dart
│       ├── section_label.dart
│       ├── search_input.dart
│       └── suggestion_chip.dart
│
└── features/
    └── ranking/
        ├── data/
        │   ├── dtos/
        │   │   └── ranking_dto.dart        — JSON → domain model parser + schema validator
        │   └── repositories/
        │       ├── ranking_repo.dart        — RankingRepository interface + OpenAI implementation
        │       └── ranking_prompts.dart     — kListSystemPrompt · kDetailSystemPrompt (read-only)
        │
        ├── domain/
        │   ├── models/
        │   │   └── ranking_model.dart      — Sealed: MediaRanking · GeographicRanking · TechnicalRanking
        │   └── providers/
        │       ├── ranking_providers.dart  — repositoryProvider · notifierProvider · archetypeProvider
        │       └── item_detail_provider.dart — FutureProvider.autoDispose.family for Trip 2
        │
        └── presentation/
            ├── notifiers/
            │   └── ranking_notifier.dart   — AutoDisposeAsyncNotifier, full state machine
            └── views/
                ├── screens/
                │   ├── home_screen.dart         — State 1 coordinator
                │   ├── ranking_dashboard.dart   — State 3 coordinator
                │   └── item_detail_screen.dart  — State 4 coordinator
                └── widgets/
                    ├── idle_view.dart
                    ├── loading_view.dart
                    ├── humor_fallback_view.dart
                    ├── error_fallback_view.dart
                    ├── animated_card.dart
                    ├── technical_layout_card.dart
                    ├── media_layout_card.dart
                    ├── geographic_layout_card.dart
                    └── detail/
                        ├── detail_hero_banner.dart
                        ├── detail_title_row.dart
                        ├── detail_content.dart
                        └── detail_loading_error.dart
```

---

## Setup

```bash
# 1. Clone and install
flutter pub get

# 2. Create .env in project root
OPENAI_API_KEY=sk-your-key-here
OPENAI_MODEL=gpt-4.1-nano

# 3. Run on device
flutter run

# 4. Run on Chrome for UI iteration
flutter run -d chrome
```

The model string is read at runtime from `.env` via `Env.openAiModel`. Swapping models requires no Dart changes.

---

## Key Architectural Decisions

**Why `sealed` classes everywhere** — Exhaustive `switch` at compile time. Adding a new archetype without handling every switch site is a compiler error, not a runtime bug discovered in production.

**Why `autoDispose` on all feature providers** — The notifier is created when the feature is entered and garbage-collected when the user navigates away. Without `autoDispose`, stale ranking state from a previous session leaks into the next.

**Why `NonsenseException` routes to `AsyncData` not `AsyncError`** — A humor response is a valid, intentional API outcome. Routing it to `AsyncError` would render the error UI for a non-error. `AsyncData(HumorState(...))` keeps the state machine semantically correct.

**Why `CustomPainter` + `Ticker` for particles** — `setState` at 60fps rebuilds the entire widget tree 60 times per second. `CustomPainter` with a `Ticker` repaints only the canvas layer, bypassing the widget tree entirely. `RepaintBoundary` isolates it from the rest of the screen.

**Why `ref.listen` for navigation** — Navigation is a side effect. Side effects never go inside `build`. `ref.listen` fires outside the build cycle when state changes, keeping `build` a pure function.

**Why prompts live in `ranking_prompts.dart`** — The system prompts are the API contract. Isolating them as read-only constants means they can be reviewed, diffed, and iterated without touching repository logic.