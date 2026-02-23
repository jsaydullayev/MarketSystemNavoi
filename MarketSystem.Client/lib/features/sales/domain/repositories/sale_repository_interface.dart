/// Sale Repository Interface
/// Sotuv repository interfeysi - data layer uchun kontrakt

import '../../../../core/failure/api_result.dart';
import '../entities/sale_entity.dart';
import '../entities/sale_item_entity.dart';
import '../entities/payment_entity.dart';

/// Sale Repository Interface
/// Data layer implementation qilishi kerak bo'lgan metodlar
abstract class SaleRepositoryInterface {
  /// Barcha sotuvlarni olish
  Future<ApiResult<List<SaleEntity>>> getAllSales();

  /// Sotuvni tafsilotlari bilan olish
  Future<ApiResult<Map<String, dynamic>>> getSaleDetail(String saleId);

  /// Mening draft sotuvlarimni olish
  Future<ApiResult<List<SaleEntity>>> getMyDraftSales();

  /// Yangi sotuv yaratish
  Future<ApiResult<SaleEntity>> createSale({String? customerId});

  /// Sotuvga mahsulot qo'shish
  Future<ApiResult<void>> addSaleItem({
    required String saleId,
    required String productId,
    required double quantity,  // ✅ DECIMAL - 22.5 m, 15.5 kg bo'lishi mumkin
    required double salePrice,
    required double minSalePrice,  // ✅ Yangi: minPrice parametri qo'shildi
    String? comment,
  });

  /// Sotuvga to'lov qo'shish
  Future<ApiResult<void>> addPayment({
    required String saleId,
    required String paymentType,
    required double amount,
  });

  /// Sotuvni bekor qilish (Admin/Owner)
  Future<ApiResult<void>> cancelSale({
    required String saleId,
    required String adminId,
  });

  /// Sotilgan mahsulotni qaytarish
  Future<ApiResult<void>> returnSaleItem({
    required String saleId,
    required String saleItemId,
    required double quantity,
    String? comment,
  });
}
