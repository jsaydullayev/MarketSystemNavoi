import 'dart:convert';
import '../../core/providers/auth_provider.dart';
import '../../core/constants/api_constants.dart';
import 'http_service.dart';
import '../models/product_category_model.dart';

class CategoryService {
  final AuthProvider authProvider;
  late final HttpService _httpService;

  CategoryService({required this.authProvider}) {
    _httpService = HttpService();
  }

  /// Get all categories
  Future<List<ProductCategoryModel>> getAllCategories() async {
    final response = await _httpService.get('${ApiConstants.baseUrl}/ProductCategories/GetAllCategories');

    if (response.statusCode == 200) {
      if (response.body.isEmpty) {
        return [];
      }
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ProductCategoryModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load categories: ${response.statusCode}');
    }
  }

  /// Get category by ID
  Future<ProductCategoryModel?> getCategoryById(int id) async {
    final response = await _httpService.get('${ApiConstants.baseUrl}/ProductCategories/GetCategoryById/$id');

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
      '${ApiConstants.baseUrl}/ProductCategories/CreateCategory',
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
      '${ApiConstants.baseUrl}/ProductCategories/UpdateCategory',
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
    final response = await _httpService.delete('${ApiConstants.baseUrl}/ProductCategories/DeleteCategory/$id');

    if (response.statusCode == 200) {
      return true;
    } else if (response.statusCode == 404) {
      return false;
    } else {
      throw Exception('Failed to delete category: ${response.statusCode}');
    }
  }
}
