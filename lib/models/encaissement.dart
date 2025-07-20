class Encaissement {
  DateTime date;
  double montant;
  String modeReglement;
  String commentaire;
  bool isSelected;

  Encaissement({
    required this.date,
    required this.montant,
    required this.modeReglement,
    this.commentaire = '',
    this.isSelected = false,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'montant': montant,
        'modeReglement': modeReglement,
      };

  static Encaissement fromJson(Map<String, dynamic> json) => Encaissement(
        date: DateTime.parse(json['date']),
        montant: json['montant'],
        modeReglement: json['modeReglement'],
      );
}
