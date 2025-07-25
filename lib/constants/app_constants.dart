import 'package:flutter/material.dart';

class AppConstants {
  // Couleurs par type de produit
  static const Map<String, Color> productTypeColors = {
    'Tomate': Colors.red,
    'Crème': Colors.blue,
    'Softs': Colors.amber,
    'Vins': Colors.orange,
    'Spécialités': Colors.green,
    'Glaces': Colors.purple,
    'Desserts': Colors.pink,
  };

  // Ordre d'affichage des catégories
  static const List<String> categoryOrder = [
    'Tomate',
    'Crème', 
    'Spécialités',
    'Softs',
    'Vins',
    'Desserts',
    'Glaces'
  ];

  // Durées et seuils
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration statusUpdateInterval = Duration(minutes: 1);
  static const Duration snackBarDuration = Duration(seconds: 2);
  
  // Seuils pour les statuts de commande (en minutes)
  static const int lateThreshold = -10;
  static const int slightlyLateThreshold = 0;
  static const int comingSoonThreshold = 15;

  // Tailles de grille et espacement
  static const int gridCrossAxisCount = 6;
  static const double gridSpacing = 10.0;
  static const double cardElevation = 2.0;
  static const double borderRadius = 8.0;
  static const double dialogBorderRadius = 16.0;

  // Tailles de police
  static const double titleFontSize = 20.0;
  static const double subtitleFontSize = 16.0;
  static const double bodyFontSize = 14.0;
  static const double captionFontSize = 12.0;
  static const double smallFontSize = 11.0;

  // Messages
  static const String emptyCartMessage = "Panier vide";
  static const String noOrdersMessage = "Aucune commande en attente";
  static const String touchForDetailsMessage = "Toucher pour voir le détail";
  static const String orderOnHoldMessage = "Commande mise en attente";
  static const String orderValidatedMessage = "Commande validée et encaissée";
  static const String orderCancelledMessage = "Commande annulée";
  static const String orderBackToCompositionMessage = "Commande remise en composition";
  static const String paymentSuccessMessage = "Encaissement réalisé avec succès";

  // Modes de paiement par défaut
  static const String defaultPaymentMethod = "Espèces";
  static const List<String> paymentMethods = ["Espèces", "Chèque", "Groupe"];

  // Configuration de l'historique
  static const String frenchLocale = 'fr_FR';
}

class AppStyles {
  static const TextStyle titleStyle = TextStyle(
    fontSize: AppConstants.titleFontSize,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: AppConstants.subtitleFontSize,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: AppConstants.bodyFontSize,
  );

  static const TextStyle captionStyle = TextStyle(
    fontSize: AppConstants.captionFontSize,
  );

  static const TextStyle priceStyle = TextStyle(
    fontSize: AppConstants.subtitleFontSize,
    fontWeight: FontWeight.bold,
    color: Colors.green,
  );

  static BoxDecoration cardDecoration(Color backgroundColor, Color borderColor) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      border: Border.all(color: borderColor, width: 2),
    );
  }

  static BoxDecoration dialogDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(AppConstants.dialogBorderRadius),
      color: Colors.white,
    );
  }
}
