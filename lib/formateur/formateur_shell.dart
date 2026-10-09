import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/formateur_provider.dart';
import 'screens/accueil_screen.dart';
import 'screens/calendrier_screen.dart';
import 'screens/elearning_formateur_screen.dart';
import 'screens/formations_screen.dart';
import 'screens/participants_screen.dart';
import 'screens/presence_formateur_screen.dart';
import 'screens/profile_formateur_screen.dart';
import 'screens/sessions_screen.dart';
import 'widgets/formateur_colors.dart';
import 'widgets/formateur_tabs.dart';

const _dark = Color(0xFF1A110E);
const _gold = Color(0xFFC5A059);

/// Shell formateur : AppBar + menu latéral (plus de barre de navigation du bas).
class FormateurShell extends StatefulWidget {
  final UserModel? user;

  const FormateurShell({super.key, this.user});

  @override
  State<FormateurShell> createState() => _FormateurShellState();
}

class _FormateurShellState extends State<FormateurShell> {
  int _currentIndex = FormateurTabs.accueil;

  late final List<Widget> _screens;

  void _go(int index) => setState(() => _currentIndex = index);

  int get _navigationIndex => switch (_currentIndex) {
    FormateurTabs.accueil => 0,
    FormateurTabs.formations => 1,
    FormateurTabs.calendrier => 2,
    _ => 3,
  };

  void _onNavigationSelected(int index) {
    switch (index) {
      case 0:
        _go(FormateurTabs.accueil);
      case 1:
        _go(FormateurTabs.formations);
      case 2:
        _go(FormateurTabs.calendrier);
      case 3:
        _showMoreDestinations();
    }
  }

  Future<void> _showMoreDestinations() async {
    final index = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _MoreDestinationsSheet(currentIndex: _currentIndex),
    );
    if (index != null && mounted) _go(index);
  }

  /// Les nouveaux écrans ont un fond crème : on les isole du fond sombre du shell.
  Widget _light(Widget child) => ColoredBox(
    color: FormateurColors.bg,
    child: SafeArea(top: false, child: child),
  );

  @override
  void initState() {
    super.initState();
    // L'ordre doit correspondre aux index de FormateurTabs.
    _screens = [
      _light(AccueilScreen(onNavigate: _go)), // remplace HomeFormateurScreen
      const ElearningFormateurScreen(),
      _light(const FormationsScreen()),
      _light(const SessionsScreen()),
      _light(const CalendrierScreen()),
      _light(const ParticipantsScreen()),
      const PresenceFormateurScreen(),
      const ProfileFormateurScreen(),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = widget.user ?? context.read<AuthProvider>().currentUser;
    if (user != null) context.read<FormateurProvider>().setProfile(user);
  }

  @override
  Widget build(BuildContext context) {
    final current = FormateurTabs.all[_currentIndex];

    return PopScope(
      // Retour système : revient à l'accueil avant de quitter
      canPop: _currentIndex == FormateurTabs.accueil,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _go(FormateurTabs.accueil);
      },
      child: Scaffold(
        backgroundColor: _dark,
        appBar: AppBar(
          backgroundColor: _dark,
          foregroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: const IconThemeData(color: _gold),
          titleSpacing: 4,
          title: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/logo_yms.png',
                  width: 38,
                  height: 38,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      current.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'YMS  •  ESPACE FORMATEUR',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFC5A059),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Présence',
              icon: const Icon(Icons.qr_code_scanner_rounded, color: _gold),
              onPressed: () => _go(FormateurTabs.presence),
            ),
            IconButton(
              tooltip: 'Mon profil',
              icon: const Icon(Icons.account_circle_outlined, color: _gold),
              onPressed: () => _go(FormateurTabs.profil),
            ),
          ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, thickness: 1, color: Color(0x33C5A059)),
          ),
        ),
        drawer: _FormateurDrawer(currentIndex: _currentIndex, onSelect: _go),
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _navigationIndex,
          onDestinationSelected: _onNavigationSelected,
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFF3EBD9),
          elevation: 8,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Accueil',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book_rounded),
              label: 'Formations',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month_rounded),
              label: 'Agenda',
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view_rounded),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'Plus',
            ),
          ],
        ),
      ),
    );
  }
}

class _FormateurDrawer extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelect;
  const _FormateurDrawer({required this.currentIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<FormateurProvider>();
    final email = profile.email;
    final name = profile.nomComplet;

    return Drawer(
      backgroundColor: _dark,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF9A7936),
                  Color(0xFFC5A059),
                  Color(0xFFE5C158),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 20,
              20,
              20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: _dark,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0x66FFFFFF)),
                      ),
                      child: Image.asset(
                        'assets/images/logo_yms.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'YMS',
                            style: TextStyle(
                              color: _dark,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            'ESPACE FORMATEUR',
                            style: TextStyle(
                              color: _dark,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  name.isEmpty ? 'Bienvenue' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _dark,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _dark,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              children: [
                for (var i = 0; i < FormateurTabs.all.length; i++)
                  _item(context, i),
              ],
            ),
          ),
          const Divider(color: Color(0x33FFFFFF), height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              leading: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFFCA5A5),
              ),
              title: const Text(
                'Se déconnecter',
                style: TextStyle(
                  color: Color(0xFFFCA5A5),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              onTap: () => _confirmLogout(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Se déconnecter ?'),
        content: const Text(
          'Votre session sera fermée et vous devrez vous reconnecter pour '
          'accéder à votre espace formateur.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _dark,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !context.mounted) return;

    Navigator.of(context).pop();
    await context.read<AuthProvider>().logout();
  }

  Widget _item(BuildContext context, int i) {
    final tab = FormateurTabs.all[i];
    final selected = i == currentIndex;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        selected: selected,
        selectedTileColor: const Color(0x33C5A059),
        selectedColor: _gold,
        iconColor: const Color(0xFF78716C),
        textColor: Colors.white70,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Icon(tab.icon, size: 22),
        title: Text(
          tab.label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        onTap: () {
          Navigator.of(context).pop(); // ferme le menu
          onSelect(i);
        },
      ),
    );
  }
}

class _MoreDestinationsSheet extends StatelessWidget {
  final int currentIndex;
  const _MoreDestinationsSheet({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final destinations = [
      FormateurTabs.elearning,
      FormateurTabs.sessions,
      FormateurTabs.participants,
      FormateurTabs.presence,
      FormateurTabs.profil,
    ];

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: const BoxDecoration(
          color: FormateurColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: FormateurColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Explorer votre espace',
              style: TextStyle(
                color: FormateurColors.ink,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Accédez aux autres outils formateur.',
              style: TextStyle(
                color: FormateurColors.muted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            for (final index in destinations)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: FormateurColors.border),
                  ),
                  child: Icon(
                    FormateurTabs.all[index].icon,
                    color: FormateurColors.gold,
                    size: 21,
                  ),
                ),
                title: Text(
                  FormateurTabs.all[index].label,
                  style: const TextStyle(
                    color: FormateurColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                trailing: currentIndex == index
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: FormateurColors.gold,
                      )
                    : const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 15,
                        color: FormateurColors.muted,
                      ),
                onTap: () => Navigator.of(context).pop(index),
              ),
          ],
        ),
      ),
    );
  }
}
