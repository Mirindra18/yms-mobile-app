import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import 'common.dart';

/// Logo « YMS » : marque (badge doré) + nom de famille en serif.
class YmsLogo extends StatelessWidget {
  final double size;
  const YmsLogo({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.brown800, AppColors.brown900],
            ),
            borderRadius: BorderRadius.circular(size * 0.32),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.7)),
          ),
          child: const Icon(
            Icons.workspace_premium,
            color: AppColors.gold,
            size: 22,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'YMS',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.brown900,
                height: 1,
              ),
            ),
            Text(
              'Formation & Excellence',
              style: GoogleFonts.manrope(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Barre supérieure commune : marque + cloches de notification + avatar.
class BrandTopBar extends StatelessWidget {
  final String initials;
  final VoidCallback onLogout;

  const BrandTopBar({
    super.key,
    required this.initials,
    required this.onLogout,
  });

  Future<void> _openNotifications(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _NotificationsPanel(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.page, 8, AppSpacing.page, 8),
      child: Row(
        children: [
          const YmsLogo(),
          const Spacer(),
          _RoundAction(
            icon: Icons.notifications_none,
            tooltip: 'Notifications',
            badge: true,
            onTap: () => _openNotifications(context),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: () => showModalBottomSheet<void>(
              context: context,
              backgroundColor: AppColors.cream,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              builder: (_) => _AccountSheet(initials: initials, onLogout: onLogout),
            ),
            borderRadius: BorderRadius.circular(28),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.brown800, AppColors.brown900],
                ),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.cream,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool badge;
  final VoidCallback onTap;

  const _RoundAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Center(
                child: Icon(Icons.notifications_none, color: AppColors.brown700, size: 22),
              ),
              if (badge)
                Positioned(
                  top: 8,
                  right: 9,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.gold,
                      shape: BoxShape.circle,
                      border: Border.fromBorderSide(
                        BorderSide(color: AppColors.white, width: 1.5),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Accès rapide depuis l'avatar : compte courant + déconnexion.
class _AccountSheet extends StatelessWidget {
  final String initials;
  final VoidCallback onLogout;

  const _AccountSheet({required this.initials, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.page, 24, AppSpacing.page, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.brown800, AppColors.brown900],
                ),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.cream,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text('Gérer mon compte YMS', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Se déconnecter'),
                onPressed: () {
                  Navigator.pop(context);
                  onLogout();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Panneau de notifications (simulé, aucune API dédiée côté backend).
class _NotificationsPanel extends StatelessWidget {
  const _NotificationsPanel();

  static const _items = [
    (
      Icons.event_available,
      'Échéance à venir',
      'Votre échéance de ce mois approche : pensez à régler votre écolage.',
      'à l\'instant',
    ),
    (
      Icons.video_library_outlined,
      'Nouvelle leçon disponible',
      '« Flexbox et mise en page » est disponible sur votre parcours.',
      'il y a 2 h',
    ),
    (
      Icons.fact_check_outlined,
      'Assiduité 100 %',
      'Félicitations ! Votre taux de présence atteint 100 %.',
      'il y a 1 j',
    ),
    (
      Icons.school_outlined,
      'Inscriptions ouvertes',
      'Développement Web Full-Stack : les places sont limitées.',
      'il y a 3 j',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.page, 16, AppSpacing.page, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notifications', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text('Vos derniers événements YMS', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            ..._items.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconTile(icon: e.$1, color: AppColors.brown700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(e.$2,
                                        style: Theme.of(context).textTheme.titleSmall),
                                  ),
                                  Text(e.$4,
                                      style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(e.$3, style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

/// Bouton flottant de chat (conseiller YMS simulé).
class ChatFab extends StatelessWidget {
  const ChatFab({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.cream,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (_) => const ChatSheet(),
      ),
      backgroundColor: AppColors.brown900,
      foregroundColor: AppColors.cream,
      elevation: 4,
      icon: const Icon(Icons.support_agent, color: AppColors.gold),
      label: const Text(
        'Assistant',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

/// Feuille « Conseiller YMS » : simulateur de chat avec réponses pré-écrites.
class ChatSheet extends StatefulWidget {
  const ChatSheet({super.key});

  @override
  State<ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends State<ChatSheet> {
  final List<({bool fromUser, String text})> _messages = [
    (
      fromUser: false,
      text: 'Bonjour ! Je suis votre conseiller YMS. Comment puis-je vous aider ? 😊'
    ),
  ];

  void _send(String reply) {
    setState(() {
      _messages.add((fromUser: true, text: reply));
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _messages.add((fromUser: false, text: _botAnswer(reply)));
      });
    });
  }

  String _botAnswer(String question) {
    final q = question.toLowerCase();
    if (q.contains('echen') || q.contains('échéance') || q.contains('payer')) {
      return 'Rendez-vous dans l\'onglet Écolage : choisissez l\'échéance puis le mode MVola, Orange Money, espèces ou virement. Le reçu apparaît immédiatement.';
    }
    if (q.contains('inscri')) {
      return 'Ouvrez l\'onglet Formations, choisissez votre formation puis appuyez sur « S\'inscrire ». La place est confirmée instantanément.';
    }
    if (q.contains('certificat') || q.contains('certif')) {
      return 'Pour obtenir un certificat : formation terminée, écolage soldé et au moins 75 % d\'assiduité. Suivez votre progression dans l\'onglet Certificat.';
    }
    if (q.contains('session') || q.contains('cours')) {
      return 'Les prochaines séances de cours en ligne sont annoncées dans l\'onglet Accueil, section Actualités.';
    }
    return 'Bonne nouvelle : tout se passe depuis cette application 😊 Explorez les onglets Accueil, Formations, Écolage et Certificat.';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.72,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.page, 16, AppSpacing.page, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const IconTile(icon: Icons.support_agent, color: AppColors.gold),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Conseiller YMS',
                            style: Theme.of(context).textTheme.titleMedium),
                        Text('En ligne', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _messages.length,
                  itemBuilder: (context, i) {
                    final m = _messages[i];
                    return Align(
                      alignment: m.fromUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        constraints: const BoxConstraints(maxWidth: 280),
                        decoration: BoxDecoration(
                          color: m.fromUser ? AppColors.brown900 : AppColors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(m.fromUser ? 16 : 4),
                            bottomRight: Radius.circular(m.fromUser ? 4 : 16),
                          ),
                          border: m.fromUser ? null : Border.all(color: AppColors.cardBorder),
                        ),
                        child: Text(
                          m.text,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: m.fromUser ? AppColors.cream : AppColors.ink,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _quick('Voir mes échéances'),
                  _quick('M\'inscrire à une formation'),
                  _quick('Obtenir un certificat'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quick(String label) {
    return ActionChip(
      label: Text(label),
      backgroundColor: AppColors.white,
      side: const BorderSide(color: AppColors.cardBorder),
      onPressed: () => _send(label),
    );
  }
}