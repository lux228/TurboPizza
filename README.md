# TurboPizza

Un petit projet Flutter pour gérer les commandes et encaissements d'une pizzeria.

## Description

TurboPizza est une application de caisse pour pizzeria développée en Flutter. Elle permet de :

- Gérer un catalogue de produits par catégories
- Prendre des commandes
- Enregistrer les encaissements avec détail des articles
- Consulter l'historique des ventes
- Calculer le rendu de monnaie

## Fonctionnalités principales

**Écran de caisse**
- Catalogue par catégories avec codes couleur
- Panier avec gestion des quantités
- Modes de paiement : Espèces, Chèques, Groupe
- Calculatrice intégrée

**Gestion des produits**
- Ajouter/modifier/supprimer des produits
- Définir prix et catégories

**Historique**
- Ventes par date
- Détail des commandes passées
- Suppression avec confirmation

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
    ├── payment_method_dialog.dart     # Dialog de sélection du paiement
    └── calculator_dialog.dart         # Calculatrice intégrée
```

## Comment ça marche

1. Sélectionnez les produits sur l'écran principal
2. Ajustez les quantités dans le panier
3. Choisissez le mode de paiement et validez
4. Gérez le catalogue via "Gestion des produits"
5. Consultez l'historique via "Historique des Encaissements"

## Notes techniques

- Stockage local (SharedPreferences)
- Modes de paiement : Espèces, Chèques, Groupe
- Calcul automatique du rendu de monnaie
- Sauvegarde des commandes avec détail des articles

---

*Petit projet personnel fait rapidement pour les besoins d'une pizzeria*
