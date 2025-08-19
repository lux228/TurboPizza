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

  // Couleurs système
  static final Color primaryBlue = Colors.blue[700]!;
  static final Color successGreen = Colors.green[600]!;
  static final Color warningOrange = Colors.orange[600]!;
  static final Color errorRed = Colors.red[600]!;
  static final Color lightBlue = Colors.lightBlue[100]!;
  static final Color lightBlueAccent = Colors.lightBlue[50]!;

  // Couleurs d'état des commandes
  static final Color lateColor = Colors.red[600]!;
  static final Color lateBackgroundColor = Colors.red[50]!;
  static final Color slightlyLateColor = Colors.orange[700]!;
  static final Color slightlyLateBackgroundColor = Colors.orange[50]!;
  static final Color comingSoonColor = Colors.orange[600]!;
  static final Color comingSoonBackgroundColor = Colors.orange[50]!;
  static final Color onTimeColor = Colors.green[600]!;
  static final Color onTimeBackgroundColor = Colors.green[50]!;

  // Couleurs des boutons d'action
  static final Color validateButtonBg = Colors.green[100]!;
  static final Color validateButtonFg = Colors.green[800]!;
  static final Color editButtonBg = Colors.orange[100]!;
  static final Color editButtonFg = Colors.orange[800]!;
  static final Color cancelButtonBg = Colors.red[100]!;
  static final Color cancelButtonFg = Colors.red[800]!;

  // Couleurs spécifiques pour les widgets
  static final Color cartItemTileColor = Colors.amber[100]!;
  static final Color disabledButtonColor = Colors.grey[300]!;
  static final Color holdButtonColor = Colors.orange[100]!;
  static final Color checkoutButtonColor = Colors.green[100]!;

  // Couleurs par type de produit pour les backgrounds
  static final Map<String, Color> productTypeBackgroundColors = {
    'Tomate': Colors.red[100]!,
    'Crème': Colors.blue[100]!,
    'Softs': Colors.amber[100]!,
    'Vins': Colors.orange[100]!,
    'Spécialités': Colors.green[100]!,
    'Glaces': Colors.purple[100]!,
    'Desserts': Colors.pink[100]!,
  };

  // Couleurs supplémentaires
  static final Color greyText = Colors.grey[600]!;
  static final Color successGreenDark = Colors.green[700]!;

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
  static const double largeFontSize = 18.0;
  static const double headerFontSize = 26.0;
  static const double priceDisplayFontSize = 18.0;
  static const double mediumFontSize = 15.0;

  // Messages
  static const String emptyCartMessage = "Panier vide";
  static const String noOrdersMessage = "Aucune commande en attente";
  static const String touchForDetailsMessage = "Toucher pour voir le détail";
  static const String orderOnHoldMessage = "Commande mise en attente";
  static const String orderValidatedMessage = "Commande validée et encaissée";
  static const String orderCancelledMessage = "Commande annulée";
  static const String orderBackToCompositionMessage = "Commande remise en composition";
  static const String paymentSuccessMessage = "Encaissement réalisé avec succès";
  static const String productManagementTitle = "Gestion des produits";
  static const String paymentHistoryTitle = "Historique des encaissements";
  static const String noProductsMessage = "Aucun produit disponible.\nUtilisez le bouton + pour en ajouter.";

  // Modes de paiement par défaut
  static const String defaultPaymentMethod = "Espèces";
  static const List<String> paymentMethods = ["Espèces", "Chèque", "Groupe"];

  // Configuration de l'historique
  static const String frenchLocale = 'fr_FR';

  // Clés de stockage (SharedPreferences)
  static const String spKeyPizzas = 'pizzas';
  static const String spKeyPayments = 'encaissements';
  static const String spKeyPendingOrders = 'commandes_attente';
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
