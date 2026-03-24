import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pizza.dart';
import '../services/cart_service.dart';
import '../utils/format_utils.dart';
import '../constants/app_strings.dart';
import '../theme/app_theme.dart';

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
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    final colorScheme = Theme.of(context).colorScheme;
    return Consumer<CartService>(
      builder: (context, cartService, child) {
        return Container(
          color: colorScheme.surface,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12.0),
                color: colorScheme.surfaceContainerHighest,
                child: Text(
                  AppStrings.currentOrderHeader,
                  style: textStyles.subtitle.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
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
                            "${AppStrings.totalPrefix} ${formatPrice(cartService.totalPrice)}",
                            style: textStyles.title.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
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
                                foregroundColor: cartService.isEmpty
                                    ? colorScheme.onSurface.withValues(
                                        alpha: 0.5,
                                      )
                                    : colorScheme.onSurface,
                                backgroundColor: cartService.isEmpty
                                    ? colorScheme.surfaceContainerHighest
                                    : colors.holdButtonColor,
                                textStyle: textStyles.subtitle,
                              ),
                              onPressed: cartService.isEmpty
                                  ? null
                                  : onPutOnHold,
                              child: Text(
                                cartService.isEmpty
                                    ? AppStrings.emptyCartMessage
                                    : cartService.lastPickupTime != null
                                    ? '${AppStrings.holdLabel} (${cartService.lastPickupTime})'
                                    : AppStrings.holdLabel,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                foregroundColor: cartService.isEmpty
                                    ? colorScheme.onSurface.withValues(
                                        alpha: 0.5,
                                      )
                                    : colorScheme.onSurface,
                                backgroundColor: cartService.isEmpty
                                    ? colorScheme.surfaceContainerHighest
                                    : colors.checkoutButtonColor,
                                textStyle: textStyles.subtitle,
                              ),
                              onPressed: cartService.isEmpty
                                  ? null
                                  : onCheckoutDirect,
                              child: Text(
                                cartService.isEmpty
                                    ? AppStrings.emptyCartMessage
                                    : AppStrings.checkoutLabel,
                              ),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textStyles = context.appTextStyles;
    return ListTile(
      tileColor: colorScheme.surfaceContainerLow,
      title: Text(
        "${pizza.quantity} x ${pizza.name}",
        style: textStyles.body.copyWith(color: colorScheme.onSurface),
      ),
      subtitle: Text(
        formatPrice(pizza.price),
        style: textStyles.caption.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.remove, color: colorScheme.onSurface),
            onPressed: () => onQuantityChanged(-1),
          ),
          IconButton(
            icon: Icon(Icons.add, color: colorScheme.onSurface),
            onPressed: () => onQuantityChanged(1),
          ),
        ],
      ),
    );
  }
}
