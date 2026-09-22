import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/auth_provider.dart';
import '../providers/elearning_provider.dart';
import '../providers/finance_provider.dart';
import '../providers/formation_provider.dart';
import '../providers/presence_provider.dart';
import '../../core/theme/app_theme.dart';
import '../core/widgets/brand_chrome.dart';

import '../apprenant/screens/certification_screen.dart';
import '../apprenant/screens/finance_screen.dart';
import '../apprenant/screens/formations_screen.dart';
import '../apprenant/screens/home_screen.dart';
import '../apprenant/screens/profile_screen.dart';

/// Coquille principale de l'application : 5 onglets + chrome premium
/// (barre de marque, notifications, assistant, navigation).
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = context;

      ctx.read<FormationProvider>().loadFormations();
      ctx.read<FinanceProvider>().load();
      ctx.read<PresenceProvider>().load();
      ctx.read<ElearningProvider>().loadFormations();
    });
  }

  String get _initials {
    final user = context.read<AuthProvider>().currentUser;

    if (user == null) return '?';

    final p = user.prenom.isNotEmpty ? user.prenom[0] : '';
    final n = user.nom.isNotEmpty ? user.nom[0] : '';

    return '$p$n'.toUpperCase();
  }

  void _goTo(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            BrandTopBar(
              initials: _initials,
              onLogout: () => context.read<AuthProvider>().logout(),
            ),
            Expanded(
              child: IndexedStack(
                index: _index,
                children: [
                  HomeScreen(onNavigate: _goTo),
                  const FormationsScreen(),
                  const FinanceScreen(),
                  const CertificationScreen(),
                  const ProfileScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: const ChatFab(),
      bottomNavigationBar: _PremiumNav(
        current: _index,
        onTap: _goTo,
      ),
    );
  }
}

class _PremiumNav extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;

  const _PremiumNav({
    required this.current,
    required this.onTap,
  });

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'Accueil'),
    (Icons.school_outlined, Icons.school_rounded, 'Formations'),
    (Icons.payments_outlined, Icons.payments_rounded, 'Écolage'),
    (
      Icons.workspace_premium_outlined,
      Icons.workspace_premium_rounded,
      'Certificat',
    ),
    (Icons.person_outline, Icons.person_rounded, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.cardBorder,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          child: Row(
            children: List.generate(_items.length, (i) {
              final (icon, activeIcon, label) = _items[i];
              final selected = current == i;

              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.brown900
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            selected ? activeIcon : icon,
                            size: 22,
                            color: selected
                                ? AppColors.gold
                                : AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          label,
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: selected
                                ? AppColors.brown900
                                : AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}