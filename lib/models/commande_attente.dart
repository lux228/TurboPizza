import 'pizza.dart';

class CommandeAttente {
  String id;
  DateTime heureComposition;
  String heureRecuperationPrevue; // Format HH:mm
  List<Pizza> articles;
  double montant;

  CommandeAttente({
    required this.id,
    required this.heureComposition,
    required this.heureRecuperationPrevue,
    required this.articles,
    required this.montant,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'heureComposition': heureComposition.toIso8601String(),
        'heureRecuperationPrevue': heureRecuperationPrevue,
        'articles': articles.map((pizza) => pizza.toJson()).toList(),
        'montant': montant,
      };

  static CommandeAttente fromJson(Map<String, dynamic> json) => CommandeAttente(
        id: json['id'],
        heureComposition: DateTime.parse(json['heureComposition']),
        heureRecuperationPrevue: json['heureRecuperationPrevue'],
        articles: (json['articles'] as List)
            .map((item) => Pizza.fromJson(item))
            .toList(),
        montant: json['montant'],
      );

  // Helper pour obtenir l'heure de récupération sous forme de DateTime pour le tri
  DateTime get heureRecuperationDateTime {
    final parts = heureRecuperationPrevue.split(':');
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }
}
