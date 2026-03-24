import 'dart:async';

import 'package:flutter/material.dart';
import '../constants/app_durations.dart';
import '../theme/app_theme.dart';

enum AppSnackBarType { info, success, warning, error }

OverlayEntry? _activeEntry;

Color _resolveAccent(AppThemeColors colors, AppSnackBarType type) {
  return switch (type) {
    AppSnackBarType.success => colors.successGreen,
    AppSnackBarType.warning => colors.warningOrange,
    AppSnackBarType.error => colors.errorRed,
    AppSnackBarType.info => colors.primaryBlue,
  };
}

void showAppSnackBar(
  BuildContext context,
  String message, {
  AppSnackBarType type = AppSnackBarType.info,
}) {
  _activeEntry?.remove();

  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  final colors = context.appColors;
  final accent = _resolveAccent(colors, type);
  final topInset = MediaQuery.maybeOf(context)?.padding.top ?? 0.0;

  _activeEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: topInset + 12,
      left: 12,
      right: 12,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: _ToastContainer(
            message: message,
            accent: accent,
            duration: AppDurations.snackBarDuration,
            onDismiss: () {
              _activeEntry?.remove();
              _activeEntry = null;
            },
          ),
        ),
      ),
    ),
  );

  overlay.insert(_activeEntry!);
}

class _ToastContainer extends StatefulWidget {
  final String message;
  final Color accent;
  final Duration duration;
  final VoidCallback onDismiss;

  const _ToastContainer({
    required this.message,
    required this.accent,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_ToastContainer> createState() => _ToastContainerState();
}

class _ToastContainerState extends State<_ToastContainer>
    with SingleTickerProviderStateMixin {
  static const Duration _fadeInDuration = Duration(milliseconds: 120);
  static const Duration _fadeOutDuration = Duration(milliseconds: 160);

  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _fadeInDuration,
      reverseDuration: _fadeOutDuration,
    );
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _opacity = curved;
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.08),
      end: Offset.zero,
    ).animate(curved);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        widget.onDismiss();
      }
    });

    _controller.forward();

    final showDuration = widget.duration - _fadeOutDuration;
    _hideTimer = Timer(
      showDuration.isNegative ? Duration.zero : showDuration,
      () {
        if (mounted) {
          _controller.reverse();
        }
      },
    );
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyles = context.appTextStyles;
    final colorScheme = Theme.of(context).colorScheme;
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _opacity,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.95,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.accent.withValues(alpha: 0.6),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.onSurface.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              widget.message,
              style: textStyles.body.copyWith(color: colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
