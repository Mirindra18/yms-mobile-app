import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/formateur_model.dart';
import '../../providers/formateur_provider.dart';
import '../../services/api_client.dart';
import '../../services/formateur_service.dart';
import '../widgets/formateur_colors.dart';
import '../widgets/formateur_common.dart';

class PresenceFormateurScreen extends StatefulWidget {
  const PresenceFormateurScreen({super.key});

  @override
  State<PresenceFormateurScreen> createState() =>
      _PresenceFormateurScreenState();
}

class _PresenceFormateurScreenState extends State<PresenceFormateurScreen> {
  final _titleController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<Formation> _formations = [];
  List<Inscription> _participants = [];
  List<PresenceSession> _sessions = [];
  List<PresenceRecord> _attendance = [];
  PresenceStats? _stats;
  int? _formationId;
  int? _sessionId;
  DateTime _sessionDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 12, minute: 0);

  ApiClient get _api => context.read<ApiClient>();
  PresenceSession? get _selectedSession {
    for (final session in _sessions) {
      if (session.id == _sessionId) return session;
    }
    return null;
  }

  List<Inscription> get _selectedParticipants => _participants
      .where((p) => p.formationId == _formationId && p.validee)
      .toList();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        FormateurService.formations(
          _api,
          context.read<FormateurProvider>().email,
        ),
        FormateurService.participants(_api),
      ]);
      final formations = results[0] as List<Formation>;
      final participants = results[1] as List<Inscription>;
      if (!mounted) return;
      setState(() {
        _formations = formations;
        _participants = participants;
        _formationId ??= formations.isEmpty ? null : formations.first.id;
        _loading = false;
      });
      final id = _formationId;
      if (id != null) await _loadSessions(id);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger vos formations ou participants : $error';
        _loading = false;
      });
    }
  }

  Future<void> _loadSessions(int formationId) async {
    setState(() {
      _loading = true;
      _error = null;
      _sessions = [];
      _sessionId = null;
      _attendance = [];
      _stats = null;
    });
    try {
      final sessions =
          await FormateurService.presenceSessions(_api, formationId);
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _sessionId = sessions.isEmpty ? null : sessions.first.id;
        _loading = false;
      });
      if (_sessionId != null) await _loadAttendance(_sessionId!);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger les séances de présence : $error';
        _loading = false;
      });
    }
  }

  Future<void> _loadAttendance(int sessionId) async {
    try {
      final results = await Future.wait([
        FormateurService.sessionAttendance(_api, sessionId),
        FormateurService.sessionStats(_api, sessionId),
      ]);
      if (!mounted) return;
      setState(() {
        _attendance = results[0] as List<PresenceRecord>;
        _stats = results[1] as PresenceStats;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Impossible de charger le pointage : $error');
    }
  }

  Future<void> _createSession() async {
    final formationId = _formationId;
    final title = _titleController.text.trim();
    if (formationId == null || title.isEmpty) {
      setState(() => _error = 'Choisissez une formation et saisissez un titre.');
      return;
    }
    final start = DateTime(
      _sessionDate.year,
      _sessionDate.month,
      _sessionDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    final end = DateTime(
      _sessionDate.year,
      _sessionDate.month,
      _sessionDate.day,
      _endTime.hour,
      _endTime.minute,
    );
    if (!end.isAfter(start)) {
      setState(() => _error = 'L’heure de fin doit être après l’heure de début.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final created = await FormateurService.createPresenceSession(
        _api,
        formationId,
        title,
        start,
        end,
      );
      _titleController.clear();
      if (!mounted) return;
      setState(() {
        _sessions = [..._sessions, created]
          ..sort((a, b) => a.start.compareTo(b.start));
        _sessionId = created.id;
      });
      await _loadAttendance(created.id);
    } catch (error) {
      if (mounted) setState(() => _error = 'Création de la séance impossible : $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _activateQr() async {
    final session = _selectedSession;
    if (session == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await FormateurService.activateQr(_api, session.id);
      if (!mounted) return;
      setState(() {
        _sessions = _sessions
            .map((item) => item.id == updated.id ? updated : item)
            .toList();
      });
    } catch (error) {
      if (mounted) setState(() => _error = 'Activation du QR impossible : $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _closeSession() async {
    final session = _selectedSession;
    if (session == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated =
          await FormateurService.closePresenceSession(_api, session.id);
      if (!mounted) return;
      setState(() {
        _sessions = _sessions
            .map((item) => item.id == updated.id ? updated : item)
            .toList();
      });
    } catch (error) {
      if (mounted) setState(() => _error = 'Clôture de la séance impossible : $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _manualEntry() async {
    final session = _selectedSession;
    final participants = _selectedParticipants;
    if (session == null || participants.isEmpty) {
      setState(() => _error =
          'Aucun apprenant avec une inscription validée dans cette formation.');
      return;
    }
    int participantId = participants.first.userId;
    String status = 'PRESENT';
    final submitted = await showDialog<(int, String)>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Saisie manuelle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: participantId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Apprenant'),
                items: [
                  for (final participant in participants)
                    DropdownMenuItem(
                      value: participant.userId,
                      child: Text(
                        '${participant.userPrenom} ${participant.userNom}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => participantId = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Statut'),
                items: const [
                  DropdownMenuItem(value: 'PRESENT', child: Text('Présent')),
                  DropdownMenuItem(value: 'ABSENT', child: Text('Absent')),
                  DropdownMenuItem(value: 'LATE', child: Text('En retard')),
                  DropdownMenuItem(value: 'EXCUSED', child: Text('Excusé')),
                ],
                onChanged: (value) {
                  if (value != null) setDialogState(() => status = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, (participantId, status)),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
    if (submitted == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await FormateurService.markPresenceManually(
        _api,
        session.id,
        submitted.$1,
        submitted.$2,
      );
      await _loadAttendance(session.id);
    } catch (error) {
      if (mounted) setState(() => _error = 'Enregistrement impossible : $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _sessionDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (date != null) setState(() => _sessionDate = date);
  }

  Future<void> _pickTime({required bool start}) async {
    final time = await showTimePicker(
      context: context,
      initialTime: start ? _startTime : _endTime,
    );
    if (time != null) {
      setState(() {
        if (start) {
          _startTime = time;
        } else {
          _endTime = time;
        }
      });
    }
  }

  String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  String _personName(int id) {
    for (final participant in _participants) {
      if (participant.userId == id) {
        return '${participant.userPrenom} ${participant.userNom}'.trim();
      }
    }
    return 'Apprenant #$id';
  }

  @override
  Widget build(BuildContext context) {
    final session = _selectedSession;
    return RefreshIndicator(
      color: FormateurColors.gold,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          const PageHeader(
            title: 'Gestion des présences',
            subtitle:
                'Créez une séance, affichez son QR code et suivez le pointage de vos apprenants.',
          ),
          const SizedBox(height: 16),
          if (_error != null) ...[
            ErrorView(_error!, onRetry: _load),
            const SizedBox(height: 12),
          ],
          if (_loading)
            const LoadingView('Chargement de vos formations...')
          else if (_formations.isEmpty)
            const EmptyView(
              icon: Icons.menu_book_rounded,
              title: 'Aucune formation attribuée',
              message:
                  'Les formations affectées à votre compte apparaîtront ici.',
            )
          else ...[
            _formationSelector(),
            const SizedBox(height: 12),
            _createSessionCard(),
            const SizedBox(height: 12),
            if (_sessions.isNotEmpty) _sessionSelector(),
            if (session != null) ...[
              const SizedBox(height: 12),
              _sessionCard(session),
              const SizedBox(height: 12),
              _statsCards(),
              const SizedBox(height: 12),
              _attendanceCard(),
            ] else if (!_loading)
              const EmptyView(
                icon: Icons.event_busy_rounded,
                title: 'Aucune séance de présence',
                message: 'Créez une séance pour commencer le suivi.',
              ),
          ],
          if (_saving) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(color: FormateurColors.gold),
          ],
        ],
      ),
    );
  }

  Widget _formationSelector() => DropdownButtonFormField<int>(
        initialValue: _formationId,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Formation',
          prefixIcon: Icon(Icons.menu_book_rounded),
          filled: true,
          fillColor: Colors.white,
        ),
        items: [
          for (final formation in _formations)
            DropdownMenuItem(
              value: formation.id,
              child: Text(formation.titre, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: _saving
            ? null
            : (value) {
                if (value == null) return;
                setState(() => _formationId = value);
                _loadSessions(value);
              },
      );

  Widget _createSessionCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Planifier une séance',
              style: TextStyle(
                color: FormateurColors.ink,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre de la séance',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _saving ? null : _pickDate,
                  icon: const Icon(Icons.calendar_month),
                  label: Text(DateFormat('dd/MM/yyyy').format(_sessionDate)),
                ),
                OutlinedButton.icon(
                  onPressed: _saving ? null : () => _pickTime(start: true),
                  icon: const Icon(Icons.schedule),
                  label: Text('Début ${_formatTime(_startTime)}'),
                ),
                OutlinedButton.icon(
                  onPressed: _saving ? null : () => _pickTime(start: false),
                  icon: const Icon(Icons.schedule),
                  label: Text('Fin ${_formatTime(_endTime)}'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _createSession,
                icon: const Icon(Icons.add),
                label: const Text('Créer la séance'),
                style: FilledButton.styleFrom(
                  backgroundColor: FormateurColors.ink,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _sessionSelector() => DropdownButtonFormField<int>(
        initialValue: _sessionId,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Séance de présence',
          prefixIcon: Icon(Icons.event_available_rounded),
          filled: true,
          fillColor: Colors.white,
        ),
        items: [
          for (final session in _sessions)
            DropdownMenuItem(
              value: session.id,
              child: Text(
                '${session.title} • ${DateFormat('dd/MM HH:mm').format(session.start)}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: _saving
            ? null
            : (value) {
                if (value == null) return;
                setState(() {
                  _sessionId = value;
                  _attendance = [];
                  _stats = null;
                });
                _loadAttendance(value);
              },
      );

  Widget _sessionCard(PresenceSession session) => Container(
        padding: const EdgeInsets.all(16),
        decoration: cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    session.title,
                    style: const TextStyle(
                      color: FormateurColors.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                StatusBadge(
                  label: session.isOpen ? 'Ouverte' : 'Clôturée',
                  background: session.isOpen
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFFFF1F2),
                  foreground: session.isOpen
                      ? const Color(0xFF047857)
                      : const Color(0xFFBE123C),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(session.start)} • '
              '${DateFormat('HH:mm').format(session.start)} – '
              '${DateFormat('HH:mm').format(session.end)}',
              style: const TextStyle(color: FormateurColors.muted, fontSize: 12),
            ),
            if (session.qrToken != null) ...[
              const SizedBox(height: 14),
              Center(
                child: QrImageView(
                  data: session.qrToken!,
                  size: 190,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: FormateurColors.ink,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: FormateurColors.ink,
                  ),
                ),
              ),
              Center(
                child: Text(
                  session.qrExpireAt == null
                      ? 'QR activé'
                      : 'Valide jusqu’à ${DateFormat('HH:mm').format(session.qrExpireAt!)}',
                  style: const TextStyle(
                    color: FormateurColors.muted,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _saving ? null : _activateQr,
                  icon: const Icon(Icons.qr_code_2_rounded),
                  label: Text(session.qrToken == null
                      ? 'Activer le QR (15 min)'
                      : 'Renouveler le QR'),
                ),
                OutlinedButton.icon(
                  onPressed:
                      _saving || !session.isOpen ? null : _closeSession,
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('Clôturer'),
                ),
                FilledButton.icon(
                  onPressed:
                      _saving || !session.isOpen ? null : _manualEntry,
                  icon: const Icon(Icons.how_to_reg_rounded),
                  label: const Text('Pointage manuel'),
                  style: FilledButton.styleFrom(
                    backgroundColor: FormateurColors.ink,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _statsCards() {
    final stats = _stats;
    final participantCount = _selectedParticipants.length;
    final presentCount = stats?.presents ??
        _attendance.where((record) => record.status == 'PRESENT').length;
    final notCheckedIn = (participantCount - _attendance.length)
        .clamp(0, participantCount);
    final rate = participantCount == 0
        ? 0
        : (presentCount * 100 / participantCount).round();
    return StatGrid(cards: [
      StatCard(
        label: 'Apprenants inscrits',
        value: '$participantCount',
        icon: Icons.groups_rounded,
      ),
      StatCard(
        label: 'Présents',
        value: '$presentCount',
        icon: Icons.how_to_reg_rounded,
        valueColor: const Color(0xFF047857),
      ),
      StatCard(
        label: 'Non pointés',
        value: '$notCheckedIn',
        icon: Icons.pending_actions_rounded,
        valueColor: const Color(0xFFB45309),
      ),
      StatCard(
        label: 'Taux présence',
        value: '$rate%',
        icon: Icons.percent_rounded,
        dark: true,
        valueColor: FormateurColors.gold,
      ),
    ]);
  }

  Widget _attendanceCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Présences enregistrées (${_attendance.length})',
              style: const TextStyle(
                color: FormateurColors.ink,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            if (_attendance.isEmpty)
              const Text(
                'Aucun pointage pour cette séance.',
                style: TextStyle(color: FormateurColors.muted),
              )
            else
              for (final record in _attendance)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: FormateurColors.soft,
                    child: Icon(Icons.person, color: FormateurColors.gold),
                  ),
                  title: Text(_personName(record.participantId)),
                  subtitle: Text(
                    '${record.mode == 'QR' ? 'QR Code' : 'Manuel'} • '
                    '${DateFormat('dd/MM/yyyy HH:mm').format(record.date)}',
                  ),
                  trailing: StatusBadge(
                    label: record.status,
                    background: record.status == 'PRESENT'
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFFFF7ED),
                    foreground: record.status == 'PRESENT'
                        ? const Color(0xFF047857)
                        : const Color(0xFFB45309),
                  ),
                ),
          ],
        ),
      );
}
