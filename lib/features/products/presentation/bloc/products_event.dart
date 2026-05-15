part of 'products_bloc.dart';

@immutable
sealed class ProductsEvent extends Equatable {
  const ProductsEvent();

  @override
  List<Object?> get props => [];
}

final class ProductsLoadRequested extends ProductsEvent {
  const ProductsLoadRequested();
}

final class ProductCreateRequested extends ProductsEvent {
  const ProductCreateRequested({
    required this.name,
    required this.type,
    required this.currency,
    this.defaultPrice,
    this.tags = const [],
  });

  final String name;
  final String type;
  final String currency;
  final double? defaultPrice;
  final List<String> tags;

  @override
  List<Object?> get props => [name, type, currency, defaultPrice, tags];
}
