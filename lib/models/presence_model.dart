// Modèle du module Présences.
// Aligné sur le DTO Java : PresenceResponse.
import 'package:flutter/material.dart';

class PresenceEntry {
  final int id;
  final int participantId;
  final int seanceId;
  final String statut; // PRESENT | ABSENT | LATE | EXCUSED
  final String mode; // QR | MANUAL
  final DateTime? datePresence;
  final int? valideParId;

  const PresenceEntry({
    required this.id,
    this.participantId = 0,
    this.seanceId = 0,
    this.statut = 'ABSENT',
    this.mode = 'QR',
    this.datePresence,
    this.valideParId,
  });

  factory PresenceEntry.fromJson(Map<String, dynamic> json) => PresenceEntry(
        id: (json['id'] as num?)?.toInt() ?? 0,
        participantId: (json['participantId'] as num?)?.toInt() ?? 0,
        seanceId: (json['seanceId'] as num?)?.toInt() ?? 0,
        statut: (json['statut'] as String?) ?? 'ABSENT',
        mode: (json['mode'] as String?) ?? 'QR',
        datePresence: _tryDate(json['datePresence']),
        valideParId: (json['valideParId'] as num?)?.toInt(),
      );

  bool get estPresent => statut == 'PRESENT' || statut == 'LATE';

  String get statutLabel => switch (statut) {
        'PRESENT' => 'Présent',
        'ABSENT' => 'Absent',
        'LATE' => 'En retard',
        'EXCUSED' => 'Excusé',
        _ => statut,
      };

  Color get color => switch (statut) {
        'PRESENT' => const Color(0xFF3E7C5A),
        'LATE' => const Color(0xFFB4892A),
        'EXCUSED' => const Color(0xFF8C7B6B),
        _ => const Color(0xFFB0483C),
      };

  static DateTime? _tryDate(Object? value) =>
      value == null ? null : DateTime.tryParse(value.toString());
}

/// Calcul utils pour l'assiduité.
class PresenceStats {
  /// Taux d'assiduité (0..100) ou null si aucune séance.
  static double? taux(List<PresenceEntry> entries) {
    if (entries.isEmpty) return null;
    final presents = entries.where((e) => e.estPresent).length;
    return (presents / entries.length) * 100;
  }

  static int presents(List<PresenceEntry> entries) =>
      entries.where((e) => e.estPresent).length;
}