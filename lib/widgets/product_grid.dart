import 'package:flutter/material.dart';
import '../models/pizza.dart';
import '../utils/format_utils.dart';
import '../constants/app_constants.dart';

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
    for (String categoryType in AppConstants.categoryOrder) {
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

    return SingleChildScrollView(
      child: Column(children: categoryWidgets),
    );
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
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            categoryName.toUpperCase(),
            style: AppStyles.titleStyle,
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: AppConstants.gridCrossAxisCount,
            crossAxisSpacing: AppConstants.gridSpacing,
            mainAxisSpacing: AppConstants.gridSpacing,
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

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color? backgroundColor;
    switch (product.type) {
      case 'Tomate':
        backgroundColor = Colors.red[100];
        break;
      case 'Crème':
        backgroundColor = Colors.blue[100];
        break;
      case 'Softs':
        backgroundColor = Colors.amber[100];
        break;
      case 'Vins':
        backgroundColor = Colors.orange[100];
        break;
      case 'Spécialités':
        backgroundColor = Colors.green[100];
        break;
      case 'Glaces':
        backgroundColor = Colors.purple[100];
        break;
      case 'Desserts':
        backgroundColor = Colors.pink[100];
        break;
    }

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
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              Text(
                formatPrice(product.price),
                style: AppStyles.subtitleStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
