/// Get Products Use Case
/// Business logic for getting all products
library;

import 'package:equatable/equatable.dart';

import '../../../../core/failure/failures.dart';
import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

/// Get Products Use Case
class GetProductsUseCase extends Equatable {
  final ProductRepository repository;

  const GetProductsUseCase(this.repository);

  /// Execute use case
  Future<ResultFuture<List<ProductEntity>>> call() async {
    // Could add caching logic here later
    return repository.getAllProducts();
  }
}

/// Create Product Use Case
/// Business logic for creating a product
library;

import 'package:equatable/equatable.dart';

import '../../../../core/failure/failures.dart';
import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

/// Create Product Params
class CreateProductParams extends Equatable {
  final String name;
  final bool isTemporary;
  final double costPrice;
  final double salePrice;
  final double minSalePrice;
  final int quantity;
  final int minThreshold;

  const CreateProductParams({
    required this.name,
    required this.isTemporary,
    required this.costPrice,
    required this.salePrice,
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

/// Create Product Use Case class
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
      quantity: params.quantity,
      minThreshold: params.minThreshold,
    );
  }
}

/// Update Product Use Case
/// Business logic for updating a product
library;

import 'package:equatable/equatable.dart';

import '../../../../core/failure/failures.dart';
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
  final int quantity;
  final int minThreshold;

  const UpdateProductParams({
    required this.id,
    required this.name,
    required this.isTemporary,
    required this.costPrice,
    required this.salePrice,
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
        salePrice,
        quantity,
        minThreshold,
      ];
}

/// Update Product Use Case class
class UpdateProductUseCase extends Equatable {
  final ProductRepository repository;

  const UpdateProductUseCase(this.repository);

  /// Execute use case
  Future<ResultFuture<ProductEntity?>> call(UpdateProductParams params) async {
    return repository.updateProduct(
      id: params.id,
      name: params.name,
      isTemporary: params.isTemporary,
      costPrice: params.costPrice,
      salePrice: params.salePrice,
      quantity: params.quantity,
      minThreshold: params.minThreshold,
    );
  }
}

/// Delete Product Use Case
/// Business logic for deleting a product
library;

import 'package:equatable/equatable.dart';

import '../../../../core/failure/failures.dart';
import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

/// Delete Product Use Case
class DeleteProductUseCase extends Equatable {
  final ProductRepository repository;

  const DeleteProductUseCase(this.repository);

  /// Execute use case
  Future<ResultFuture<bool>> call(String productId) async {
    return repository.deleteProduct(productId);
  }
}
