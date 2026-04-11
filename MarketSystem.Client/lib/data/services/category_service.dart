import 'dart:convert';
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
      final response = await _httpService.get('/ProductCategories/GetAllCategories');

      if (response.statusCode == 200) {
        // Bo'sh yoki whitespace-only javoblarni tekshirish
        final trimmedBody = response.body.trim();
        if (trimmedBody.isEmpty) {
          return [];
        }

        // JSON ni parse qilish
        final List<dynamic> data = jsonDecode(trimmedBody);
        return data.map((json) => ProductCategoryModel.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Avtorizatsiya xatosi: Iltimos, qayta tizimga kiring');
      } else if (response.statusCode == 403) {
        throw Exception('Ruxsat yo\'q: Faqat Admin va Owner kategoriyalarni ko\'rishi mumkin');
      } else if (response.statusCode == 404) {
        throw Exception('Endpoint topilmadi. Backend ishga tushganini tekshiring');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Kategoriyalarni yuklashda xatolik: $e');
    }
  }

  /// Get category by ID
  Future<ProductCategoryModel?> getCategoryById(int id) async {
    final response = await _httpService.get('/ProductCategories/GetCategoryById/$id');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ProductCategoryModel.fromJson(data);
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to load category: ${response.statusCode}');
    }
  }

  /// Create new category
  Future<ProductCategoryModel> createCategory({
    required String name,
    String? description,
  }) async {
    final request = CreateCategoryRequestModel(
      name: name,
      description: description,
    );

    final response = await _httpService.post(
      '/ProductCategories/CreateCategory',
      body: request.toJson(),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ProductCategoryModel.fromJson(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Category creation failed');
    }
  }

  /// Update category
  Future<ProductCategoryModel?> updateCategory({
    required int id,
    required String name,
    String? description,
    bool isActive = true,
  }) async {
    final request = UpdateCategoryRequestModel(
      id: id,
      name: name,
      description: description,
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
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Category update failed');
    }
  }

  /// Delete category
  Future<bool> deleteCategory(int id) async {
    final response = await _httpService.delete('/ProductCategories/DeleteCategory/$id');

    if (response.statusCode == 200) {
      return true;
    } else if (response.statusCode == 404) {
      return false;
    } else if (response.statusCode == 400) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Category deletion failed: Bad Request');
    } else {
      throw Exception('Failed to delete category: ${response.statusCode}');
    }
  }
}
