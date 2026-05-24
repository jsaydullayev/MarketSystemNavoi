import 'dart:convert';
import '../../core/errors/api_exception.dart';
import '../../core/providers/auth_provider.dart';
import 'http_service.dart';
import '../models/product_category_model.dart';

class CategoryService {
  final AuthProvider authProvider;
  final HttpService _httpService;

  CategoryService({required this.authProvider, HttpService? httpService})
    : _httpService = httpService ?? HttpService();

  /// Get all categories
  Future<List<ProductCategoryModel>> getAllCategories() async {
    try {
      final response = await _httpService.get(
        '/ProductCategories/GetAllCategories',
      );

      if (response.statusCode == 200) {
        // Bo'sh yoki whitespace-only javoblarni tekshirish
        final trimmedBody = response.body.trim();
        if (trimmedBody.isEmpty) {
          return [];
        }

        // JSON ni parse qilish
        final List<dynamic> data = jsonDecode(trimmedBody);
        return data.map((json) => ProductCategoryModel.fromJson(json)).toList();
      }
      throw ApiException.fromResponse(
        response,
        fallbackMessage: switch (response.statusCode) {
          401 => 'Avtorizatsiya xatosi: Iltimos, qayta tizimga kiring',
          403 =>
            'Ruxsat yo\'q: Faqat Admin va Owner kategoriyalarni ko\'rishi mumkin',
          404 => 'Endpoint topilmadi. Backend ishga tushganini tekshiring',
          _ => 'Failed to load categories',
        },
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Kategoriyalarni yuklashda xatolik: $e');
    }
  }

  /// Get category by ID
  Future<ProductCategoryModel?> getCategoryById(int id) async {
    final response = await _httpService.get(
      '/ProductCategories/GetCategoryById/$id',
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ProductCategoryModel.fromJson(data);
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Failed to load category',
      );
    }
  }

  /// Create new category
  Future<ProductCategoryModel> createCategory({
    required String name,
    String? description,
    String? icon,
  }) async {
    final request = CreateCategoryRequestModel(
      name: name,
      description: description,
      icon: icon,
    );

    final response = await _httpService.post(
      '/ProductCategories/CreateCategory',
      body: request.toJson(),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ProductCategoryModel.fromJson(data);
    }
    throw ApiException.fromResponse(
      response,
      fallbackMessage: 'Category creation failed',
    );
  }

  /// Update category
  Future<ProductCategoryModel?> updateCategory({
    required int id,
    required String name,
    String? description,
    String? icon,
    bool isActive = true,
  }) async {
    final request = UpdateCategoryRequestModel(
      id: id,
      name: name,
      description: description,
      icon: icon,
      isActive: isActive,
    );

    final response = await _httpService.put(
      '/ProductCategories/UpdateCategory',
      body: request.toJson(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ProductCategoryModel.fromJson(data);
    } else if (response.statusCode == 404) {
      return null;
    }
    throw ApiException.fromResponse(
      response,
      fallbackMessage: 'Category update failed',
    );
  }

  /// Delete category
  Future<bool> deleteCategory(int id) async {
    final response = await _httpService.delete(
      '/ProductCategories/DeleteCategory/$id',
    );

    if (response.statusCode == 200) {
      return true;
    } else if (response.statusCode == 404) {
      return false;
    }
    throw ApiException.fromResponse(
      response,
      fallbackMessage: 'Failed to delete category',
    );
  }
}
