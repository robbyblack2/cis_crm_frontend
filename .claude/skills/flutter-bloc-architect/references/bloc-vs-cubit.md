# Bloc vs Cubit

Both are state management primitives from `flutter_bloc`. Same `BlocProvider`, `BlocBuilder`, `BlocListener` API on the consumer side. Different on the producer side.

## Cubit

```dart
class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);
  void increment() => emit(state + 1);
  void decrement() => emit(state - 1);
}
```

- Method calls in, states out.
- No event log.
- No `EventTransformer` — no built-in debounce / throttle / droppable / restartable.
- Less ceremony — fewer files.

## Bloc

```dart
class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0) {
    on<CounterIncremented>((e, emit) => emit(state + 1), transformer: droppable());
    on<CounterDecremented>((e, emit) => emit(state - 1), transformer: droppable());
  }
}
```

- Events in, states out.
- Full event log → reproducible test history.
- `EventTransformer` per handler — debounce, throttle, drop, restart, sequentialize.

## Decision rule (capability-based)

The **official** rule from [bloclibrary.dev/bloc-concepts](https://bloclibrary.dev/bloc-concepts/) is capability-based, not screen-complexity-based:

> Use **Cubit** for simple, straightforward state changes. Use **Bloc** when you need an `EventTransformer` (debounce, throttle, restart) or want the auditable event log.

### Apply that rule

**Default to `Cubit`.** Upgrade to `Bloc` only when one of these is genuinely true:

- A handler needs `restartable()` — typically search-as-you-type ("cancel the previous request when a new one starts").
- A handler needs `droppable()` — typically a submit button ("don't queue duplicate submits").
- A handler needs `sequential()` — typically file uploads ("process these in order").
- The user-input flow is concurrent and you want explicit `concurrent()` for documentation.
- You want the auditable event log for debugging.

Screen complexity ("multi-action") is *not* the criterion. The official `flutter_login` example uses `Bloc` with no transformers at all — the choice was made for the event-log/debug ergonomics. So "multi-action screen" only matters insofar as it implies you'll want one of the transformer or event-log capabilities above.

### Forms

Forms follow the same capability rule:

- **Cubit by default** — login, signup, settings edit, profile. Method calls (`emailChanged(value)`, `submitted()`) are sufficient.
- **Promote to Bloc** only when a field needs **debounced async validation** (e.g., username availability check) or **debounced auto-save** of in-progress drafts — i.e., you'll declare `restartable()` on a field-changed event.
- State class is single-class with `FormzSubmissionStatus` (the documented exemption from the sealed-hierarchy rule — see `references/state-design.md`).

bloclibrary.dev does not publish forms-specific guidance — this rule is a project-local extension of the capability rule.

## bloc_concurrency transformers

```dart
import 'package:bloc_concurrency/bloc_concurrency.dart';

on<SearchQueryChanged>(_onQueryChanged, transformer: restartable());
on<LoginSubmitted>(_onSubmit, transformer: droppable());
on<UploadRequested>(_onUpload, transformer: sequential());
on<NotificationReceived>(_onReceived, transformer: concurrent());
```

Default (no transformer specified) is `concurrent` — handlers run in parallel.

### Project rule: declare a transformer on every user-input handler — stricter than official

The official position is that transformers are an opt-in feature; the `flutter_login` example declares no transformers at all. **This skill mandates an explicit transformer on every user-input handler** (the `bloc-verifier` agent flags handlers without one). The reason: hidden concurrency bugs (rapid taps double-submitting, search-as-you-type races) are easier to prevent than diagnose. Treat the rule as "make concurrency intent explicit at the call site," not "the BLoC team requires this." The four transformers' descriptions below match the [`bloc_concurrency` package](https://pub.dev/packages/bloc_concurrency) docs.

Transformer choice cheat-sheet:
- **`restartable()`** — cancel the previous handler when a new event arrives. Search-as-you-type.
- **`droppable()`** — drop new events while a previous handler is still running. Submit buttons.
- **`sequential()`** — queue events in order; one runs at a time. File uploads.
- **`concurrent()`** — run handlers in parallel. Independent events (notifications, telemetry).

## Naming

Per [bloclibrary.dev/naming-conventions](https://bloclibrary.dev/naming-conventions/), event names use **domain-language past tense**, not UI-action verbs:

- ✓ `LoginSubmitted`, `CartItemAdded`, `FeedRefreshed`, `NotificationReceived`
- ✗ `SubmitPressed`, `AddCartButtonTapped`, `RefreshClicked`

Event names describe what *happened* in the domain, not which widget was touched. The widget tree is an implementation detail; the event log should read like a business narrative.

## HydratedCubit / HydratedBloc

For state that must survive app restart, use `HydratedCubit` or `HydratedBloc` (whichever fits the rules above) instead of plain `Cubit`/`Bloc`. Same logic + a `toJson`/`fromJson` pair. See `references/hydrated-bloc.md`.
