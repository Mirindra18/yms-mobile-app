// Modèles du module Finance (écolage / échéances / paiements).
// Alignés sur les DTO Java : EcolageResponse, EcheanceResponse,
// PaiementResponse.

const _monthsFr = [
  'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
  'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
];

String _two(int v) => v.toString().padLeft(2, '0');

class EcheanceModel {
  final int id;
  final DateTime? moisConcerne;
  final double montant;
  final DateTime? dateLimite;
  final String statut;

  const EcheanceModel({
    required this.id,
    this.moisConcerne,
    this.montant = 0,
    this.dateLimite,
    this.statut = 'EN_ATTENTE',
  });

  factory EcheanceModel.fromJson(Map<String, dynamic> json) => EcheanceModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        moisConcerne: _tryDate(json['moisConcerne']),
        montant: (json['montant'] as num?)?.toDouble() ?? 0,
        dateLimite: _tryDate(json['dateLimite']),
        statut: (json['statut'] as String?) ?? 'EN_ATTENTE',
      );

  bool get isPayee => statut == 'PAYEE';
  bool get isEnAttente => statut == 'EN_ATTENTE';
  bool get isEnRetard => statut == 'EN_RETARD';
  bool get payableNow => isEnAttente || isEnRetard;

  String get moisLabel {
    final d = moisConcerne;
    if (d == null) return 'Échéance';
    return '${_monthsFr[d.month - 1]} ${d.year}';
  }

  String get moisCourt {
    final d = moisConcerne;
    if (d == null) return '—';
    return '${_monthsFr[d.month - 1].substring(0, 3)}. ${d.year}';
  }

  String get statutLabel => switch (statut) {
        'PAYEE' => 'Payée',
        'EN_ATTENTE' => 'En attente',
        'EN_RETARD' => 'En retard',
        _ => statut,
      };

  static DateTime? _tryDate(Object? value) =>
      value == null ? null : DateTime.tryParse(value.toString());
}

class EcolageModel {
  final int id;
  final String apprenantEmail;
  final int formationId;
  final double montantTotal;
  final double soldeDu;
  final List<EcheanceModel> echeances;

  const EcolageModel({
    required this.id,
    this.apprenantEmail = '',
    this.formationId = 0,
    this.montantTotal = 0,
    this.soldeDu = 0,
    this.echeances = const [],
  });

  factory EcolageModel.fromJson(Map<String, dynamic> json) => EcolageModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        apprenantEmail: (json['apprenantEmail'] as String?) ?? '',
        formationId: (json['formationId'] as num?)?.toInt() ?? 0,
        montantTotal: (json['montantTotal'] as num?)?.toDouble() ?? 0,
        soldeDu: (json['soldeDu'] as num?)?.toDouble() ?? 0,
        echeances: ((json['echeances'] as List<dynamic>?) ?? const [])
            .map((e) => EcheanceModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  bool get estSolder => soldeDu <= 0;

  List<EcheanceModel> get echeancesAPayer =>
      echeances.where((e) => e.payableNow).toList();
}

class PaiementModel {
  final int id;
  final int echeanceId;
  final double montant;
  final String modePaiement;
  final String statut;
  final String? numeroRecu;
  final DateTime? createdAt;

  const PaiementModel({
    required this.id,
    this.echeanceId = 0,
    this.montant = 0,
    this.modePaiement = '',
    this.statut = 'EN_ATTENTE',
    this.numeroRecu,
    this.createdAt,
  });

  factory PaiementModel.fromJson(Map<String, dynamic> json) => PaiementModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        echeanceId: (json['echeanceId'] as num?)?.toInt() ?? 0,
        montant: (json['montant'] as num?)?.toDouble() ?? 0,
        modePaiement: (json['modePaiement'] as String?) ?? '',
        statut: (json['statut'] as String?) ?? 'EN_ATTENTE',
        numeroRecu: json['numeroRecu'] as String?,
        createdAt: _tryDate(json['createdAt']),
      );

  String get montantAr =>
      '${montant.round().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} Ar';

  static DateTime? _tryDate(Object? value) =>
      value == null ? null : DateTime.tryParse(value.toString());
}

/// Formatage de date courte partagé (reprend le style de la maquette).
String shortDate(DateTime d) =>
    '${_two(d.day)}/${_two(d.month)}/${d.year}';