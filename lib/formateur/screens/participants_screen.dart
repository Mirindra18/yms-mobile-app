import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/formateur_model.dart';
import '../../services/api_client.dart';
import '../../services/formateur_service.dart';
import '../widgets/formateur_colors.dart';
import '../widgets/formateur_common.dart';


class ParticipantsScreen extends StatefulWidget {
  const ParticipantsScreen({super.key});

  @override
  State<ParticipantsScreen> createState() => _ParticipantsScreenState();
}

class _ParticipantsScreenState extends State<ParticipantsScreen> {
  static const _toutes = 'TOUTES';

  bool _loading = true;
  String _error = '';
  List<Inscription> _participants = [];
  String _search = '';
  String _formation = _toutes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final data = await FormateurService.participants(
        context.read<ApiClient>(),
      );
      if (!mounted) return;
      setState(() => _participants = data);
    } catch (e) {
      if (!mounted) return;
      setState(() =>
          _error = 'Impossible de charger les participants de vos formations : $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<String> get _formations {
    final set = _participants
        .map((p) => p.formationTitre)
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return set;
  }

  List<Inscription> get _filtered {
    final q = _search.trim().toLowerCase();
    return _participants.where((p) {
      if (_formation != _toutes && p.formationTitre != _formation) return false;
      if (q.isEmpty) return true;
      return p.userNom.toLowerCase().contains(q) ||
          p.userPrenom.toLowerCase().contains(q) ||
          p.userEmail.toLowerCase().contains(q) ||
          p.formationTitre.toLowerCase().contains(q);
    }).toList();
  }

  String _date(String d) {
    if (d.isEmpty) return '-';
    try {
      return DateFormat('dd MMM yyyy', 'fr_FR').format(DateTime.parse(d));
    } catch (_) {
      return d;
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    final valides = _participants.where((p) => p.validee).length;
    return RefreshIndicator(
        color: FormateurColors.gold,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            const PageHeader(
              title: 'Mes Participants',
              subtitle:
                  'Consultez et gérez les apprenants inscrits à vos sessions de formation.',
            ),
            const SizedBox(height: 16),
            StatGrid(cards: [
              StatCard(
                  label: 'Total participants',
                  value: '${_participants.length}',
                  icon: Icons.groups_rounded),
              StatCard(
                  label: 'Mes formations',
                  value: '${_formations.length}',
                  icon: Icons.menu_book_rounded),
              StatCard(
                  label: 'Inscriptions validées',
                  value: '$valides',
                  icon: Icons.how_to_reg_rounded,
                  dark: true,
                  valueColor: FormateurColors.gold),
            ]),
            const SizedBox(height: 16),
            SearchField(
              hint: 'Nom, prénom ou e-mail...',
              onChanged: (v) => setState(() => _search = v),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: FormateurColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _formation,
                  icon: const Icon(Icons.filter_list_rounded,
                      color: FormateurColors.gold),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: FormateurColors.ink),
                  items: [
                    const DropdownMenuItem(
                        value: _toutes, child: Text('Toutes les formations')),
                    for (final f in _formations)
                      DropdownMenuItem(
                          value: f, child: Text(f, overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (v) => setState(() => _formation = v ?? _toutes),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const LoadingView('Chargement des participants...')
            else if (_error.isNotEmpty)
              ErrorView(_error, onRetry: _load)
            else if (list.isEmpty)
              const EmptyView(
                icon: Icons.groups_rounded,
                title: 'Aucun participant trouvé',
                message:
                    'Aucun participant ne correspond à votre recherche ou à la formation sélectionnée.',
              )
            else ...[
              for (final p in list) _card(p),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Affichage de ${list.length} participant${list.length > 1 ? 's' : ''} • Total : ${_participants.length}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: FormateurColors.muted),
                ),
              ),
            ],
          ],
        ),
      );
  }

  Widget _statut(Inscription p) {
    if (p.validee) {
      return StatusBadge(
          label: p.statutLabel,
          background: FormateurColors.ink,
          foreground: FormateurColors.accent,
          border: FormateurColors.goldBorder,
          dot: FormateurColors.accent);
    }
    if (p.annulee) {
      return StatusBadge(
          label: p.statutLabel,
          background: const Color(0xFFFFF1F2),
          foreground: const Color(0xFFBE123C),
          border: const Color(0xFFFECDD3),
          dot: FormateurColors.rose);
    }
    return StatusBadge(
        label: p.statutLabel,
        background: FormateurColors.bg,
        foreground: FormateurColors.gold,
        border: FormateurColors.border,
        dot: FormateurColors.gold);
  }

  Widget _line(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(children: [
        Icon(icon, size: 14, color: FormateurColors.gold),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: FormateurColors.ink)),
        ),
      ]),
    );
  }

  Widget _card(Inscription p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: FormateurColors.bg,
                shape: BoxShape.circle,
                border: Border.all(color: FormateurColors.border),
              ),
              child: Text(p.initiales,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: FormateurColors.gold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${p.userPrenom} ${p.userNom}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: FormateurColors.ink)),
                  Text('ID #${p.userId}',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: FormateurColors.muted)),
                ],
              ),
            ),
            _statut(p),
          ]),
          const SizedBox(height: 6),
          _line(Icons.mail_outline_rounded, p.userEmail),
          _line(Icons.menu_book_rounded, p.formationTitre),
          _line(Icons.calendar_month_rounded, 'Inscrit le ${_date(p.dateInscription)}'),
        ],
      ),
    );
  }
}
