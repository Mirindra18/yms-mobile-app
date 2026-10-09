import 'package:flutter_test/flutter_test.dart';
import 'package:yms_mobile_app/models/formateur_model.dart';

void main() {
  group('Inscription', () {
    test('maps backend formation and learner fields', () {
      final inscription = Inscription.fromJson({
        'id': 21,
        'formationId': 7,
        'formationTitre': 'Comptable Senior',
        'statut': 'VALIDEE',
        'dateInscription': '2026-10-01T10:00:00',
        'userId': 12,
        'userNom': 'Rakoto',
        'userPrenom': 'Miora',
        'userEmail': 'miora@example.com',
      });

      expect(inscription.formationId, 7);
      expect(inscription.userId, 12);
      expect(inscription.formationTitre, 'Comptable Senior');
      expect(inscription.validee, isTrue);
    });
  });

  group('PresenceSession', () {
    test('maps session dates, QR state and open status', () {
      final session = PresenceSession.fromJson({
        'id': 3,
        'formationId': 7,
        'titre': 'Cours de comptabilité',
        'debut': '2026-10-10T09:00:00',
        'fin': '2026-10-10T12:00:00',
        'statut': 'OPEN',
        'qrToken': 'test-token',
        'qrExpireAt': '2026-10-10T09:15:00',
      });

      expect(session.start.hour, 9);
      expect(session.end.hour, 12);
      expect(session.qrToken, 'test-token');
      expect(session.isOpen, isTrue);
    });
  });

  test('maps attendance record and aggregate statistics', () {
    final attendance = PresenceRecord.fromJson({
      'id': 10,
      'participantId': 12,
      'seanceId': 3,
      'statut': 'PRESENT',
      'mode': 'QR',
      'datePresence': '2026-10-10T09:03:00',
      'valideParId': null,
    });
    final stats = PresenceStats.fromJson({
      'total': 4,
      'presents': 3,
      'absents': 1,
      'tauxPresence': 75.0,
    });

    expect(attendance.participantId, 12);
    expect(attendance.mode, 'QR');
    expect(stats.total, 4);
    expect(stats.rate, 75.0);
  });
}
