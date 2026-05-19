import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/products/domain/entities/product.dart';
import 'package:cis_crm/features/products/domain/repositories/product_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'products_event.dart';
part 'products_state.dart';

class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  ProductsBloc({required ProductRepository repository})
      : _repository = repository,
        super(const ProductsInitial()) {
    on<ProductsLoadRequested>(
      _onLoadRequested,
      transformer: restartable(),
    );
    on<ProductCreateRequested>(
      _onCreateRequested,
      transformer: droppable(),
    );
    on<ProductDeleteRequested>(
      _onDeleteRequested,
      transformer: droppable(),
    );
  }

  final ProductRepository _repository;

  Future<void> _onLoadRequested(
    ProductsLoadRequested event,
    Emitter<ProductsState> emit,
  ) async {
    emit(const ProductsLoading());
    final result = await _repository.getProducts();
    switch (result) {
      case Success(data: final products):
        emit(ProductsLoaded(products: products));
      case Failure(error: final failure):
        emit(ProductsError(message: failure.message));
    }
  }

  Future<void> _onCreateRequested(
    ProductCreateRequested event,
    Emitter<ProductsState> emit,
  ) async {
    emit(const ProductsLoading());
    final result = await _repository.createProduct(
      name: event.name,
      type: event.type,
      currency: event.currency,
      defaultPrice: event.defaultPrice,
      tags: event.tags,
    );
    switch (result) {
      case Success():
        add(const ProductsLoadRequested());
      case Failure(error: final failure):
        emit(ProductsError(message: failure.message));
    }
  }

  Future<void> _onDeleteRequested(
    ProductDeleteRequested event,
    Emitter<ProductsState> emit,
  ) async {
    emit(const ProductsLoading());
    final result = await _repository.deleteProduct(id: event.id);
    switch (result) {
      case Success():
        add(const ProductsLoadRequested());
      case Failure(error: final failure):
        emit(ProductsError(message: failure.message));
    }
  }
}
