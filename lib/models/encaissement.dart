import 'pizza.dart';

class Encaissement {
  DateTime date;
  double montant;
  String modeReglement;
  List<Pizza> articles;
  bool isSelected;

  Encaissement({
    required this.date,
    required this.montant,
    required this.modeReglement,
    this.articles = const [],
    this.isSelected = false,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'montant': montant,
        'modeReglement': modeReglement,
        'articles': articles.map((pizza) => pizza.toJson()).toList(),
      };

  static Encaissement fromJson(Map<String, dynamic> json) => Encaissement(
        date: DateTime.parse(json['date']),
        montant: json['montant'],
        modeReglement: json['modeReglement'],
        articles: json['articles'] != null
            ? (json['articles'] as List).map((item) => Pizza.fromJson(item)).toList()
            : [],
      );
}
