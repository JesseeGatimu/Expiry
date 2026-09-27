import '../models/category.dart';
import '../models/product.dart';

class AppData {
  static final List<Category> categories = [
    Category(name: 'Milk', removalDays: 2),
    Category(name: 'Yoghurt', removalDays: 5),
    Category(name: 'Cheese', removalDays: 20),
    Category(name: 'Bread', removalDays: 2),
  ];

  static final List<Product> products = [];
}
