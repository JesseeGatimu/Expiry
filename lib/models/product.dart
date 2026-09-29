import 'category.dart';

enum ProductStatus { active, sold, removed, expired }

class Product {
  final String? id;
  final String name;
  final Category category;
  final String size;
  final DateTime expiryDate;
  final DateTime originalRemovalDate;

  DateTime currentRemovalDate;
  int extensionDays;
  ProductStatus status;

  Product({
    this.id,
    required this.name,
    required this.category,
    required this.size,
    required this.expiryDate,
    required this.originalRemovalDate,
    DateTime? currentRemovalDate,
    this.extensionDays = 0,
    this.status = ProductStatus.active,
  }) : currentRemovalDate = currentRemovalDate ?? originalRemovalDate;

  /// True when the product is still marked active but its expiry has passed.
  /// Derived — never mutate [status] to expire a product.
  bool get isExpired {
    if (status != ProductStatus.active) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final exp = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return exp.isBefore(today);
  }

  /// The status the UI should show — merges stored status + derived expiry.
  ProductStatus get effectiveStatus =>
      isExpired ? ProductStatus.expired : status;

  static ProductStatus parseStatus(String? raw) {
    return ProductStatus.values.firstWhere(
      (s) => s.name == raw,
      orElse: () => ProductStatus.active,
    );
  }
}
