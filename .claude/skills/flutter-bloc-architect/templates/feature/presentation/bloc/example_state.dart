part of 'example_bloc.dart';

/// States emitted by [ExampleBloc].
///
/// Native sealed hierarchy. The default shape is Initial → Loading → Loaded → Error.
/// Add feature-specific variants as needed; keep `extends Equatable`,
/// `@immutable`, `const` constructor, and the `props` list rule.
@immutable
sealed class ExampleState extends Equatable {
  const ExampleState();

  @override
  List<Object?> get props => [];
}

final class ExampleInitial extends ExampleState {
  const ExampleInitial();
}

final class ExampleLoading extends ExampleState {
  const ExampleLoading();
}

final class ExampleLoaded extends ExampleState {
  const ExampleLoaded(this.items);

  final List<ExampleEntity> items;

  ExampleLoaded copyWith({List<ExampleEntity>? items}) =>
      ExampleLoaded(items ?? this.items);

  @override
  List<Object?> get props => [items];
}

final class ExampleError extends ExampleState {
  const ExampleError(this.failure);

  final AppFailure failure;

  @override
  List<Object?> get props => [failure];
}
