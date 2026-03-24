# TurboPizza

[![CI/CD](https://github.com/lux228/TurboPizza/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/lux228/TurboPizza/actions/workflows/ci-cd.yml)
[![CI/CD (dev)](https://github.com/lux228/TurboPizza/actions/workflows/ci-cd.yml/badge.svg?branch=dev)](https://github.com/lux228/TurboPizza/actions/workflows/ci-cd.yml?query=branch%3Adev)

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

## Lancer le projet

```bash
git clone https://github.com/lux228/TurboPizza.git
cd TurboPizza
flutter pub get
flutter run
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
