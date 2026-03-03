/// Update Product Use Case
/// Business logic for updating a product

import 'package:equatable/equatable.dart';

import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

/// Update Product Params
class UpdateProductParams extends Equatable {
  final String id;
  final String name;
  final bool isTemporary;
  final double costPrice;
  final double salePrice;
  final double minSalePrice;
  final double quantity;
  final int minThreshold;

  const UpdateProductParams({
    required this.id,
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
        id,
        name,
        isTemporary,
        costPrice,
        salePrice,
        minSalePrice,
        quantity,
        minThreshold,
      ];
}

/// Update Product Use Case
class UpdateProductUseCase extends Equatable {
  final ProductRepository repository;

  const UpdateProductUseCase(this.repository);

  /// Execute use case
  Future<ProductEntity?> call(UpdateProductParams params) async {
    return repository.updateProduct(
      id: params.id,
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
