import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/formateur_model.dart';
import '../../providers/formateur_provider.dart';
import '../../services/api_client.dart';
import '../../services/formateur_service.dart';
import '../widgets/formateur_colors.dart';
import '../widgets/formateur_common.dart';


enum _Statut { aujourdHui, aVenir, terminee }

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  bool _loading = true;
  String _error = '';
  List<Seance> _seances = [];
  String _search = '';
  _Statut? _filter; // null = toutes

  @override
  void initState() {
    super.initState();
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
      setState(() => _error = 'Impossible de charger vos séances planifiées : $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  _Statut _statut(Seance s) {
    final n = DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    if (s.day == today) return _Statut.aujourdHui;
    if (s.day.isAfter(today)) return _Statut.aVenir;
    return _Statut.terminee;
  }

  int _count(_Statut st) => _seances.where((s) => _statut(s) == st).length;

  List<Seance> get _filtered {
    final q = _search.trim().toLowerCase();
    final list = _seances.where((s) {
      if (_filter != null && _statut(s) != _filter) return false;
      if (q.isEmpty) return true;
      return s.formationTitre.toLowerCase().contains(q) || s.date.contains(q);
    }).toList()
      ..sort((a, b) =>
          '${a.date}T${a.heureDebut}'.compareTo('${b.date}T${b.heureDebut}'));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final email = context.watch<FormateurProvider>().email;
    final list = _filtered;
    return RefreshIndicator(
        color: FormateurColors.gold,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            const PageHeader(
              title: 'Mes Sessions',
              subtitle:
                  'Retrouvez l\'ensemble de vos séances de formation programmées.',
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: cardDecoration(),
              child: Row(children: [
                const IconBox(icon: Icons.event_available_rounded),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('COMPTE FORMATEUR',
                          style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w800,
                              color: FormateurColors.muted)),
                      Text(email,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: FormateurColors.ink)),
                    ],
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            StatGrid(cards: [
              StatCard(
                  label: 'Total sessions',
                  value: '${_seances.length}',
                  icon: Icons.calendar_month_rounded),
              StatCard(
                  label: 'À venir',
                  value: '${_count(_Statut.aVenir)}',
                  icon: Icons.schedule,
                  valueColor: FormateurColors.gold),
              StatCard(
                  label: "Aujourd'hui",
                  value: '${_count(_Statut.aujourdHui)}',
                  icon: Icons.event_available_rounded,
                  dark: true),
              StatCard(
                  label: 'Terminées',
                  value: '${_count(_Statut.terminee)}',
                  icon: Icons.menu_book_rounded,
                  valueColor: FormateurColors.muted),
            ]),
            const SizedBox(height: 16),
            SearchField(
              hint: 'Rechercher par formation ou date...',
              onChanged: (v) => setState(() => _search = v),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _chip('Toutes', null),
                _chip('À venir', _Statut.aVenir),
                _chip("Aujourd'hui", _Statut.aujourdHui),
                _chip('Terminées', _Statut.terminee),
              ]),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const LoadingView('Chargement de vos sessions...')
            else if (_error.isNotEmpty)
              ErrorView(_error, onRetry: _load)
            else if (list.isEmpty)
              const EmptyView(
                icon: Icons.calendar_month_rounded,
                title: 'Aucune session trouvée',
                message:
                    'Aucune séance planifiée ne correspond à votre recherche ou au filtre sélectionné.',
              )
            else
              for (final s in list) _card(s),
          ],
        ),
      );
  }

  Widget _chip(String label, _Statut? value) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _filter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? FormateurColors.ink : FormateurColors.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? FormateurColors.goldBorder : FormateurColors.border),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: selected ? FormateurColors.accent : FormateurColors.muted)),
        ),
      ),
    );
  }

  Widget _badge(_Statut st) {
    switch (st) {
      case _Statut.aujourdHui:
        return const StatusBadge(
            label: "Aujourd'hui",
            background: FormateurColors.ink,
            foreground: FormateurColors.accent,
            border: FormateurColors.goldBorder,
            dot: FormateurColors.accent);
      case _Statut.aVenir:
        return const StatusBadge(
            label: 'À venir',
            background: FormateurColors.bg,
            foreground: FormateurColors.gold,
            border: FormateurColors.border,
            dot: FormateurColors.gold);
      case _Statut.terminee:
        return const StatusBadge(
            label: 'Terminée',
            background: FormateurColors.soft,
            foreground: FormateurColors.muted,
            dot: FormateurColors.muted);
    }
  }

  Widget _info(IconData icon, String label, String value) {
    return Row(children: [
      IconBox(icon: icon, size: 34),
      const SizedBox(width: 10),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: const TextStyle(
                  fontSize: 9,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w800,
                  color: FormateurColors.muted)),
          Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: FormateurColors.ink)),
        ],
      ),
    ]);
  }

  Widget _card(Seance s) {
    final st = _statut(s);
    final long = toBeginningOfSentenceCase(
        DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(s.day));
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const IconBox(icon: Icons.menu_book_rounded, size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      s.formationTitre.isEmpty
                          ? 'Formation sans titre'
                          : s.formationTitre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: FormateurColors.ink)),
                  const SizedBox(height: 2),
                  Text('Séance n°${s.id}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: FormateurColors.muted)),
                ],
              ),
            ),
          ]),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: FormateurColors.soft),
          ),
          _info(Icons.calendar_month_rounded, 'Date', long),
          const SizedBox(height: 10),
          _info(Icons.schedule, 'Horaire', '${s.debut}  →  ${s.fin}'),
          const SizedBox(height: 12),
          _badge(st),
        ],
      ),
    );
  }
}
