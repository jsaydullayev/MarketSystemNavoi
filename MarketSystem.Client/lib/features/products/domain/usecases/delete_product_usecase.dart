/// Product States
/// States for Product Bloc
library;

import 'package:equatable/equatable.dart';

import '../../../../core/failure/failures.dart';
import '../../entities/product_entity.dart';

/// Product State Base
abstract class ProductState extends Equatable {
  const ProductState();
}

/// Initial state
class ProductInitial extends ProductState {
  const ProductInitial();

  @override
  List<Object?> get props => [];
}

/// Loading state
class ProductLoading extends ProductState {
  const ProductLoading();

  @override
  List<Object?> get props => [];
}

/// Loaded state
class ProductLoaded extends ProductState {
  final List<ProductEntity> products;

  const ProductLoaded({required this.products});

  @override
  List<Object?> get props => [products];
}

/// Error state
class ProductError extends ProductState {
  final String message;

  const ProductError({required this.message});

  @override
  List<Object?> get props => [message];
}
