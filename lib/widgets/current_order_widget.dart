import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pizza.dart';
import '../services/cart_service.dart';
import '../utils/format_utils.dart';
import '../constants/app_constants.dart';

class CurrentOrderWidget extends StatelessWidget {
  final VoidCallback onPutOnHold;
  final VoidCallback onCheckoutDirect;

  const CurrentOrderWidget({
    super.key,
    required this.onPutOnHold,
    required this.onCheckoutDirect,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CartService>(
      builder: (context, cartService, child) {
        return Container(
          color: Colors.grey[200],
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12.0),
                color: Colors.grey[300],
                child: const Text(
                  'COMMANDE EN COURS',
                  style: const TextStyle(
                    fontSize: AppConstants.subtitleFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: cartService.items.length,
                  itemBuilder: (context, index) {
                    final pizza = cartService.items[index];
                    return CartItemTile(
                      pizza: pizza,
                      onQuantityChanged: (change) {
                        cartService.adjustQuantity(pizza.name, change);
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Total: ${formatPrice(cartService.totalPrice)}",
                            style: const TextStyle(
                              fontSize: AppConstants.titleFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                foregroundColor: cartService.isEmpty ? Colors.grey : Colors.black,
                                backgroundColor: cartService.isEmpty ? AppConstants.disabledButtonColor : AppConstants.holdButtonColor,
                                textStyle: const TextStyle(fontSize: AppConstants.subtitleFontSize),
                              ),
                              onPressed: cartService.isEmpty ? null : onPutOnHold,
                              child: Text(cartService.isEmpty ? AppConstants.emptyCartMessage : "En attente"),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                foregroundColor: cartService.isEmpty ? Colors.grey : Colors.black,
                                backgroundColor: cartService.isEmpty ? AppConstants.disabledButtonColor : AppConstants.checkoutButtonColor,
                                textStyle: const TextStyle(fontSize: AppConstants.subtitleFontSize),
                              ),
                              onPressed: cartService.isEmpty ? null : onCheckoutDirect,
                              child: Text(cartService.isEmpty ? AppConstants.emptyCartMessage : "Encaisser"),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CartItemTile extends StatelessWidget {
  final Pizza pizza;
  final Function(int) onQuantityChanged;

  const CartItemTile({
    super.key,
    required this.pizza,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: AppConstants.cartItemTileColor,
      title: Text("${pizza.name} x${pizza.quantity}"),
      subtitle: Text(formatPrice(pizza.price)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () => onQuantityChanged(-1),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => onQuantityChanged(1),
          ),
        ],
      ),
    );
  }
}
