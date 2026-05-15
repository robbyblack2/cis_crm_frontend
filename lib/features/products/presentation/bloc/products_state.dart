part of 'products_bloc.dart';

@immutable
sealed class ProductsState extends Equatable {
  const ProductsState();

  @override
  List<Object?> get props => [];
}

final class ProductsInitial extends ProductsState {
  const ProductsInitial();
}

final class ProductsLoading extends ProductsState {
  const ProductsLoading();
}

final class ProductsLoaded extends ProductsState {
  const ProductsLoaded({required this.products});

  final List<Product> products;

  @override
  List<Object?> get props => [products];
}

final class ProductsError extends ProductsState {
  const ProductsError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
