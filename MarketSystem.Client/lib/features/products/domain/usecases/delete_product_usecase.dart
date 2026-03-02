/// Delete Product Use Case
/// Business logic for deleting a product

import 'package:equatable/equatable.dart';
import '../repositories/product_repository.dart';

/// Delete Product Use Case
class DeleteProductUseCase extends Equatable {
  final ProductRepository repository;

  const DeleteProductUseCase(this.repository);

  /// Execute use case
  ResultFuture<bool> call(String id) async {
    return repository.deleteProduct(id);
  }

  @override
  List<Object?> get props => [repository];
}
