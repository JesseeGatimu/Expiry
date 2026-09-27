import 'category.dart';

enum ProductStatus { active, sold, removed, expired }

class Product {
  final String name;
  final Category category;
  final String size;
  final DateTime expiryDate;
  final DateTime originalRemovalDate;

  DateTime currentRemovalDate;
  int extensionDays;
  ProductStatus status;

  Product({
    required this.name,
    required this.category,
    required this.size,
    required this.expiryDate,
    required this.originalRemovalDate,
    DateTime? currentRemovalDate,
    this.extensionDays = 0,
    this.status = ProductStatus.active,
  }) : currentRemovalDate = currentRemovalDate ?? originalRemovalDate;
}
