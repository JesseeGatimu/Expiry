import 'package:flutter/material.dart';

import '../data/app_data.dart';
import '../models/product.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  @override
  void initState() {
    super.initState();

    _updateExpiredProducts();
  }

  void _updateExpiredProducts() {
    final DateTime today = DateTime.now();

    final DateTime todayOnly = DateTime(today.year, today.month, today.day);

    for (final Product product in AppData.products) {
      if (product.status != ProductStatus.active) {
        continue;
      }

      final DateTime expiryDateOnly = DateTime(
        product.expiryDate.year,
        product.expiryDate.month,
        product.expiryDate.day,
      );

      if (expiryDateOnly.isBefore(todayOnly)) {
        product.status = ProductStatus.expired;
      }
    }
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

  bool _isOverdue(DateTime date) {
    final DateTime today = DateTime.now();

    final DateTime todayOnly = DateTime(today.year, today.month, today.day);

    final DateTime dateOnly = DateTime(date.year, date.month, date.day);

    return dateOnly.isBefore(todayOnly);
  }

  bool _needsAttention(Product product) {
    return product.status == ProductStatus.active &&
        (_isToday(product.currentRemovalDate) ||
            _isOverdue(product.currentRemovalDate));
  }

  String _removalWarning(Product product) {
    if (_isToday(product.currentRemovalDate)) {
      return 'REMOVE TODAY';
    }

    return 'OVERDUE';
  }

  String _removalMessage(Product product) {
    if (_isToday(product.currentRemovalDate)) {
      return 'This product should be removed '
          'from the shelf today.';
    }

    return 'This product should have been '
        'removed from the shelf already.';
  }

  String _statusText(ProductStatus status) {
    switch (status) {
      case ProductStatus.active:
        return 'Active';

      case ProductStatus.sold:
        return 'Sold';

      case ProductStatus.removed:
        return 'Removed';

      case ProductStatus.expired:
        return 'Expired';
    }
  }

  Color _statusColor(BuildContext context, ProductStatus status) {
    switch (status) {
      case ProductStatus.active:
        return Theme.of(context).colorScheme.primary;

      case ProductStatus.sold:
        return Colors.green.shade700;

      case ProductStatus.removed:
        return Colors.orange.shade700;

      case ProductStatus.expired:
        return Colors.red.shade700;
    }
  }

  Color _statusBackground(BuildContext context, ProductStatus status) {
    switch (status) {
      case ProductStatus.active:
        return Theme.of(context).colorScheme.primaryContainer;

      case ProductStatus.sold:
        return Colors.green.shade50;

      case ProductStatus.removed:
        return Colors.orange.shade50;

      case ProductStatus.expired:
        return Colors.red.shade50;
    }
  }

  Future<void> _markAsSold(Product product) async {
    try {
      await AppData.updateProduct(product, ProductStatus.sold);
      if (mounted) {
        setState(() {});
        _showMessage('${product.name} marked as sold.');
      }
    } catch (error) {
      _showMessage('Could not update product: $error');
    }
  }

  Future<void> _markAsRemoved(Product product) async {
    try {
      await AppData.updateProduct(product, ProductStatus.removed);
      if (mounted) {
        setState(() {});
        _showMessage('${product.name} marked as removed.');
      }
    } catch (error) {
      _showMessage('Could not update product: $error');
    }
  }

  Future<void> _showExtendDialog(Product product) async {
    final DateTime removalDate = DateTime(
      product.currentRemovalDate.year,
      product.currentRemovalDate.month,
      product.currentRemovalDate.day,
    );
    final DateTime expiryDate = DateTime(
      product.expiryDate.year,
      product.expiryDate.month,
      product.expiryDate.day,
    );
    final int availableDays = expiryDate.difference(removalDate).inDays;
    if (availableDays <= 0) {
      _showMessage('This product cannot be extended beyond its expiry date.');
      return;
    }

    String input = '';
    final int? extraDays = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Extend shelf time'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Current removal date: ${_formatDate(product.currentRemovalDate)}',
            ),
            Text(
              'You can extend it by up to $availableDays days.',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            const SizedBox(height: 18),
            TextField(
              keyboardType: TextInputType.number,
              autofocus: true,
              onChanged: (value) => input = value,
              decoration: const InputDecoration(
                labelText: 'Extra days',
                hintText: 'e.g. 2',
                suffixText: 'days',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final int? days = int.tryParse(input.trim());
              if (days == null || days <= 0 || days > availableDays) {
                return;
              }
              Navigator.pop(dialogContext, days);
            },
            child: const Text('Extend'),
          ),
        ],
      ),
    );

    if (!mounted || extraDays == null) return;
    try {
      await AppData.extendProduct(product, extraDays);
      if (mounted) {
        setState(() {});
        _showMessage('Removal date extended successfully.');
      }
    } catch (error) {
      _showMessage('Could not extend product: $error');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showProductActions(Product product) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${product.category.name} • '
                  '${product.size}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),
                if (product.status == ProductStatus.active) ...[
                  ListTile(
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.check_circle_outline,
                        color: Colors.green.shade700,
                      ),
                    ),
                    title: const Text(
                      'Mark as Sold',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('The product was sold.'),
                    onTap: () {
                      Navigator.pop(context);
                      _markAsSold(product);
                    },
                  ),
                  const SizedBox(height: 4),
                  ListTile(
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.remove_circle_outline,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    title: const Text(
                      'Mark as Removed',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'The product was removed from the shelf.',
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _markAsRemoved(product);
                    },
                  ),
                  const SizedBox(height: 4),
                  ListTile(
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.calendar_month_outlined,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    title: const Text(
                      'Extend Shelf Time',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('Give the product additional days.'),
                    onTap: () {
                      Navigator.pop(context);
                      _showExtendDialog(product);
                    },
                  ),
                ],
                if (product.status == ProductStatus.expired)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'This product has expired.',
                              style: TextStyle(
                                color: Colors.red.shade800,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (product.status != ProductStatus.active &&
                    product.status != ProductStatus.expired)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'This product is already '
                      '${_statusText(product.status).toLowerCase()}.',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    _updateExpiredProducts();

    final List<Product> activeProducts = AppData.products
        .where((product) => product.status == ProductStatus.active)
        .toList();

    final List<Product> attentionProducts =
        activeProducts.where(_needsAttention).toList()..sort(
          (first, second) =>
              first.currentRemovalDate.compareTo(second.currentRemovalDate),
        );

    final List<Product> otherProducts =
        activeProducts.where((product) => !_needsAttention(product)).toList()
          ..sort(
            (first, second) =>
                first.currentRemovalDate.compareTo(second.currentRemovalDate),
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Products',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: activeProducts.isEmpty
          ? _buildEmptyState()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (attentionProducts.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Needs attention',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...attentionProducts.map((product) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildProductCard(context, product),
                    );
                  }),
                  if (otherProducts.isNotEmpty) const SizedBox(height: 12),
                ],
                if (otherProducts.isNotEmpty) ...[
                  const Text(
                    'All products',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${activeProducts.length} '
                    '${activeProducts.length == 1 ? 'product' : 'products'} '
                    'tracked',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  ...otherProducts.map((product) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildProductCard(context, product),
                    );
                  }),
                ],
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 70,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 18),
            const Text(
              'No products yet',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Products you add will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    final bool needsAttention = _needsAttention(product);

    final bool isToday = _isToday(product.currentRemovalDate);

    final Color statusColor = _statusColor(context, product.status);

    final Color statusBackground = _statusBackground(context, product.status);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: needsAttention ? Colors.red.shade50 : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: needsAttention
            ? BorderSide(color: Colors.red.shade200, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          _showProductActions(product);
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (needsAttention) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 21,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _removalWarning(product),
                              style: TextStyle(
                                color: Colors.red.shade800,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _removalMessage(product),
                              style: TextStyle(
                                color: Colors.red.shade800,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: needsAttention
                          ? Colors.red.shade100
                          : statusBackground,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      needsAttention
                          ? Icons.warning_amber_rounded
                          : Icons.inventory_2_outlined,
                      color: needsAttention ? Colors.red.shade700 : statusColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${product.category.name} • '
                          '${product.size}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: needsAttention
                          ? Colors.red.shade100
                          : statusBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      needsAttention
                          ? isToday
                                ? 'Remove'
                                : 'Overdue'
                          : _statusText(product.status),
                      style: TextStyle(
                        color: needsAttention
                            ? Colors.red.shade700
                            : statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _InfoItem(
                      label: 'Expiry',
                      value: _formatDate(product.expiryDate),
                    ),
                  ),
                  Expanded(
                    child: _InfoItem(
                      label: 'Remove',
                      value: _formatDate(product.currentRemovalDate),
                      valueColor: needsAttention ? Colors.red.shade700 : null,
                    ),
                  ),
                ],
              ),
              if (product.extensionDays > 0) ...[
                const SizedBox(height: 10),
                Text(
                  'Extended by '
                  '${product.extensionDays} '
                  '${product.extensionDays == 1 ? 'day' : 'days'}',
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (product.status == ProductStatus.active) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _markAsSold(product);
                        },
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Sold'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _markAsRemoved(product);
                        },
                        icon: const Icon(Icons.remove_circle_outline, size: 18),
                        label: const Text('Removed'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showExtendDialog(product);
                    },
                    icon: const Icon(Icons.calendar_month_outlined, size: 18),
                    label: const Text('Extend Shelf Time'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoItem({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
