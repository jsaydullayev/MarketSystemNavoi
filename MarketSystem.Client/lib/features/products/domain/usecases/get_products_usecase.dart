/// Get Products Use Case
/// Business logic for getting all products

import 'package:equatable/equatable.dart';

import '../../../../core/failure/failures.dart';
import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

/// Get Products Use Case
class GetProductsUseCase extends Equatable {
  final ProductRepository repository;

  const GetProductsUseCase(this.repository);

  /// Execute use case
  ResultFuture<List<ProductEntity>> call() async {
    return repository.getAllProducts();
  }

  @override
  List<Object?> get props => [repository];
}
