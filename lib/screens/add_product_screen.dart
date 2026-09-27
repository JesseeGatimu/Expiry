import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/product.dart';

class AddProductScreen extends StatefulWidget {
  final List<Category> categories;

  const AddProductScreen({super.key, required this.categories});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _sizeController = TextEditingController();

  Category? _selectedCategory;
  DateTime? _expiryDate;
  DateTime? _removalDate;

  @override
  void dispose() {
    _nameController.dispose();
    _sizeController.dispose();
    super.dispose();
  }

  void _calculateRemovalDate() {
    if (_expiryDate == null || _selectedCategory == null) {
      setState(() {
        _removalDate = null;
      });
      return;
    }

    setState(() {
      _removalDate = _expiryDate!.subtract(
        Duration(days: _selectedCategory!.removalDays),
      );
    });
  }

  Future<void> _selectExpiryDate() async {
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
    );

    if (selectedDate == null) {
      return;
    }

    setState(() {
      _expiryDate = selectedDate;
    });

    _calculateRemovalDate();
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Select expiry date';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  void _saveProduct() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category.')),
      );
      return;
    }

    if (_expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an expiry date.')),
      );
      return;
    }

    final removalDate = _expiryDate!.subtract(
      Duration(days: _selectedCategory!.removalDays),
    );

    final product = Product(
      name: _nameController.text.trim(),
      category: _selectedCategory!,
      size: _sizeController.text.trim(),
      expiryDate: _expiryDate!,
      originalRemovalDate: removalDate,
    );

    Navigator.pop(context, product);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Product',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Product name',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'e.g. Brookside Yoghurt',
                prefixIcon: const Icon(Icons.inventory_2_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter the product name';
                }

                return null;
              },
            ),

            const SizedBox(height: 22),

            const Text(
              'Category',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<Category>(
              initialValue: _selectedCategory,
              decoration: InputDecoration(
                hintText: 'Select category',
                prefixIcon: const Icon(Icons.category_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              items: widget.categories.map((category) {
                return DropdownMenuItem<Category>(
                  value: category,
                  child: Text(category.name),
                );
              }).toList(),
              onChanged: (category) {
                setState(() {
                  _selectedCategory = category;
                });

                _calculateRemovalDate();
              },
              validator: (value) {
                if (value == null) {
                  return 'Select a category';
                }

                return null;
              },
            ),

            const SizedBox(height: 10),

            if (_selectedCategory != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        'Remove this product '
                        '${_selectedCategory!.removalDays} '
                        '${_selectedCategory!.removalDays == 1 ? 'day' : 'days'} '
                        'before expiry.',
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 22),

            const Text(
              'Size',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            TextFormField(
              controller: _sizeController,
              decoration: InputDecoration(
                hintText: 'e.g. 500 ml',
                prefixIcon: const Icon(Icons.straighten_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter the product size';
                }

                return null;
              },
            ),

            const SizedBox(height: 22),

            const Text(
              'Expiry date',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            InkWell(
              onTap: _selectExpiryDate,
              borderRadius: BorderRadius.circular(14),
              child: InputDecorator(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _formatDate(_expiryDate),
                  style: TextStyle(
                    color: _expiryDate == null
                        ? Colors.grey.shade600
                        : Colors.black,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            if (_removalDate != null)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.orange.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SHELF REMOVAL DATE',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      _formatDate(_removalDate),
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      'The product should be removed '
                      'from the shelf on this date.',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 30),

            SizedBox(
              height: 55,
              child: FilledButton.icon(
                onPressed: _saveProduct,
                icon: const Icon(Icons.check),
                label: const Text(
                  'Add Product',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
