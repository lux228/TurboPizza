import 'package:flutter/material.dart';
import '../models/pending_order.dart';
import '../services/order_service.dart';
import '../utils/format_utils.dart';
import '../theme/app_theme.dart';

class OrderStatusCard extends StatelessWidget {
  final PendingOrder order;
  final OrderStatusInfo statusInfo;
  final VoidCallback? onTap;
  final VoidCallback? onValidate;
  final VoidCallback? onEdit;
  final VoidCallback? onChangeTime;
  final VoidCallback? onCancel;

  const OrderStatusCard({
    super.key,
    required this.order,
    required this.statusInfo,
    this.onTap,
    this.onValidate,
    this.onEdit,
    this.onChangeTime,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    final layout = context.appLayout;
    final statusPalette = _resolveStatusPalette(statusInfo.status, colors);
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8.0),
        elevation: layout.cardElevation,
        color: statusPalette.background,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(layout.borderRadius),
            border: Border.all(
              color: statusPalette.foreground,
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOrderHeader(textStyles, colors, statusPalette.foreground),
                const SizedBox(height: 6),
                _buildOrderItems(textStyles),
                const SizedBox(height: 12),
                _buildActionButtons(colors, textStyles),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ({Color foreground, Color background}) _resolveStatusPalette(
    OrderStatus status,
    AppThemeColors colors,
  ) {
    switch (status) {
      case OrderStatus.late:
        return (foreground: colors.lateColor, background: colors.lateBackgroundColor);
      case OrderStatus.slightlyLate:
        return (
          foreground: colors.slightlyLateColor,
          background: colors.slightlyLateBackgroundColor,
        );
      case OrderStatus.comingSoon:
        return (
          foreground: colors.comingSoonColor,
          background: colors.comingSoonBackgroundColor,
        );
      case OrderStatus.onTime:
        return (foreground: colors.onTimeColor, background: colors.onTimeBackgroundColor);
    }
  }

  Widget _buildOrderHeader(
    AppTextStyles textStyles,
    AppThemeColors colors,
    Color statusColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              statusInfo.icon,
              size: 16,
              color: statusColor,
            ),
            const SizedBox(width: 4),
            Text(
              'Récup: ${order.plannedPickupTime}',
              style: textStyles.subtitle.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.greyText,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(${order.createdAt.hour.toString().padLeft(2, '0')}:${order.createdAt.minute.toString().padLeft(2, '0')})',
              style: textStyles.small.copyWith(
                color: colors.greyText,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        Expanded(
          child: Center(
            child: Text(
              statusInfo.statusText,
              style: textStyles.small.copyWith(
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
        Text(
          formatPrice(order.amount),
          style: textStyles.large.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildOrderItems(AppTextStyles textStyles) {
    return Text(
    order.items
      .map((a) => '${a.quantity} x ${a.name}')
          .join(', '),
      style: textStyles.caption,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildActionButtons(AppThemeColors colors, AppTextStyles textStyles) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (onValidate != null)
          Expanded(
            child: _buildActionButton(
              onPressed: onValidate!,
              icon: Icons.check,
              label: 'Valider',
              backgroundColor: colors.validateButtonBg,
              foregroundColor: colors.validateButtonFg,
              textStyles: textStyles,
            ),
          ),
        if (onValidate != null && (onEdit != null || onChangeTime != null || onCancel != null))
          const SizedBox(width: 8),
        if (onEdit != null)
          Expanded(
            child: _buildActionButton(
              onPressed: onEdit!,
              icon: Icons.edit,
              label: 'Modifier',
              backgroundColor: colors.editButtonBg,
              foregroundColor: colors.editButtonFg,
              textStyles: textStyles,
            ),
          ),
        if (onEdit != null && (onChangeTime != null || onCancel != null))
          const SizedBox(width: 8),
        if (onChangeTime != null)
          Expanded(
            child: _buildActionButton(
              onPressed: onChangeTime!,
              icon: Icons.schedule,
              label: 'Horaire',
              backgroundColor: colors.lightBlueAccent,
              foregroundColor: colors.primaryBlue,
              textStyles: textStyles,
            ),
          ),
        if (onChangeTime != null && onCancel != null)
          const SizedBox(width: 8),
        if (onCancel != null)
          Expanded(
            child: _buildActionButton(
              onPressed: onCancel!,
              icon: Icons.delete,
              label: 'Annuler',
              backgroundColor: colors.cancelButtonBg,
              foregroundColor: colors.cancelButtonFg,
              textStyles: textStyles,
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
    required AppTextStyles textStyles,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label, style: textStyles.body),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
