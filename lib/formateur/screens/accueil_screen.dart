import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/formateur_model.dart';
import '../../providers/formateur_provider.dart';
import '../../services/api_client.dart';
import '../../services/formateur_service.dart';
import '../widgets/formateur_colors.dart';
import '../widgets/formateur_common.dart';
import '../widgets/formateur_tabs.dart';


/// Remplace l'ancien « Tableau de bord » : c'est maintenant la page d'ACCUEIL.
class AccueilScreen extends StatefulWidget {
  /// Appelé pour changer d'onglet dans le FormateurShell.
  final ValueChanged<int> onNavigate;
  const AccueilScreen({super.key, required this.onNavigate});

  @override
  State<AccueilScreen> createState() => _AccueilScreenState();
}

class _AccueilScreenState extends State<AccueilScreen> {
  bool _loading = true;
  String _error = '';
  List<Formation> _formations = [];
  List<Seance> _seances = [];
  List<Inscription> _participants = [];

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
      final results = await Future.wait([
        FormateurService.formations(apiClient, email),
        FormateurService.seances(apiClient, email),
        FormateurService.participants(apiClient),
      ]);
      if (!mounted) return;
      setState(() {
        _formations = results[0] as List<Formation>;
        _seances = results[1] as List<Seance>;
        _participants = results[2] as List<Inscription>;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Impossible de charger vos données : $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  @override
  Widget build(BuildContext context) {
    final email = context.watch<FormateurProvider>().email;
    final profile = context.watch<FormateurProvider>();
    final nomAffiche = profile.nomComplet.isEmpty
        ? email
        : profile.nomComplet;

    final today = _today;
    final aujourdHui = _seances.where((s) => s.day == today).toList();
    final aVenir = _seances.where((s) => s.day.isAfter(today)).toList()
      ..sort((a, b) => '${a.date}${a.heureDebut}'.compareTo('${b.date}${b.heureDebut}'));
    aujourdHui.sort((a, b) => a.heureDebut.compareTo(b.heureDebut));
    final prochaines = [...aujourdHui, ...aVenir].take(4).toList();
    final formationsActives =
        _formations.where((f) => f.statut == 'EN_COURS').length;
    final recentes = _formations.take(3).toList();

    return RefreshIndicator(
        color: FormateurColors.gold,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _hero(nomAffiche),
            const SizedBox(height: 16),
            if (_loading)
              const LoadingView('Chargement de votre espace...')
            else if (_error.isNotEmpty)
              ErrorView(_error, onRetry: _load)
            else ...[
              StatGrid(cards: [
                StatCard(
                    label: 'Formations actives',
                    value: '$formationsActives',
                    icon: Icons.menu_book_rounded),
                StatCard(
                    label: 'Apprenants inscrits',
                    value: '${_participants.length}',
                    icon: Icons.groups_rounded),
                StatCard(
                    label: "Séances aujourd'hui",
                    value: '${aujourdHui.length}',
                    icon: Icons.event_available_rounded,
                    dark: true),
                StatCard(
                    label: 'Séances à venir',
                    value: '${aVenir.length}',
                    icon: Icons.calendar_month_rounded,
                    valueColor: FormateurColors.gold),
              ]),
              const SizedBox(height: 22),
              _sectionTitle('Accès rapide'),
              const SizedBox(height: 10),
              _quickAccess(context),
              const SizedBox(height: 22),
              _sectionTitle('Prochaines séances',
                  action: 'Calendrier',
                  onAction: () =>
                      widget.onNavigate(FormateurTabs.calendrier)),
              const SizedBox(height: 10),
              if (prochaines.isEmpty)
                const EmptyView(
                    icon: Icons.event_busy_rounded,
                    title: 'Aucune séance à venir',
                    message: "Vous n'avez pas de séance planifiée.")
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: cardDecoration(),
                  child: Column(children: [
                    for (var i = 0; i < prochaines.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      SeanceTile(
                        dayNumber: prochaines[i].date.split('-').last,
                        title: prochaines[i].formationTitre,
                        time:
                            '${DateFormat('EEE d MMM', 'fr_FR').format(prochaines[i].day)} • ${prochaines[i].debut} - ${prochaines[i].fin}',
                        trailing: prochaines[i].day == today
                            ? const StatusBadge(
                                label: "Aujourd'hui",
                                background: FormateurColors.ink,
                                foreground: FormateurColors.accent,
                                border: FormateurColors.goldBorder)
                            : null,
                      ),
                    ],
                  ]),
                ),
              const SizedBox(height: 22),
              _sectionTitle('Mes formations récentes',
                  action: 'Tout voir',
                  onAction: () =>
                      widget.onNavigate(FormateurTabs.formations)),
              const SizedBox(height: 10),
              if (recentes.isEmpty)
                const EmptyView(
                    icon: Icons.menu_book_rounded,
                    title: 'Aucune formation récente',
                    message: 'Aucune formation à afficher pour le moment.')
              else
                for (final f in recentes) _formationRow(f),
            ],
          ],
        ),
      );
  }

  Widget _hero(String nom) {
    final h = DateTime.now().hour;
    final salut = h < 18 ? 'Bonjour' : 'Bonsoir';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [FormateurColors.ink, Color(0xFF4A2C1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            Icon(Icons.auto_awesome, size: 15, color: FormateurColors.accent),
            SizedBox(width: 6),
            Text('ESPACE FORMATEUR',
                style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w900,
                    color: FormateurColors.accent)),
          ]),
          const SizedBox(height: 10),
          Text('$salut $nom',
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
          const SizedBox(height: 4),
          const Text("Vue d'ensemble de vos formations et apprenants",
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFE8DFC8))),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t, {String? action, VoidCallback? onAction}) {
    return Row(children: [
      Expanded(
        child: Text(t,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: FormateurColors.ink)),
      ),
      if (action != null)
        GestureDetector(
          onTap: onAction,
          child: Text(action,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: FormateurColors.gold)),
        ),
    ]);
  }

  Widget _quickAccess(BuildContext context) {
    const items = [
      FormateurTabs.formations,
      FormateurTabs.sessions,
      FormateurTabs.calendrier,
      FormateurTabs.participants,
      FormateurTabs.presence,
      FormateurTabs.elearning,
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.05,
      children: [
        for (final i in items)
          InkWell(
            borderRadius: BorderRadius.circular(kCardRadius),
            onTap: () => widget.onNavigate(i),
            child: Container(
              decoration: cardDecoration(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconBox(icon: FormateurTabs.all[i].icon, size: 40),
                  const SizedBox(height: 8),
                  Text(FormateurTabs.all[i].label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: FormateurColors.ink)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _formationRow(Formation f) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(),
      child: Row(children: [
        IconBox(icon: Icons.menu_book_rounded, dark: true, size: 42),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(f.titre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: FormateurColors.ink)),
              const SizedBox(height: 3),
              Text('${f.categorie} • ${f.dureeHeures}h • ${f.occupees}/${f.capaciteMax} inscrits',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: FormateurColors.muted)),
            ],
          ),
        ),
      ]),
    );
  }
}
