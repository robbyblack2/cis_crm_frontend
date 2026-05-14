part of 'example_bloc.dart';

@immutable
sealed class ExampleEvent extends Equatable {
  const ExampleEvent();

  @override
  List<Object?> get props => [];
}

final class ExampleLoadRequested extends ExampleEvent {
  const ExampleLoadRequested();
}

final class ExampleCleared extends ExampleEvent {
  const ExampleCleared();
}
