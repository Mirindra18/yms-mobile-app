import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/formation_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/formation_provider.dart';

String _fmtDate(DateTime? d) {
  if (d == null) return '—';
  return '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
}

int _inscrits(FormationModel f) {
  final n = f.capaciteMax - f.placesRestantes;
  return n < 0 ? 0 : n;
}

class HomeFormateurScreen extends StatelessWidget {
  final ValueChanged<int> onNavigate;

  const HomeFormateurScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final formationProvider = context.watch<FormationProvider>();

    final prenom = user?.prenom ?? 'Formateur';
    final nom = user?.nom ?? '';
    final email = (user?.email ?? '').toLowerCase();

    // Uniquement les programmes de ce formateur (hors annulés)
    final mesFormations = email.isEmpty
        ? <FormationModel>[]
        : formationProvider.formations
            .where((f) =>
                (f.formateurEmail ?? '').toLowerCase() == email &&
                !f.estAnnulee)
            .toList();

    final totalInscrits =
        mesFormations.fold<int>(0, (sum, f) => sum + _inscrits(f));
    final totalCapacite =
        mesFormations.fold<int>(0, (sum, f) => sum + f.capaciteMax);
    final totalPlaces = mesFormations.fold<int>(
        0, (sum, f) => sum + (f.placesRestantes < 0 ? 0 : f.placesRestantes));
    final taux = totalCapacite == 0
        ? 0
        : ((totalInscrits * 100) / totalCapacite).round();

    // Session en cours et prochaine session
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    FormationModel? enCours;
    FormationModel? aVenir;
    for (final f in mesFormations) {
      final debut = f.dateDebut;
      final fin = f.dateFin;
      if (debut == null || fin == null) continue;
      final d = DateTime(debut.year, debut.month, debut.day);
      final e = DateTime(fin.year, fin.month, fin.day);
      if (!d.isAfter(today) && !e.isBefore(today)) {
        enCours ??= f;
      } else if (d.isAfter(today)) {
        if (aVenir == null || d.isBefore(aVenir.dateDebut!)) {
          aVenir = f;
        }
      }
    }
    final session = enCours ?? aVenir;
    final sessionActive = enCours != null;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F5),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<FormationProvider>().loadFormations(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _Header(
                  prenom: prenom,
                  nom: nom,
                  session: session,
                  sessionActive: sessionActive,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (formationProvider.isLoading &&
                        formationProvider.formations.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: LinearProgressIndicator(
                          color: Color(0xFFC5A059),
                        ),
                      ),
                    if (formationProvider.errorMessage != null)
                      _ErrorBanner(
                        message: formationProvider.errorMessage!,
                        onRetry: () =>
                            context.read<FormationProvider>().loadFormations(),
                      ),
                    const Text(
                      'APERÇU GLOBAL',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Color(0xFF2A1B16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.people_alt_outlined,
                            value: '$totalInscrits',
                            label: 'Étudiants inscrits',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.menu_book_outlined,
                            value: mesFormations.length
                                .toString()
                                .padLeft(2, '0'),
                            label: 'Formations',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.event_seat_outlined,
                            value: '$totalPlaces',
                            label: 'Places restantes',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.donut_large_outlined,
                            value: '$taux%',
                            label: 'Taux de remplissage',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(
                      sessionActive ? 'COURS EN COURS' : 'PROCHAIN COURS',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Color(0xFF2A1B16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _NextCourseCard(
                      formation: session,
                      onPresence: () => onNavigate(3),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'ACTIONS RAPIDES',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Color(0xFF2A1B16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.qr_code_2,
                            title: 'Présence',
                            onTap: () => onNavigate(3),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.add_circle_outline,
                            title: 'Contenu',
                            onTap: () => onNavigate(1),
                          ),
                        ),
                      ],
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x33DC2626)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: Color(0xFFDC2626)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: Color(0xFF7F1D1D)),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Réessayer', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String prenom;
  final String nom;
  final FormationModel? session;
  final bool sessionActive;

  const _Header({
    required this.prenom,
    required this.nom,
    required this.session,
    required this.sessionActive,
  });

  @override
  Widget build(BuildContext context) {
    final initials = '${prenom.isNotEmpty ? prenom[0] : ''}'
            '${nom.isNotEmpty ? nom[0] : ''}'
        .toUpperCase();

    final s = session;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A110E),
            Color(0xFF2A1B16),
            Color(0xFF241814),
          ],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(34),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: const Color(0xFFC5A059),
                child: Text(
                  initials.isEmpty ? 'F' : initials,
                  style: const TextStyle(
                    color: Color(0xFF1A110E),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ESPACE FORMATEUR',
                      style: TextStyle(
                        color: Color(0xFFE5C158),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$prenom $nom'.trim(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .06),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0x33C5A059),
                  ),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFFE5C158),
                  size: 21,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0x33C5A059),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.play_circle_outline,
                  color: Color(0xFFE5C158),
                  size: 30,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s == null
                            ? 'AUCUNE SESSION'
                            : (sessionActive
                                ? 'SESSION ACTIVE'
                                : 'PROCHAINE SESSION'),
                        style: const TextStyle(
                          color: Color(0xFFE5C158),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s?.titre ?? 'Aucune formation planifiée',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        s == null
                            ? 'Vos programmes apparaîtront ici'
                            : '${_fmtDate(s.dateDebut)} → ${_fmtDate(s.dateFin)}',
                        style: const TextStyle(
                          color: Color(0xFFB8B0AC),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (s != null)
                  _StatusBadge(label: sessionActive ? 'EN COURS' : 'À VENIR'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;

  const _StatusBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0x33C5A059),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0x66C5A059),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFE5C158),
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0x12000000),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: const Color(0xFF9A7936),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF2A1B16),
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF78716C),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _NextCourseCard extends StatelessWidget {
  final FormationModel? formation;
  final VoidCallback onPresence;

  const _NextCourseCard({
    required this.formation,
    required this.onPresence,
  });

  @override
  Widget build(BuildContext context) {
    final f = formation;

    if (f == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x15000000)),
        ),
        child: const Text(
          'Aucun cours en cours ou à venir pour le moment.',
          style: TextStyle(color: Color(0xFF78716C), fontSize: 12),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0x15000000),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A1B16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.school_outlined,
                  color: Color(0xFFE5C158),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f.titre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_fmtDate(f.dateDebut)} → ${_fmtDate(f.dateFin)}',
                      style: const TextStyle(
                        color: Color(0xFF78716C),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.category_outlined,
                size: 16,
                color: Color(0xFF9A7936),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  f.categorie.isEmpty ? 'Sans catégorie' : f.categorie,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              Text(
                '${_inscrits(f)} / ${f.capaciteMax} inscrits',
                style: const TextStyle(
                  color: Color(0xFF78716C),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPresence,
              icon: const Icon(Icons.qr_code_2, size: 18),
              label: const Text('Gérer les présences'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A1B16),
                foregroundColor: const Color(0xFFE5C158),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(
        icon,
        size: 18,
        color: const Color(0xFF9A7936),
      ),
      label: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF2A1B16),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 13),
        side: const BorderSide(
          color: Color(0x22C5A059),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}