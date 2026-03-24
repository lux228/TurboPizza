class AppStrings {
  static const String emptyCartMessage = "Panier vide";
  static const String noOrdersMessage = "Aucune commande en attente";
  static const String touchForDetailsMessage = "Toucher pour voir le détail";
  static const String orderOnHoldMessage = "Commande mise en attente";
  static const String invalidPickupTimeMessage =
      "Horaire invalide. Merci de sélectionner un créneau valide.";
  static const String emptyOrderItemsMessage =
      "Commande vide. Ajoutez au moins un article.";
  static const String invalidOrderAmountMessage =
      "Montant invalide. Vérifiez la commande.";
  static const String orderValidatedMessage = "Commande validée et encaissée";
  static const String orderCancelledMessage = "Commande annulée";
  static const String orderBackToCompositionMessage =
      "Commande remise en composition";
  static const String orderTimeUpdatedPrefix = "Horaire modifié :";
  static const String paymentSuccessMessage =
      "Encaissement réalisé avec succès";
  static const String productManagementTitle = "Gestion des produits";
  static const String paymentHistoryTitle = "Historique des encaissements";
  static const String paymentDeleteConfirmTitle = "Confirmer la suppression";
  static const String paymentDeleteConfirmMessage =
      "Êtes-vous sûr de vouloir supprimer cette commande ?";
  static const String irreversibleActionMessage =
      "Cette action est irréversible.";
  static const String cancelLabel = "Annuler";
  static const String deleteLabel = "Supprimer";
  static const String closeLabel = "Fermer";
  static const String confirmLabel = "Confirmer";
  static const String validateLabel = "Valider";
  static const String editLabel = "Modifier";
  static const String scheduleLabel = "Horaire";
  static const String choosePaymentMethodTitle = "Choisir le mode de règlement";
  static const String noSlotLabel = "Aucun créneau";
  static const String noSlotsAvailableTodayMessage =
      "Plus de créneaux disponibles aujourd'hui.";
  static const String calculatorTitle = "Calculatrice";
  static const String currentOrderLabel = "Commande en cours :";
  static const String missingIdDeleteMessage =
      "Suppression impossible: identifiant manquant.";
  static const String missingIdUpdateMessage =
      "Modification impossible: identifiant manquant.";
  static const String paymentDeletedMessage = "Commande supprimée avec succès";
  static const String paymentMethodUpdatedMessage =
      "Mode de règlement mis à jour";
  static const String dailyLabel = "Journalier";
  static const String weeklyLabel = "Hebdomadaire";
  static const String monthlyLabel = "Mensuel";
  static const String selectDatePrompt = "Sélectionner la date:";
  static const String selectWeekPrompt = "Sélectionner la semaine:";
  static const String selectMonthPrompt = "Sélectionner le mois:";
  static const String todayLabel = "Aujourd'hui";
  static const String yesterdayLabel = "Hier";
  static const String dayBeforeYesterdayLabel = "Avant-hier";
  static const String noPaymentsForPeriodMessage =
      "Aucun encaissement pour cette periode.";
  static const String amountPrefix = "Montant:";
  static const String modePrefix = "Mode:";
  static const String itemsPrefix = "Articles:";
  static const String editPaymentMethodTooltip =
      "Modifier le mode de règlement";
  static const String viewPaymentDetailsTooltip =
      "Voir le détail de la commande";
  static const String deletePaymentTooltip = "Supprimer cet encaissement";
  static const String checksLabel = "Chèques";
  static const String cashLabel = "Espèces";
  static const String transfersLabel = "Virements";
  static const String amountToReconcileLabel = "À pointer";
  static const String paymentDetailsTitle = "Détail de la commande";
  static const String orderedItemsTitle = "Articles commandés :";
  static const String noItemsForOrderMessage =
      "Aucun article enregistré pour cette commande";
  static const String paymentMethodPrefix = "Mode de règlement :";
  static const String totalAmountPrefix = "Montant total :";
  static const String settingsTitle = "Paramètres";
  static const String exportDbButtonLabel = "Exporter la base SQLite";
  static const String importDbButtonLabel = "Importer une base SQLite (.db)";
  static const String exportCsvButtonLabel =
      "Exporter les encaissements en CSV";
  static const String exportSavedLocationMessage =
      "Exports enregistrés dans votre dossier Téléchargements (sinon dossier support de l'app).";
  static const String themeLabel = "Thème";
  static const String themeDescription = "Choisir clair, sombre ou système";
  static const String themeSystemLabel = "Système";
  static const String themeLightLabel = "Clair";
  static const String themeDarkLabel = "Sombre";
  static const String categoryButtonsSettingsTitle =
      "Boutons catégories (écran principal)";
  static const String categoryButtonsVisibleDescription =
      "Tous les boutons sont visibles (Tomate, Crème, Spécialités, Desserts, Boissons).";
  static const String categoryButtonsHiddenDescription =
      "Tous les boutons sont masqués.";
  static const String orderThresholdsSettingsTitle =
      "Seuils de statut des commandes";
  static const String orderThresholdsSettingsDescription =
      "Valeurs en minutes par rapport à l'heure prévue.";
  static const String thresholdLateLabel = "Retard";
  static const String thresholdSlightlyLateLabel = "Légèrement en retard";
  static const String thresholdOnTimeLabel = "À l'heure";
  static const String thresholdComingSoonLabel = "Bientôt là";
  static const String saveThresholdsButtonLabel = "Sauvegarder les seuils";
  static const String resetThresholdsButtonLabel =
      "Réinitialiser par défaut";
  static const String thresholdsSavedMessage = "Seuils sauvegardés.";
  static const String thresholdsResetMessage =
      "Seuils réinitialisés aux valeurs par défaut.";
  static const String thresholdsInvalidMessage =
      "Ordre invalide: Retard < Légèrement en retard < À l'heure <= Bientôt là.";
  static const String thresholdsInvalidNumberMessage =
      "Veuillez saisir des nombres entiers valides.";
  static const String dbExportSuccessPrefix = "Base exportée vers";
  static const String exportFailedPrefix = "Export échoué:";
  static const String importSuccessMessage =
      "Import réussi et données rechargées.";
  static const String importFailedPrefix = "Import échoué:";
  static const String csvExportSuccessPrefix = "CSV exporté vers";
  static const String appMenuTitle = "Menu";
  static const String salesStatisticsTitle = "Statistiques de vente";
  static const String periodLabel = "Période : ";
  static const String period7DaysLabel = "7 jours";
  static const String period30DaysLabel = "30 jours";
  static const String period90DaysLabel = "90 jours";
  static const String period1YearLabel = "1 an";
  static const String customPeriodLabel = "Personnalisé";
  static const String salesLoadErrorPrefix = "Erreur lors du chargement :";
  static const String noDataForPeriodMessage =
      "Aucune donnée pour cette période";
  static const String noDataMessage = "Aucune donnée";
  static const String totalRevenueLabel = "Chiffre d'affaires total";
  static const String revenueTrendLabel = "Évolution du chiffre d'affaires";
  static const String currentYearLabel = "Cette année";
  static const String previousYearLabel = "N-1";
  static const String topProductsLabel = "Top 5 des produits";
  static const String byQuantityLabel = "Par quantité";
  static const String byRevenueLabel = "Par chiffre d'affaires";
  static const String paymentMethodDistributionLabel =
      "Répartition par méthode de paiement";
  static const String pizzaTypeDistributionLabel =
      "Répartition par type de pizza";
  static const String settingsMenuLabel = "Paramètres";
    static const String enterFullscreenMenuLabel = "Plein écran";
    static const String exitFullscreenMenuLabel = "Quitter le plein écran";
    static const String quitMenuLabel = "Quitter";
  static const String homeWindowTooSmallMessage =
      "Fenetre trop petite. Agrandissez la fenetre pour un affichage correct.";
  static const String calculatorTooltip = "Calculatrice";
  static const String orderPreviewTitle = "Aperçu de la commande";
  static const String appTitle = "TurboPizza";
  static const String pendingOrdersHeader = "COMMANDES EN ATTENTE";
  static const String currentOrderHeader = "COMMANDE EN COURS";
  static const String totalPrefix = "Total:";
  static const String holdLabel = "En attente";
  static const String checkoutLabel = "Encaisser";
  static const String pickupShortPrefix = "Récup:";
  static const String orderStatusLate = "En retard";
  static const String orderStatusSlightlyLate = "Légèrement en retard";
  static const String orderStatusComingSoon = "Bientôt là";
  static const String orderStatusOnTime = "À l'heure";
  static const String editInProgressWarningMessage =
      "Terminez d'abord la modification en cours (mettre en attente ou encaisser).";
  static const String compositionTimePrefix = "Heure de composition :";
  static const String plannedPickupTimePrefix =
      "Heure de récupération prévue :";
  static const String pickupTimePrefix = "Heure de récupération :";
  static const String orderCancellationConfirmTitle = "Confirmer l'annulation";
  static const String orderCancellationConfirmQuestion =
      "Êtes-vous sûr de vouloir annuler cette commande ?";
  static const String noLabel = "Non";
  static const String yesCancelLabel = "Oui, annuler";
  static const String saveLabel = "Sauvegarder";
  static const String addProductTitle = "Ajouter produit";
  static const String editProductTitle = "Modifier produit";
  static const String productNameLabel = "Nom";
  static const String productPriceLabel = "Prix";
  static const String productTypeLabel = "Type";
  static const String deleteProductConfirmMessagePrefix =
      "Êtes-vous sûr de vouloir supprimer";
  static const String productDeletedSuccessSuffix = "supprimé avec succès";
  static const String diagnosticDuplicatesTitle = "Diagnostic doublons";
  static const String duplicateSkippedLabel =
      "Doublons ignores (migration legacy)";
  static const String duplicateRemovedLabel =
      "Doublons supprimes (upgrade base)";
  static const String notAvailableLabel = "n/a";
  static const String errorPrefix = "Erreur:";
  static const String noInfoAvailableMessage = "Aucune information disponible.";
  static const String migrationStatusTitle = "État de la migration";
  static const String migrationCompletedEmojiLabel = "✅ Migration complétée";
  static const String migrationPendingEmojiLabel = "⚠️ Migration en attente";
  static const String retryLabel = "Réessayer";
  static const String legacyDataSectionTitle =
      "Données legacy (SharedPreferences)";
  static const String currentDataSectionTitle = "Données actuelles (SQLite)";
  static const String productsPrefix = "Produits:";
  static const String paymentsPrefix = "Paiements:";
  static const String ordersPrefix = "Commandes:";
  static const String migrationCompletedLabel = "Migration complétée";
  static const String migrationNotCompletedLabel = "Migration non effectuée";
  static const String datePrefix = "Date:";
  static const String migratedCountsSuffix = "commandes migrées";
  static const String productsWord = "produits";
  static const String paymentsWord = "paiements";
  static const String weekOfPrefix = "Semaine du";
  static const String toDateConnector = "au";
  static const String revenuePreviousYearPrefix = "CA N-1";
  static const String revenuePreviousWeekPrefix = "CA semaine N-1";
  static const String revenuePrefix = "CA";
  static const String forceMigrationLabel = "Forcer la migration";
  static const String cleanLegacyDataLabel = "Nettoyer les données legacy";
  static const String refreshLabel = "Actualiser";
  static const String migrateLabel = "Migrer";
  static const String forceMigrationContent =
      "Cette action va migrer les données de SharedPreferences vers SQLite. Continuer ?";
  static const String forceMigrationSuccessPrefix = "Migration réussie:";
  static const String forceMigrationSkippedMessage =
      "Migration ignorée (déjà effectuée)";
  static const String cleanLegacyDataContent =
      "Cette action va supprimer définitivement les données stockées dans SharedPreferences. Assurez-vous que la migration est complète.\n\nCette action est irréversible !";
  static const String legacyDataDeletedMessage = "Données legacy supprimées";
  static const String previousDayTooltip = "Jour précédent";
  static const String previousWeekTooltip = "Semaine précédente";
  static const String previousMonthTooltip = "Mois précédent";
  static const String nextDayTooltip = "Jour suivant";
  static const String nextWeekTooltip = "Semaine suivante";
  static const String nextMonthTooltip = "Mois suivant";
  static const String noProductsMessage =
      "Aucun produit disponible.\nUtilisez le bouton + pour en ajouter.";
}
