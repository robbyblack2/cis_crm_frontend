part of 'example_bloc.dart';

/// Events accepted by [ExampleBloc].
///
/// Native sealed hierarchy + Equatable. Add new events as new `final class`
/// subtypes here; the bloc's `on<...>` handlers must be exhaustive.
@immutable
sealed class ExampleEvent extends Equatable {
  const ExampleEvent();

  @override
  List<Object?> get props => [];
}

/// Initial load.
final class ExampleLoadRequested extends ExampleEvent {
  const ExampleLoadRequested();
}

/// User pulled to refresh.
final class ExampleRefreshRequested extends ExampleEvent {
  const ExampleRefreshRequested();
}

/// User created a new example.
final class ExampleCreateRequested extends ExampleEvent {
  const ExampleCreateRequested(this.entity);

  final ExampleEntity entity;

  @override
  List<Object?> get props => [entity];
}

/// User deleted an example.
final class ExampleDeleteRequested extends ExampleEvent {
  const ExampleDeleteRequested(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
