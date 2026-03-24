import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/pizza.dart';

/// Repository for managing product data in the database.
class ProductRepository {
  final Database db;

  ProductRepository(this.db);

  /// Fetches all products from the database.
  ///
  /// If [includeInactive] is true, inactive products will also be returned.
  Future<List<Pizza>> fetchProducts({bool includeInactive = false}) async {
    final rows = await db.query(
      'products',
      where: includeInactive ? null : 'active = 1',
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows
        .map(
          (r) => Pizza(
            name: r['name'] as String,
            price: (r['price'] as num).toDouble(),
            quantity: 0,
            type: r['type'] as String,
          ),
        )
        .toList();
  }

  /// Replaces all products in the database with the provided list.
  ///
  /// This operation is atomic - either all products are replaced or none are.
  Future<void> replaceProducts(List<Pizza> pizzas) async {
    await db.transaction((txn) async {
      await txn.delete('products');
      for (final pizza in pizzas) {
        await txn.insert('products', {
          'name': pizza.name,
          'price': pizza.price,
          'type': pizza.type,
          'active': 1,
        });
      }
    });
  }

  /// Inserts a product into the database.
  ///
  /// Throws an exception if a product with the same name already exists.
  Future<void> insertProduct(Pizza pizza) async {
    await db.insert('products', {
      'name': pizza.name,
      'price': pizza.price,
      'type': pizza.type,
      'active': 1,
    });
  }

  /// Updates an existing product in the database.
  Future<void> updateProduct(Pizza pizza) async {
    await db.update(
      'products',
      {'price': pizza.price, 'type': pizza.type},
      where: 'name = ?',
      whereArgs: [pizza.name],
    );
  }

  /// Deletes a product from the database by name.
  Future<void> deleteProduct(String name) async {
    await db.delete('products', where: 'name = ?', whereArgs: [name]);
  }

  /// Marks a product as inactive without deleting it.
  Future<void> deactivateProduct(String name) async {
    await db.update(
      'products',
      {'active': 0},
      where: 'name = ?',
      whereArgs: [name],
    );
  }
}
