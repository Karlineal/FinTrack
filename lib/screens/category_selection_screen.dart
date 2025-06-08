import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../utils/format_util.dart';

class CategorySelectionScreen extends StatefulWidget {
  final Set<Category> initialSelectedCategories;

  const CategorySelectionScreen({
    super.key,
    required this.initialSelectedCategories,
  });

  @override
  State<CategorySelectionScreen> createState() =>
      _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends State<CategorySelectionScreen> {
  late Set<Category> _selectedCategories;

  @override
  void initState() {
    super.initState();
    _selectedCategories = Set<Category>.from(widget.initialSelectedCategories);
  }

  void _toggleCategory(Category category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Category> expenseCategories =
        Category.values
            .where(
              (c) =>
                  c != Category.salary &&
                  c != Category.gift &&
                  c != Category.other,
            )
            .toList();
    final List<Category> incomeCategories = [
      Category.salary,
      Category.gift,
      Category.other,
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('选择分类'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_selectedCategories),
            child: const Text(
              '完成',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCategorySection('支出', expenseCategories),
            const SizedBox(height: 24),
            _buildCategorySection('收入', incomeCategories),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(String title, List<Category> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children:
              categories.map((category) {
                final bool isSelected = _selectedCategories.contains(category);
                return ChoiceChip(
                  label: Text(FormatUtil.getCategoryName(category)),
                  avatar:
                      isSelected
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                  selected: isSelected,
                  onSelected: (selected) {
                    _toggleCategory(category);
                  },
                  selectedColor: Colors.green,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                  backgroundColor: Colors.grey[200],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isSelected ? Colors.green : Colors.grey[300]!,
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }
}
