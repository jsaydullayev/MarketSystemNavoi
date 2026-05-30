import 'sale_entity.dart';

class SalePageResult {
  final List<SaleEntity> items;
  final int currentPage;
  final int totalPages;
  final int total;

  const SalePageResult({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.total,
  });

  bool get hasMore => currentPage < totalPages;

  SalePageResult appendPage(SalePageResult next) => SalePageResult(
    items: [...items, ...next.items],
    currentPage: next.currentPage,
    totalPages: next.totalPages,
    total: next.total,
  );
}
