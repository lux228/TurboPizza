# TurboPizza

Un petit projet Flutter pour gérer les commandes et encaissements d'une pizzeria.

## Description

TurboPizza est une simple application de caisse développée pour faciliter la gestion quotidienne d'une pizzeria. Elle permet de :

- Gérer le catalogue de pizzas avec leurs prix
- Prendre des commandes avec un panier simple
- Enregistrer les encaissements selon le mode de paiement
- Consulter l'historique des ventes par date
- Calculer le rendu de monnaie automatiquement

## Fonctionnalités principales

**Écran de caisse**
- Liste des pizzas par type (tomate, crème, mois)
- Panier avec ajout/suppression d'articles
- Choix du mode de paiement
- Calcul du total et du rendu de monnaie

**Gestion des pizzas**
- Ajouter/modifier/supprimer des pizzas
- Définir les prix

**Historique**
- Voir les ventes par jour
- Totaux par mode de paiement
- Supprimer des encaissements

## Tech

- Flutter & Dart
- SharedPreferences (stockage local)
- Package intl (formatage des prix)

## Prérequis

- Flutter SDK (>=3.2.3 <4.0.0)
- Dart SDK
- Un émulateur Android/iOS ou un appareil physique

## Lancer le projet

```bash
git clone https://github.com/lux228/TurboPizza.git
cd TurboPizza
flutter pub get
flutter run
```

## Organisation du code

```
lib/
├── main.dart                          # Point d'entrée de l'application
├── models/                            # Modèles de données
│   ├── pizza.dart                     # Modèle Pizza
│   └── encaissement.dart              # Modèle Encaissement
├── pages/                             # Écrans de l'application
│   ├── pizza_home_page.dart           # Écran principal (caisse)
│   ├── pizza_management_page.dart     # Gestion des pizzas
│   └── encaissement_history_page.dart # Historique des encaissements
├── utils/                             # Utilitaires
│   ├── format_utils.dart              # Formatage des prix
│   └── storage_service.dart           # Service de stockage local
└── widgets/                           # Composants réutilisables
    └── payment_method_dialog.dart     # Dialog de sélection du paiement
```

## Comment ça marche

1. Sélectionnez les pizzas sur l'écran principal
2. Choisissez le mode de paiement
3. Validez → l'encaissement est enregistré
4. Gérez le catalogue via "Gérer les pizzas"
5. Consultez l'historique via "Historique"

## Notes techniques

- Données stockées en local (SharedPreferences)
- Modes de paiement : Espèces, Chèques, Groupe
- Calcul automatique du rendu de monnaie pour les espèces

---

*Petit projet personnel fait rapidement pour les besoins d'une pizzeria*
