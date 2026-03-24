import 'package:flutter/material.dart';
import '../models/pizza.dart';
import '../utils/format_utils.dart';
import '../constants/app_categories.dart';
import '../theme/app_theme.dart';

class ProductGrid extends StatelessWidget {
  final List<Pizza> products;
  final Function(Pizza) onProductTap;

  const ProductGrid({
    super.key,
    required this.products,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    // Regrouper les produits par type
    final Map<String, List<Pizza>> groupedProducts = {};
    for (var product in products) {
      groupedProducts.putIfAbsent(product.type, () => []).add(product);
    }

    // Trier chaque groupe par nom
    for (var group in groupedProducts.values) {
      group.sort((a, b) => a.name.compareTo(b.name));
    }

    final List<Widget> categoryWidgets = [];

    // Afficher les catégories dans l'ordre spécifié
    for (String categoryType in AppCategories.categoryOrder) {
      if (groupedProducts.containsKey(categoryType)) {
        final List<Pizza> productsInCategory = groupedProducts[categoryType]!;

        categoryWidgets.add(
          CategorySection(
            categoryName: categoryType,
            products: productsInCategory,
            onProductTap: onProductTap,
          ),
        );
      }
    }

    return SingleChildScrollView(child: Column(children: categoryWidgets));
  }
}

class CategorySection extends StatelessWidget {
  final String categoryName;
  final List<Pizza> products;
  final Function(Pizza) onProductTap;

  const CategorySection({
    super.key,
    required this.categoryName,
    required this.products,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    final layout = context.appLayout;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            categoryName.toUpperCase(),
            style: context.appTextStyles.title,
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: layout.gridCrossAxisCount,
            crossAxisSpacing: layout.gridSpacing,
            mainAxisSpacing: layout.gridSpacing,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return ProductCard(
              product: products[index],
              onTap: () => onProductTap(products[index]),
            );
          },
        ),
      ],
    );
  }
}

class ProductCard extends StatelessWidget {
  final Pizza product;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    final backgroundColor = colors.productTypeBackgroundColor(product.type);

    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: backgroundColor,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                product.name,
                style: textStyles.large,
                textAlign: TextAlign.center,
              ),
              Text(formatPrice(product.price), style: textStyles.subtitle),
            ],
          ),
        ),
      ),
    );
  }
}
