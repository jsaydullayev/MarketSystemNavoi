/// Create Product Use Case
/// Business logic for creating a product

import 'package:equatable/equatable.dart';
import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

/// Create Product Params
class CreateProductParams extends Equatable {
  final String name;
  final bool isTemporary;
  final double costPrice;
  final double salePrice;
  final double minSalePrice;
  final double quantity;
  final int minThreshold;

  const CreateProductParams({
    required this.name,
    required this.isTemporary,
    required this.costPrice,
    required this.salePrice,
    required this.minSalePrice,
    required this.quantity,
    required this.minThreshold,
  });

  @override
  List<Object?> get props => [
        name,
        isTemporary,
        costPrice,
        salePrice,
        minSalePrice,
        quantity,
        minThreshold,
      ];
}

/// Create Product Use Case
class CreateProductUseCase extends Equatable {
  final ProductRepository repository;

  const CreateProductUseCase(this.repository);

  /// Execute use case
  Future<ResultFuture<ProductEntity?>> call(CreateProductParams params) async {
    return repository.createProduct(
      name: params.name,
      isTemporary: params.isTemporary,
      costPrice: params.costPrice,
      salePrice: params.salePrice,
      minSalePrice: params.minSalePrice,
      quantity: params.quantity,
      minThreshold: params.minThreshold,
    );
  }

  @override
  List<Object?> get props => [repository];
}
