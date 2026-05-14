# State Design

How to design the state hierarchy for a feature. Load when defining or refactoring states.

The five rules below distill [bloclibrary.dev/modeling-state](https://bloclibrary.dev/modeling-state/) — "annotate the class with `@immutable` from package:meta, implement a `copyWith` method, and use the `const` keyword for constructors" — and add the sealed-hierarchy preference also endorsed there ("a sealed class that holds any shared properties and multiple subclasses for the separate states... Type Safe... Exhaustive").

## The five rules (recap)

Every state class:
1. `extends Equatable`.
2. Annotated `@immutable`.
3. Part of a `sealed` hierarchy.
4. All constructors are `const`.
5. `copyWith` hand-written; use the sentinel pattern for nullable fields that need "set to null" support.

### The single documented exemption: formz form states

A state class that contains a `FormzSubmissionStatus` field is **single-class, not sealed**. Reason: `FormzSubmissionStatus` is itself a state machine (`initial / inProgress / success / failure / canceled`). Wrapping it in a second sealed hierarchy duplicates information and forces awkward mapping. The bloc-verifier agent skips rule 3 for these classes; rules 1, 2, 4, 5 still apply.

```dart
final class LoginState extends Equatable {
  const LoginState({
    this.email = const EmailInput.pure(),
    this.password = const PasswordInput.pure(),
    this.status = FormzSubmissionStatus.initial,
    this.errorMessage,
  });
  final EmailInput email;
  final PasswordInput password;
  final FormzSubmissionStatus status;
  final String? errorMessage;
  bool get isValid => Formz.validate([email, password]);
  // hand-written copyWith
  @override List<Object?> get props => [email, password, status, errorMessage];
}
```

## Default shape

```dart
@immutable
sealed class FeatureState extends Equatable {
  const FeatureState();
  @override
  List<Object?> get props => [];
}

final class FeatureInitial extends FeatureState { const FeatureInitial(); }
final class FeatureLoading extends FeatureState { const FeatureLoading(); }
final class FeatureLoaded extends FeatureState {
  const FeatureLoaded(this.data);
  final SomeType data;
  @override List<Object?> get props => [data];
}
final class FeatureError extends FeatureState {
  const FeatureError(this.failure);
  final AppFailure failure;
  @override List<Object?> get props => [failure];
}
```

## Why sealed unions instead of one class with flags

Tempting:
```dart
class FeatureState {
  final bool isLoading;
  final SomeType? data;
  final AppFailure? error;
}
```

This is a god-state class. It allows nonsense combinations (`isLoading: true, error: someFailure, data: someData`) the compiler can't prevent. You'll forget to clear `error` when starting a new load. You'll forget to clear `data` on logout.

Sealed unions make impossible states unrepresentable. `FeatureLoading` has no `data` field. The compiler refuses to accidentally hold both.

## When to add more variants

Add variants when the screen has genuinely different visual modes. Examples:

- **Search:** `Idle | Loading | Results(items) | NoMatches | Error`. `NoMatches` is distinct from `Loaded(items: [])` — it lets the UI show "no results for 'foo'" rather than the regular empty state.
- **Auth:** `Initial | CheckingSession | Authenticated(user) | Unauthenticated | Error`. Five states because there's a meaningful "we don't yet know" period at app start.
- **File upload:** `Idle | Uploading(progress) | Succeeded(uploadId) | Failed(failure)`. Progress is a field on `Uploading`, not a flag on a flat class.

Don't add variants for distinctions the UI doesn't render. If the screen looks identical for two scenarios, they're the same state.

## When to nest collections inside `Loaded`

For lists, the canonical shape is:

```dart
final class FeatureLoaded extends FeatureState {
  const FeatureLoaded(this.items);
  final List<Entity> items;
  @override List<Object?> get props => [items];
}
```

Equatable's `DeepCollectionEquality` handles list equality. Always reconstruct the list when contents change — never mutate in place:

```dart
emit(state.copyWith(items: [...state.items, newItem]));   // ✓
state.items.add(newItem);                                 // ✗ silent bug
```

For lookup-by-id-heavy screens (e.g., editing a single item in a long list), use `Map<String, Entity>` keyed by id instead — `state.items[id] = updated` is O(1), and constructing a new map with `{...state.items, id: updated}` preserves immutability.

## copyWith sentinel pattern

Default `copyWith` cannot distinguish "did not pass" from "passed null":

```dart
// BROKEN — caller can't set description to null
FeatureLoaded copyWith({String? description}) =>
    FeatureLoaded(description ?? this.description);
```

Sentinel pattern fixes it:

```dart
const _sentinel = Object();

FeatureLoaded copyWith({Object? description = _sentinel}) {
  return FeatureLoaded(
    description: identical(description, _sentinel)
        ? this.description
        : description as String?,
  );
}
```

Now `state.copyWith()` keeps the old description; `state.copyWith(description: null)` sets it to null. Use the sentinel **only on nullable fields where "set to null" is a real operation** — for non-nullable fields the simple `?? this.field` pattern is fine.

## Paginated state shape

For paginated lists (endless scroll), use a sealed hierarchy with a shared base carrying `items / hasMore / cursor`. `LoadingMore` and `Error` keep the items already loaded so the UI doesn't blank out.

> **Stricter than the official `flutter_infinite_list` example.** That example uses a flatter shape — `PostInitial | PostSuccess | PostFailure` plus a `hasReachedMax` boolean on `PostSuccess`, with `copyWith` retaining `posts` across states. This skill splits `LoadingMore` into its own variant so the UI can distinguish "fetching more" from "done loading" without inspecting which event was last dispatched. Deliberate elaboration, not a contradiction.

```dart
sealed class FeedState extends Equatable {
  const FeedState({this.items = const [], this.hasMore = true, this.cursor});
  final List<Item> items;
  final bool hasMore;
  final String? cursor;
  @override List<Object?> get props => [items, hasMore, cursor];
}

final class FeedInitial extends FeedState { const FeedInitial(); }
final class FeedLoading extends FeedState { const FeedLoading(); }   // first page
final class FeedLoaded extends FeedState {
  const FeedLoaded({required super.items, required super.hasMore, super.cursor});
}
final class FeedLoadingMore extends FeedState {
  const FeedLoadingMore({required super.items, required super.hasMore, super.cursor});
}
final class FeedError extends FeedState {
  const FeedError({
    required super.items,
    required super.hasMore,
    super.cursor,
    required this.failure,
  });
  final AppFailure failure;
  @override List<Object?> get props => [...super.props, failure];
}
```

Repos return `Future<Result<Page<T>, AppFailure>>` (the generic `Page<T>` lives at `lib/core/pagination/page.dart`). The handler for `LoadMoreRequested` uses `droppable()`; the handler for `FeedRefreshed` uses `restartable()`. The `PaginatedSliver<T>` widget at `lib/core/widgets/paginated_sliver.dart` auto-fires `onLoadMore` near the scroll bottom and renders the retry-tile footer when state is `FeedError`.

## State equality and bloc emission

`Bloc.emit` skips emitting if `next == current`. Equatable's `==` walks the `props` list. Adding a field means updating `props` — otherwise new field changes are silently ignored.

The `bloc-verifier` agent checks for fields that exist but aren't in `props`. Run it before declaring a state-class change done.
