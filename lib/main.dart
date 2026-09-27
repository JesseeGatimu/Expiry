import 'package:flutter/material.dart';

import 'data/app_data.dart';
import 'models/product.dart';
import 'screens/add_product_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/products_screen.dart';

void main() {
  runApp(const ExpiryTrackerApp());
}

class ExpiryTrackerApp extends StatelessWidget {
  const ExpiryTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Expiry Tracker',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        scaffoldBackgroundColor: const Color(0xFFF7F8FC),
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<void> _openAddProduct() async {
    final Product? product = await Navigator.push<Product>(
      context,
      MaterialPageRoute(
        builder: (context) {
          return AddProductScreen(categories: AppData.categories);
        },
      ),
    );

    if (!mounted) {
      return;
    }

    if (product == null) {
      return;
    }

    setState(() {
      AppData.products.add(product);
    });
  }

  Future<void> _openProducts() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return const ProductsScreen();
        },
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openCategories() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return const CategoriesScreen();
        },
      ),
    );
    if (mounted) setState(() {});
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  bool _isToday(DateTime date) {
    final DateTime today = DateTime.now();

    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }

  String _removalLabel(DateTime date) {
    final DateTime today = DateTime.now();

    final DateTime todayOnly = DateTime(today.year, today.month, today.day);

    final DateTime dateOnly = DateTime(date.year, date.month, date.day);

    final int difference = dateOnly.difference(todayOnly).inDays;

    if (difference == 0) {
      return 'Today';
    }

    if (difference == 1) {
      return 'Tomorrow';
    }

    if (difference > 1) {
      return '$difference days';
    }

    return 'Overdue';
  }

  int _countProductsForRemovalToday() {
    final DateTime today = DateTime.now();
    final DateTime todayOnly = DateTime(today.year, today.month, today.day);
    return AppData.products.where((product) {
      final DateTime removalDate = DateTime(
        product.currentRemovalDate.year,
        product.currentRemovalDate.month,
        product.currentRemovalDate.day,
      );
      return product.status == ProductStatus.active &&
          !removalDate.isAfter(todayOnly);
    }).length;
  }

  void _updateExpiredProducts() {
    final DateTime today = DateTime.now();
    final DateTime todayOnly = DateTime(today.year, today.month, today.day);
    for (final Product product in AppData.products) {
      final DateTime expiryDate = DateTime(
        product.expiryDate.year,
        product.expiryDate.month,
        product.expiryDate.day,
      );
      if (product.status == ProductStatus.active &&
          expiryDate.isBefore(todayOnly)) {
        product.status = ProductStatus.expired;
      }
    }
  }

  int _countActiveProducts() {
    return AppData.products.where((product) {
      return product.status == ProductStatus.active;
    }).length;
  }

  int _countSoldProducts() {
    return AppData.products.where((product) {
      return product.status == ProductStatus.sold;
    }).length;
  }

  int _countRemovedProducts() {
    return AppData.products.where((product) {
      return product.status == ProductStatus.removed;
    }).length;
  }

  int _countExpiredProducts() {
    return AppData.products.where((product) {
      return product.status == ProductStatus.expired;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    _updateExpiredProducts();
    final int removeTodayCount = _countProductsForRemovalToday();

    final List<Product> activeProducts = AppData.products.where((product) {
      return product.status == ProductStatus.active;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Expiry Tracker',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Good evening 👋',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Here is what needs your attention today.',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red.shade700,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'REMOVE TODAY',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '$removeTodayCount '
                          '${removeTodayCount == 1 ? 'product' : 'products'} '
                          'need attention',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          removeTodayCount == 0
                              ? 'Nothing needs to be removed today.'
                              : 'Check these products before '
                                    'they expire.',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Tracked products',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (activeProducts.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 50,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No products yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Add a product to start tracking '
                      'its shelf removal date.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ...activeProducts.map((product) {
              final bool isToday = _isToday(product.currentRemovalDate);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ProductCard(
                  productName: product.name,
                  categoryName: product.category.name,
                  size: product.size,
                  expiryDate: _formatDate(product.expiryDate),
                  removalDate: _formatDate(product.currentRemovalDate),
                  daysUntilRemoval: _removalLabel(product.currentRemovalDate),
                  icon: Icons.inventory_2_outlined,
                  isToday: isToday,
                ),
              );
            }),
            const SizedBox(height: 16),
            const Text(
              'Overview',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _OverviewCard(
                    title: 'Active',
                    value: '${_countActiveProducts()}',
                    icon: Icons.inventory_2_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _OverviewCard(
                    title: 'Sold',
                    value: '${_countSoldProducts()}',
                    icon: Icons.check_circle_outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _OverviewCard(
                    title: 'Removed',
                    value: '${_countRemovedProducts()}',
                    icon: Icons.remove_circle_outline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _OverviewCard(
                    title: 'Expired',
                    value: '${_countExpiredProducts()}',
                    icon: Icons.error_outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddProduct,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Product',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) {
            _openProducts();
          }

          if (index == 2) {
            _openCategories();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Categories',
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final String productName;
  final String categoryName;
  final String size;
  final String expiryDate;
  final String removalDate;
  final String daysUntilRemoval;
  final IconData icon;
  final bool isToday;

  const _ProductCard({
    required this.productName,
    required this.categoryName,
    required this.size,
    required this.expiryDate,
    required this.removalDate,
    required this.daysUntilRemoval,
    required this.icon,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isToday
                    ? Colors.red.shade50
                    : Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: isToday
                    ? Colors.red.shade700
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$categoryName • $size',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    'Expires: $expiryDate',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    'Remove: $removalDate',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isToday
                          ? Colors.red.shade700
                          : Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: isToday ? Colors.red.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                daysUntilRemoval,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isToday ? Colors.red.shade700 : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _OverviewCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 25, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 3),
            Text(title, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}
