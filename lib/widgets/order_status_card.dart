import 'package:flutter/material.dart';
import '../models/commande_attente.dart';
import '../services/order_service.dart';
import '../utils/format_utils.dart';
import '../constants/app_constants.dart';

class OrderStatusCard extends StatelessWidget {
  final CommandeAttente order;
  final OrderStatusInfo statusInfo;
  final VoidCallback? onTap;
  final VoidCallback? onValidate;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;

  const OrderStatusCard({
    super.key,
    required this.order,
    required this.statusInfo,
    this.onTap,
    this.onValidate,
    this.onEdit,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8.0),
        elevation: AppConstants.cardElevation,
        color: statusInfo.backgroundColor,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            border: Border.all(
              color: statusInfo.color,
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOrderHeader(),
                const SizedBox(height: 4),
                _buildOrderItems(),
                const SizedBox(height: 8),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              statusInfo.icon,
              size: 16,
              color: statusInfo.color,
            ),
            const SizedBox(width: 4),
            Text(
              'Récup: ${order.heureRecuperationPrevue}',
              style: const TextStyle(
                fontSize: AppConstants.subtitleFontSize,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(${order.heureComposition.hour.toString().padLeft(2, '0')}:${order.heureComposition.minute.toString().padLeft(2, '0')})',
              style: TextStyle(
                fontSize: AppConstants.smallFontSize,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        Expanded(
          child: Center(
            child: Text(
              statusInfo.statusText,
              style: TextStyle(
                fontSize: AppConstants.smallFontSize,
                fontWeight: FontWeight.w600,
                color: statusInfo.color,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
        Text(
          formatPrice(order.montant),
          style: const TextStyle(
            fontSize: AppConstants.largeFontSize,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItems() {
    return Text(
      order.articles
          .map((a) => '${a.name} x${a.quantity}')
          .join(', '),
      style: const TextStyle(fontSize: AppConstants.captionFontSize),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (onValidate != null)
          Expanded(
            child: _buildActionButton(
              onPressed: onValidate!,
              icon: Icons.check,
              label: 'Valider',
              backgroundColor: AppConstants.validateButtonBg,
              foregroundColor: AppConstants.validateButtonFg,
            ),
          ),
        if (onValidate != null && (onEdit != null || onCancel != null))
          const SizedBox(width: 4),
        if (onEdit != null)
          Expanded(
            child: _buildActionButton(
              onPressed: onEdit!,
              icon: Icons.edit,
              label: 'Modifier',
              backgroundColor: AppConstants.editButtonBg,
              foregroundColor: AppConstants.editButtonFg,
            ),
          ),
        if (onEdit != null && onCancel != null)
          const SizedBox(width: 4),
        if (onCancel != null)
          Expanded(
            child: _buildActionButton(
              onPressed: onCancel!,
              icon: Icons.delete,
              label: 'Annuler',
              backgroundColor: AppConstants.cancelButtonBg,
              foregroundColor: AppConstants.cancelButtonFg,
            ),
          ),
      ],
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: AppConstants.captionFontSize)),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        minimumSize: const Size(0, 32),
      ),
    );
  }
}
