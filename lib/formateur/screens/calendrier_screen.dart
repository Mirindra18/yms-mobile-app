import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/formateur_model.dart';
import '../../providers/formateur_provider.dart';
import '../../services/api_client.dart';
import '../../services/formateur_service.dart';
import '../widgets/formateur_colors.dart';
import '../widgets/formateur_common.dart';


const _mois = [
  'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
  'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
];
const _jours = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

class CalendrierScreen extends StatefulWidget {
  const CalendrierScreen({super.key});

  @override
  State<CalendrierScreen> createState() => _CalendrierScreenState();
}

class _CalendrierScreenState extends State<CalendrierScreen> {
  bool _loading = true;
  String _error = '';
  List<Seance> _seances = [];
  late DateTime _courante;
  late DateTime _selection;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _courante = DateTime(n.year, n.month, 1);
    _selection = DateTime(n.year, n.month, n.day);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final email = context.read<FormateurProvider>().email;
    final apiClient = context.read<ApiClient>();
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final data = await FormateurService.seances(apiClient, email);
      if (!mounted) return;
      setState(() => _seances = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Impossible de charger les séances : $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _iso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List<Seance> _duJour(DateTime d) {
    final iso = _iso(d);
    return _seances.where((s) => s.date == iso).toList()
      ..sort((a, b) => a.heureDebut.compareTo(b.heureDebut));
  }

  List<Seance> get _duMois => _seances
      .where((s) => s.day.year == _courante.year && s.day.month == _courante.month)
      .toList()
    ..sort((a, b) =>
        '${a.date}${a.heureDebut}'.compareTo('${b.date}${b.heureDebut}'));

  void _changeMois(int delta) => setState(
      () => _courante = DateTime(_courante.year, _courante.month + delta, 1));

  void _aujourdHui() {
    final n = DateTime.now();
    setState(() {
      _courante = DateTime(n.year, n.month, 1);
      _selection = DateTime(n.year, n.month, n.day);
    });
  }

  @override
  Widget build(BuildContext context) {
    final duMois = _duMois;
    return RefreshIndicator(
        color: FormateurColors.gold,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            PageHeader(
              title: 'Emploi du temps',
              badge:
                  '${duMois.length} séance${duMois.length > 1 ? 's' : ''} ce mois',
              subtitle:
                  'Consultez le calendrier détaillé de vos cours et interventions.',
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: _aujourdHui,
                icon: const Icon(Icons.auto_awesome,
                    size: 14, color: FormateurColors.accent),
                label: const Text("Aujourd'hui"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FormateurColors.ink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle:
                      const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const LoadingView('Chargement de votre emploi du temps...')
            else if (_error.isNotEmpty)
              ErrorView(_error, onRetry: _load)
            else ...[
              _monthBar(duMois.length),
              const SizedBox(height: 12),
              _grid(),
              const SizedBox(height: 16),
              _selectedDay(),
              const SizedBox(height: 16),
              _monthList(duMois),
            ],
          ],
        ),
      );
  }

  Widget _monthBar(int count) {
    Widget arrow(IconData icon, VoidCallback onTap) => Material(
          color: FormateurColors.bg,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: FormateurColors.border),
              ),
              child: Icon(icon, size: 20, color: FormateurColors.ink),
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: cardDecoration(),
      child: Row(children: [
        arrow(Icons.chevron_left, () => _changeMois(-1)),
        Expanded(
          child: Column(children: [
            Text('${_mois[_courante.month - 1]} ${_courante.year}',
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: FormateurColors.ink)),
            Text('$count séance${count > 1 ? 's' : ''} programmée${count > 1 ? 's' : ''}',
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: FormateurColors.muted)),
          ]),
        ),
        arrow(Icons.chevron_right, () => _changeMois(1)),
      ]),
    );
  }

  Widget _grid() {
    final premier = (DateTime(_courante.year, _courante.month, 1).weekday + 6) % 7;
    final nbJours = DateTime(_courante.year, _courante.month + 1, 0).day;
    final cells = <int?>[
      for (var i = 0; i < premier; i++) null,
      for (var d = 1; d <= nbJours; d++) d,
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: cardDecoration(),
      child: Column(children: [
        Row(children: [
          for (final j in _jours)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(j.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 10,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w900,
                        color: FormateurColors.gold)),
              ),
            ),
        ]),
        for (var r = 0; r < cells.length ~/ 7; r++)
          Row(children: [
            for (var c = 0; c < 7; c++)
              Expanded(child: _cell(cells[r * 7 + c], now)),
          ]),
      ]),
    );
  }

  Widget _cell(int? jour, DateTime now) {
    if (jour == null) return const SizedBox(height: 48);
    final date = DateTime(_courante.year, _courante.month, jour);
    final nb = _duJour(date).length;
    final estAujourdHui =
        date == DateTime(now.year, now.month, now.day);
    final estSelection = date == _selection;

    return GestureDetector(
      onTap: () => setState(() => _selection = date),
      child: Container(
        height: 48,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: estSelection
              ? FormateurColors.ink
              : (nb > 0 ? FormateurColors.bg : Colors.transparent),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: estAujourdHui && !estSelection
                ? FormateurColors.gold
                : (estSelection ? FormateurColors.goldBorder : Colors.transparent),
            width: estAujourdHui ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$jour',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: estSelection
                        ? FormateurColors.accent
                        : (estAujourdHui ? FormateurColors.gold : FormateurColors.ink))),
            const SizedBox(height: 3),
            if (nb > 0)
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var i = 0; i < nb.clamp(0, 3); i++)
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: estSelection ? FormateurColors.accent : FormateurColors.gold,
                      shape: BoxShape.circle,
                    ),
                  ),
              ])
            else
              const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }

  Widget _selectedDay() {
    final list = _duJour(_selection);
    final titre = toBeginningOfSentenceCase(
        DateFormat('EEEE d MMMM', 'fr_FR').format(_selection));
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titre,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: FormateurColors.ink)),
          const SizedBox(height: 10),
          if (list.isEmpty)
            const Text('Aucune séance ce jour-là.',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: FormateurColors.muted))
          else
            for (var i = 0; i < list.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              SeanceTile(
                dayNumber: list[i].date.split('-').last,
                title: list[i].formationTitre,
                time: '${list[i].debut} - ${list[i].fin}',
              ),
            ],
        ],
      ),
    );
  }

  Widget _monthList(List<Seance> list) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const IconBox(icon: Icons.calendar_month_rounded, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Séances prévues ce mois-ci',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: FormateurColors.ink)),
                  Text('Vos cours de ${_mois[_courante.month - 1]}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: FormateurColors.muted)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 12),
          if (list.isEmpty)
            const EmptyView(
              icon: Icons.menu_book_rounded,
              title: 'Aucune séance ce mois-ci',
              message:
                  "Aucune séance d'enseignement n'a été planifiée pour cette période.",
            )
          else
            for (var i = 0; i < list.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              SeanceTile(
                dayNumber: list[i].date.split('-').last,
                title: list[i].formationTitre,
                time:
                    '${DateFormat('dd/MM/yyyy').format(list[i].day)} • ${list[i].debut} à ${list[i].fin}',
              ),
            ],
        ],
      ),
    );
  }
}
