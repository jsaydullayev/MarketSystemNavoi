/// Sale Remote Data Source
/// Sales API dan ma'lumot olish

import '../../../../data/services/sales_service.dart';

/// Sale Remote Data Source
/// API bilan ishlash uchun mas'ul
class SaleRemoteDataSource {
  final SalesService _salesService;

  const SaleRemoteDataSource({required SalesService salesService})
      : _salesService = salesService;

  /// Barcha sotuvlarni olish
  Future<List<dynamic>> getAllSales() async {
    return _salesService.getAllSales();
  }

  /// Sotuvni ID bo'yicha olish
  Future<Map<String, dynamic>> getSaleById(String saleId) async {
    return _salesService.getSaleById(saleId);
  }

  /// Mening draft sotuvlarimni olish
  Future<List<dynamic>> getMyDraftSales() async {
    return _salesService.getMyDraftSales();
  }

  /// Yangi sotuv yaratish
  Future<dynamic> createSale({String? customerId}) async {
    return _salesService.createSale(customerId: customerId);
  }

  /// Sotuvga mahsulot qo'shish
  Future<dynamic> addSaleItem({
    required String saleId,
    required String productId,
    required int quantity,
    required double salePrice,
    required double minSalePrice,
    String? comment,
  }) async {
    return _salesService.addSaleItem(
      saleId: saleId,
      productId: productId,
      quantity: quantity,
      salePrice: salePrice,
      minSalePrice: minSalePrice,
      comment: comment,
    );
  }

  /// Sotuvga to'lov qo'shish
  Future<dynamic> addPayment({
    required String saleId,
    required String paymentType,
    required double amount,
  }) async {
    return _salesService.addPayment(
      saleId: saleId,
      paymentType: paymentType,
      amount: amount,
    );
  }

  /// Sotuvni bekor qilish
  Future<dynamic> cancelSale({
    required String saleId,
    required String adminId,
  }) async {
    return _salesService.cancelSale(
      saleId: saleId,
      adminId: adminId,
    );
  }
}
