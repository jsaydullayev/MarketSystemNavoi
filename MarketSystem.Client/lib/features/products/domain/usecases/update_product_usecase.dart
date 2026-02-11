/// Product Events
/// Events for Product Bloc
library;

import 'package:equatable/equatable.dart';
import '../../entities/product_entity.dart';

/// Product Event Base
abstract class ProductEvent extends Equatable {
  const ProductEvent();
}

/// Load products event
class LoadProductsEvent extends ProductEvent {
  const LoadProductsEvent();

  @override
  List<Object?> get props => [];
}

/// Refresh products event
class RefreshProductsEvent extends ProductEvent {
  const RefreshProductsEvent();

  @override
  List<Object?> get props => [];
}

/// Create product event
class CreateProductEvent extends ProductEvent {
  final String name;
  final bool isTemporary;
  final double costPrice;
  final double salePrice;
  final int quantity;
  final int minThreshold;

  const CreateProductEvent({
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
        quantity,
        minThreshold,
      ];
}

/// Update product event
class UpdateProductEvent extends ProductEvent {
  final String id;
  final String name;
  final bool isTemporary;
  final double costPrice;
  final double salePrice;
  final int quantity;
  final int minThreshold;

  const UpdateProductEvent({
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
        quantity,
        minThreshold,
      ];
}

/// Delete product event
class DeleteProductEvent extends ProductEvent {
  final String id;

  const DeleteProductEvent({required this.id});

  @override
  List<Object?> get props => [id];
}
