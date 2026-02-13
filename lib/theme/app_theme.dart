import 'dart:ui';

import 'package:flutter/material.dart';

@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color primaryBlue;
  final Color successGreen;
  final Color warningOrange;
  final Color errorRed;
  final Color lightBlue;
  final Color lightBlueAccent;
  final Color lateColor;
  final Color lateBackgroundColor;
  final Color slightlyLateColor;
  final Color slightlyLateBackgroundColor;
  final Color comingSoonColor;
  final Color comingSoonBackgroundColor;
  final Color onTimeColor;
  final Color onTimeBackgroundColor;
  final Color validateButtonBg;
  final Color validateButtonFg;
  final Color editButtonBg;
  final Color editButtonFg;
  final Color cancelButtonBg;
  final Color cancelButtonFg;
  final Color cartItemTileColor;
  final Color disabledButtonColor;
  final Color holdButtonColor;
  final Color checkoutButtonColor;
  final Color greyText;
  final Color successGreenDark;
  final Map<String, Color> productTypeColors;
  final Map<String, Color> productTypeBackgroundColors;

  const AppThemeColors({
    required this.primaryBlue,
    required this.successGreen,
    required this.warningOrange,
    required this.errorRed,
    required this.lightBlue,
    required this.lightBlueAccent,
    required this.lateColor,
    required this.lateBackgroundColor,
    required this.slightlyLateColor,
    required this.slightlyLateBackgroundColor,
    required this.comingSoonColor,
    required this.comingSoonBackgroundColor,
    required this.onTimeColor,
    required this.onTimeBackgroundColor,
    required this.validateButtonBg,
    required this.validateButtonFg,
    required this.editButtonBg,
    required this.editButtonFg,
    required this.cancelButtonBg,
    required this.cancelButtonFg,
    required this.cartItemTileColor,
    required this.disabledButtonColor,
    required this.holdButtonColor,
    required this.checkoutButtonColor,
    required this.greyText,
    required this.successGreenDark,
    required this.productTypeColors,
    required this.productTypeBackgroundColors,
  });

  Color productTypeColor(String type) {
    return productTypeColors[type] ?? Colors.grey;
  }

  Color productTypeBackgroundColor(String type) {
    return productTypeBackgroundColors[type] ?? Colors.grey.shade100;
  }

  @override
  AppThemeColors copyWith({
    Color? primaryBlue,
    Color? successGreen,
    Color? warningOrange,
    Color? errorRed,
    Color? lightBlue,
    Color? lightBlueAccent,
    Color? lateColor,
    Color? lateBackgroundColor,
    Color? slightlyLateColor,
    Color? slightlyLateBackgroundColor,
    Color? comingSoonColor,
    Color? comingSoonBackgroundColor,
    Color? onTimeColor,
    Color? onTimeBackgroundColor,
    Color? validateButtonBg,
    Color? validateButtonFg,
    Color? editButtonBg,
    Color? editButtonFg,
    Color? cancelButtonBg,
    Color? cancelButtonFg,
    Color? cartItemTileColor,
    Color? disabledButtonColor,
    Color? holdButtonColor,
    Color? checkoutButtonColor,
    Color? greyText,
    Color? successGreenDark,
    Map<String, Color>? productTypeColors,
    Map<String, Color>? productTypeBackgroundColors,
  }) {
    return AppThemeColors(
      primaryBlue: primaryBlue ?? this.primaryBlue,
      successGreen: successGreen ?? this.successGreen,
      warningOrange: warningOrange ?? this.warningOrange,
      errorRed: errorRed ?? this.errorRed,
      lightBlue: lightBlue ?? this.lightBlue,
      lightBlueAccent: lightBlueAccent ?? this.lightBlueAccent,
      lateColor: lateColor ?? this.lateColor,
      lateBackgroundColor: lateBackgroundColor ?? this.lateBackgroundColor,
      slightlyLateColor: slightlyLateColor ?? this.slightlyLateColor,
      slightlyLateBackgroundColor:
          slightlyLateBackgroundColor ?? this.slightlyLateBackgroundColor,
      comingSoonColor: comingSoonColor ?? this.comingSoonColor,
      comingSoonBackgroundColor:
          comingSoonBackgroundColor ?? this.comingSoonBackgroundColor,
      onTimeColor: onTimeColor ?? this.onTimeColor,
      onTimeBackgroundColor: onTimeBackgroundColor ?? this.onTimeBackgroundColor,
      validateButtonBg: validateButtonBg ?? this.validateButtonBg,
      validateButtonFg: validateButtonFg ?? this.validateButtonFg,
      editButtonBg: editButtonBg ?? this.editButtonBg,
      editButtonFg: editButtonFg ?? this.editButtonFg,
      cancelButtonBg: cancelButtonBg ?? this.cancelButtonBg,
      cancelButtonFg: cancelButtonFg ?? this.cancelButtonFg,
      cartItemTileColor: cartItemTileColor ?? this.cartItemTileColor,
      disabledButtonColor: disabledButtonColor ?? this.disabledButtonColor,
      holdButtonColor: holdButtonColor ?? this.holdButtonColor,
      checkoutButtonColor: checkoutButtonColor ?? this.checkoutButtonColor,
      greyText: greyText ?? this.greyText,
      successGreenDark: successGreenDark ?? this.successGreenDark,
      productTypeColors: productTypeColors ?? this.productTypeColors,
      productTypeBackgroundColors:
          productTypeBackgroundColors ?? this.productTypeBackgroundColors,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
      primaryBlue: Color.lerp(primaryBlue, other.primaryBlue, t)!,
      successGreen: Color.lerp(successGreen, other.successGreen, t)!,
      warningOrange: Color.lerp(warningOrange, other.warningOrange, t)!,
      errorRed: Color.lerp(errorRed, other.errorRed, t)!,
      lightBlue: Color.lerp(lightBlue, other.lightBlue, t)!,
      lightBlueAccent:
          Color.lerp(lightBlueAccent, other.lightBlueAccent, t)!,
      lateColor: Color.lerp(lateColor, other.lateColor, t)!,
      lateBackgroundColor:
          Color.lerp(lateBackgroundColor, other.lateBackgroundColor, t)!,
      slightlyLateColor:
          Color.lerp(slightlyLateColor, other.slightlyLateColor, t)!,
      slightlyLateBackgroundColor: Color.lerp(
          slightlyLateBackgroundColor, other.slightlyLateBackgroundColor, t)!,
      comingSoonColor: Color.lerp(comingSoonColor, other.comingSoonColor, t)!,
      comingSoonBackgroundColor: Color.lerp(
          comingSoonBackgroundColor, other.comingSoonBackgroundColor, t)!,
      onTimeColor: Color.lerp(onTimeColor, other.onTimeColor, t)!,
      onTimeBackgroundColor:
          Color.lerp(onTimeBackgroundColor, other.onTimeBackgroundColor, t)!,
      validateButtonBg:
          Color.lerp(validateButtonBg, other.validateButtonBg, t)!,
      validateButtonFg:
          Color.lerp(validateButtonFg, other.validateButtonFg, t)!,
      editButtonBg: Color.lerp(editButtonBg, other.editButtonBg, t)!,
      editButtonFg: Color.lerp(editButtonFg, other.editButtonFg, t)!,
      cancelButtonBg: Color.lerp(cancelButtonBg, other.cancelButtonBg, t)!,
      cancelButtonFg: Color.lerp(cancelButtonFg, other.cancelButtonFg, t)!,
      cartItemTileColor:
          Color.lerp(cartItemTileColor, other.cartItemTileColor, t)!,
      disabledButtonColor:
          Color.lerp(disabledButtonColor, other.disabledButtonColor, t)!,
      holdButtonColor: Color.lerp(holdButtonColor, other.holdButtonColor, t)!,
      checkoutButtonColor:
          Color.lerp(checkoutButtonColor, other.checkoutButtonColor, t)!,
      greyText: Color.lerp(greyText, other.greyText, t)!,
      successGreenDark:
          Color.lerp(successGreenDark, other.successGreenDark, t)!,
      productTypeColors: t < 0.5 ? productTypeColors : other.productTypeColors,
      productTypeBackgroundColors: t < 0.5
          ? productTypeBackgroundColors
          : other.productTypeBackgroundColors,
    );
  }

  static final AppThemeColors light = AppThemeColors(
    primaryBlue: Colors.blue.shade700,
    successGreen: Colors.green.shade600,
    warningOrange: Colors.orange.shade600,
    errorRed: Colors.red.shade600,
    lightBlue: Colors.lightBlue.shade100,
    lightBlueAccent: Colors.lightBlue.shade50,
    lateColor: Colors.red.shade600,
    lateBackgroundColor: Colors.red.shade50,
    slightlyLateColor: Colors.orange.shade700,
    slightlyLateBackgroundColor: Colors.orange.shade50,
    comingSoonColor: Colors.orange.shade600,
    comingSoonBackgroundColor: Colors.orange.shade50,
    onTimeColor: Colors.green.shade600,
    onTimeBackgroundColor: Colors.green.shade50,
    validateButtonBg: Colors.green.shade100,
    validateButtonFg: Colors.green.shade800,
    editButtonBg: Colors.orange.shade100,
    editButtonFg: Colors.orange.shade800,
    cancelButtonBg: Colors.red.shade100,
    cancelButtonFg: Colors.red.shade800,
    cartItemTileColor: Colors.amber.shade100,
    disabledButtonColor: Colors.grey.shade300,
    holdButtonColor: Colors.orange.shade100,
    checkoutButtonColor: Colors.green.shade100,
    greyText: Colors.grey.shade600,
    successGreenDark: Colors.green.shade700,
    productTypeColors: const {
      'Tomate': Colors.red,
      'Crème': Colors.blue,
      'Softs': Colors.amber,
      'Vins': Colors.orange,
      'Spécialités': Colors.green,
      'Glaces': Colors.purple,
      'Desserts': Colors.pink,
    },
    productTypeBackgroundColors: {
      'Tomate': Colors.red.shade100,
      'Crème': Colors.blue.shade100,
      'Softs': Colors.amber.shade100,
      'Vins': Colors.orange.shade100,
      'Spécialités': Colors.green.shade100,
      'Glaces': Colors.purple.shade100,
      'Desserts': Colors.pink.shade100,
    },
  );

  static final AppThemeColors dark = AppThemeColors(
    primaryBlue: Colors.blue.shade300,
    successGreen: Colors.green.shade300,
    warningOrange: Colors.orange.shade300,
    errorRed: Colors.red.shade300,
    lightBlue: const Color(0xFF1F2A36),
    lightBlueAccent: const Color(0xFF15202B),
    lateColor: Colors.red.shade300,
    lateBackgroundColor: const Color(0xFF3A1B1B),
    slightlyLateColor: Colors.orange.shade300,
    slightlyLateBackgroundColor: const Color(0xFF3A2A14),
    comingSoonColor: Colors.orange.shade300,
    comingSoonBackgroundColor: const Color(0xFF3A2A14),
    onTimeColor: Colors.green.shade300,
    onTimeBackgroundColor: const Color(0xFF1E3A28),
    validateButtonBg: const Color(0xFF1E3A28),
    validateButtonFg: Colors.green.shade200,
    editButtonBg: const Color(0xFF3A2A14),
    editButtonFg: Colors.orange.shade200,
    cancelButtonBg: const Color(0xFF3A1B1B),
    cancelButtonFg: Colors.red.shade200,
    cartItemTileColor: const Color(0xFF2B2412),
    disabledButtonColor: Colors.grey.shade800,
    holdButtonColor: const Color(0xFF3A2A14),
    checkoutButtonColor: const Color(0xFF1E3A28),
    greyText: Colors.grey.shade400,
    successGreenDark: Colors.green.shade200,
    productTypeColors: const {
      'Tomate': Colors.red,
      'Crème': Colors.blue,
      'Softs': Colors.amber,
      'Vins': Colors.orange,
      'Spécialités': Colors.green,
      'Glaces': Colors.purple,
      'Desserts': Colors.pink,
    },
    productTypeBackgroundColors: {
      'Tomate': Colors.red.shade900,
      'Crème': Colors.blue.shade900,
      'Softs': Colors.amber.shade900,
      'Vins': Colors.orange.shade900,
      'Spécialités': Colors.green.shade900,
      'Glaces': Colors.purple.shade900,
      'Desserts': Colors.pink.shade900,
    },
  );
}

@immutable
class AppTextStyles extends ThemeExtension<AppTextStyles> {
  final TextStyle title;
  final TextStyle subtitle;
  final TextStyle body;
  final TextStyle caption;
  final TextStyle small;
  final TextStyle large;
  final TextStyle header;
  final TextStyle priceDisplay;
  final TextStyle medium;

  const AppTextStyles({
    required this.title,
    required this.subtitle,
    required this.body,
    required this.caption,
    required this.small,
    required this.large,
    required this.header,
    required this.priceDisplay,
    required this.medium,
  });

  @override
  AppTextStyles copyWith({
    TextStyle? title,
    TextStyle? subtitle,
    TextStyle? body,
    TextStyle? caption,
    TextStyle? small,
    TextStyle? large,
    TextStyle? header,
    TextStyle? priceDisplay,
    TextStyle? medium,
  }) {
    return AppTextStyles(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      body: body ?? this.body,
      caption: caption ?? this.caption,
      small: small ?? this.small,
      large: large ?? this.large,
      header: header ?? this.header,
      priceDisplay: priceDisplay ?? this.priceDisplay,
      medium: medium ?? this.medium,
    );
  }

  @override
  AppTextStyles lerp(ThemeExtension<AppTextStyles>? other, double t) {
    if (other is! AppTextStyles) return this;
    return AppTextStyles(
      title: TextStyle.lerp(title, other.title, t)!,
      subtitle: TextStyle.lerp(subtitle, other.subtitle, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
      small: TextStyle.lerp(small, other.small, t)!,
      large: TextStyle.lerp(large, other.large, t)!,
      header: TextStyle.lerp(header, other.header, t)!,
      priceDisplay: TextStyle.lerp(priceDisplay, other.priceDisplay, t)!,
      medium: TextStyle.lerp(medium, other.medium, t)!,
    );
  }

  static AppTextStyles light(AppThemeColors colors) {
    return AppTextStyles(
      title: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
      subtitle: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
      body: const TextStyle(fontSize: 14.0),
      caption: const TextStyle(fontSize: 12.0),
      small: const TextStyle(fontSize: 11.0),
      large: const TextStyle(fontSize: 18.0),
      header: const TextStyle(fontSize: 26.0, fontWeight: FontWeight.bold),
      priceDisplay: TextStyle(
        fontSize: 18.0,
        fontWeight: FontWeight.bold,
        color: colors.successGreen,
      ),
      medium: const TextStyle(fontSize: 15.0),
    );
  }

  static AppTextStyles dark(AppThemeColors colors) {
    return AppTextStyles(
      title: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
      subtitle: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
      body: const TextStyle(fontSize: 14.0),
      caption: const TextStyle(fontSize: 12.0),
      small: const TextStyle(fontSize: 11.0),
      large: const TextStyle(fontSize: 18.0),
      header: const TextStyle(fontSize: 26.0, fontWeight: FontWeight.bold),
      priceDisplay: TextStyle(
        fontSize: 18.0,
        fontWeight: FontWeight.bold,
        color: colors.successGreen,
      ),
      medium: const TextStyle(fontSize: 15.0),
    );
  }
}

@immutable
class AppLayoutTokens extends ThemeExtension<AppLayoutTokens> {
  final int gridCrossAxisCount;
  final double gridSpacing;
  final double cardElevation;
  final double borderRadius;
  final double dialogBorderRadius;

  const AppLayoutTokens({
    required this.gridCrossAxisCount,
    required this.gridSpacing,
    required this.cardElevation,
    required this.borderRadius,
    required this.dialogBorderRadius,
  });

  @override
  AppLayoutTokens copyWith({
    int? gridCrossAxisCount,
    double? gridSpacing,
    double? cardElevation,
    double? borderRadius,
    double? dialogBorderRadius,
  }) {
    return AppLayoutTokens(
      gridCrossAxisCount: gridCrossAxisCount ?? this.gridCrossAxisCount,
      gridSpacing: gridSpacing ?? this.gridSpacing,
      cardElevation: cardElevation ?? this.cardElevation,
      borderRadius: borderRadius ?? this.borderRadius,
      dialogBorderRadius: dialogBorderRadius ?? this.dialogBorderRadius,
    );
  }

  @override
  AppLayoutTokens lerp(ThemeExtension<AppLayoutTokens>? other, double t) {
    if (other is! AppLayoutTokens) return this;
    return AppLayoutTokens(
      gridCrossAxisCount:
          (lerpDouble(gridCrossAxisCount.toDouble(), other.gridCrossAxisCount.toDouble(), t) ??
                  gridCrossAxisCount.toDouble())
              .round(),
      gridSpacing: lerpDouble(gridSpacing, other.gridSpacing, t) ?? gridSpacing,
      cardElevation: lerpDouble(cardElevation, other.cardElevation, t) ?? cardElevation,
      borderRadius: lerpDouble(borderRadius, other.borderRadius, t) ?? borderRadius,
      dialogBorderRadius:
          lerpDouble(dialogBorderRadius, other.dialogBorderRadius, t) ?? dialogBorderRadius,
    );
  }

  static const AppLayoutTokens defaults = AppLayoutTokens(
    gridCrossAxisCount: 6,
    gridSpacing: 10.0,
    cardElevation: 2.0,
    borderRadius: 8.0,
    dialogBorderRadius: 16.0,
  );
}

class AppTheme {
  static ThemeData light() {
    final colors = AppThemeColors.light;
    final textStyles = AppTextStyles.light(colors);
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.primaryBlue,
        brightness: Brightness.light,
      ),
      textTheme: const TextTheme(),
      extensions: <ThemeExtension<dynamic>>[
        colors,
        textStyles,
        AppLayoutTokens.defaults,
      ],
    );
  }

  static ThemeData dark() {
    final colors = AppThemeColors.dark;
    final textStyles = AppTextStyles.dark(colors);
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.primaryBlue,
        brightness: Brightness.dark,
      ).copyWith(
        surface: const Color(0xFF171A20),
        outline: Colors.grey.shade700,
      ),
      textTheme: const TextTheme(),
    );
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF0F1115),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF171A20),
        foregroundColor: Colors.white,
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF171A20),
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF171A20),
        surfaceTintColor: Colors.transparent,
      ),
      dividerColor: Colors.grey.shade800,
      extensions: <ThemeExtension<dynamic>>[
        colors,
        textStyles,
        AppLayoutTokens.defaults,
      ],
    );
  }
}

extension AppThemeContext on BuildContext {
  AppThemeColors get appColors => Theme.of(this).extension<AppThemeColors>()!;
  AppTextStyles get appTextStyles => Theme.of(this).extension<AppTextStyles>()!;
  AppLayoutTokens get appLayout => Theme.of(this).extension<AppLayoutTokens>()!;
}
