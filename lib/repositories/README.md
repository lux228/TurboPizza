# Repositories

Ce dossier contient les repositories qui gèrent l'accès aux données dans la base de données SQLite.

## Architecture

L'architecture suit le pattern Repository pour séparer la logique d'accès aux données de la logique métier :

```
┌─────────────────┐
│   UI/Widgets    │
└────────┬────────┘
         │
┌────────▼────────┐
│    Services     │  (cart_service, order_service, etc.)
└────────┬────────┘
         │
┌────────▼────────────┐
│  StorageService     │  (Couche d'abstraction optionnelle)
└────────┬────────────┘
         │
┌────────▼─────────────────────────────────────────┐
│         DatabaseService (singleton)              │
│  ┌──────────────┬──────────────┬───────────────┐│
│  │   Products   │   Payments   │ PendingOrders ││
│  │  Repository  │  Repository  │  Repository   ││
│  └──────────────┴──────────────┴───────────────┘│
└──────────────────────┬───────────────────────────┘
                       │
                ┌──────▼──────┐
                │SQLite DB    │
                └─────────────┘
```

## Repositories disponibles

### ProductRepository
Gère les produits (pizzas, boissons, etc.) :
- `fetchProducts()` - Récupère tous les produits
- `replaceProducts()` - Remplace tous les produits
- `insertProduct()` - Insère un nouveau produit
- `updateProduct()` - Met à jour un produit existant
- `deleteProduct()` - Supprime un produit
- `deactivateProduct()` - Désactive un produit sans le supprimer

### PaymentRepository
Gère les paiements et leur historique :
- `fetchPayments()` - Récupère tous les paiements
- `fetchPaymentsBetween()` - Récupère les paiements dans une période
- `insertPayment()` - Enregistre un nouveau paiement
- `replacePayments()` - Remplace tous les paiements (pour import)
- `deletePayment()` - Supprime un paiement

### PendingOrderRepository
Gère les commandes en attente :
- `fetchPendingOrders()` - Récupère toutes les commandes en attente
- `fetchPendingOrderById()` - Récupère une commande spécifique
- `savePendingOrder()` - Crée ou met à jour une commande
- `removePendingOrder()` - Supprime une commande
- `replacePendingOrders()` - Remplace toutes les commandes (pour import)

## Utilisation

### Accès direct via DatabaseService

```dart
// Initialiser la base de données
await DatabaseService.instance.init();

// Accéder aux repositories
final products = await DatabaseService.instance.products.fetchProducts();
final payments = await DatabaseService.instance.payments.fetchPayments();
final orders = await DatabaseService.instance.pendingOrders.fetchPendingOrders();
```

### Accès via StorageService (compatibilité)

```dart
// Ancienne méthode (toujours supportée)
final products = await StorageService.loadPizzaList();
final payments = await StorageService.loadPayments();
```

## Migration

La logique de migration depuis SharedPreferences a été extraite dans `MigrationService`.
Elle s'exécute automatiquement au premier lancement après la mise à jour.

## Avantages de cette architecture

1. **Séparation des responsabilités** : Chaque repository gère un seul type d'entité
2. **Testabilité** : Les repositories peuvent être mockés facilement pour les tests
3. **Maintenabilité** : Code plus petit et plus facile à comprendre
4. **Réutilisabilité** : Les repositories peuvent être utilisés dans différents contextes
5. **Documentation** : Chaque méthode est documentée avec des commentaires DDartDoc
