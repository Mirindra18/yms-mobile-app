import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/presence_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/finance_provider.dart';
import '../../providers/formation_provider.dart';
import '../../providers/presence_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brand_chrome.dart';
import '../../core/widgets/common.dart';

/// Onglet Profil : identité, statistiques et menu.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.page, 4, AppSpacing.page, 28),
      children: [
        Text('Profil', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 18),
        if (user == null)
          const AppLoading()
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _IdentityCard(user: user),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      label: 'Assiduité',
                      value: _assiduiteLabel(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      label: 'Écolage',
                      value: AppFormat.ar(context.watch<FinanceProvider>().soldeTotal),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      label: 'Formations',
                      value: '${context.watch<FormationProvider>().formations.length}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _menuTile(
                context,
                icon: Icons.edit_outlined,
                title: 'Modifier mon profil',
                onTap: () => _openEdit(context),
              ),
              _menuTile(
                context,
                icon: Icons.fact_check_outlined,
                title: 'Mes présences',
                onTap: () => _openPresences(context),
              ),
              _menuTile(
                context,
                icon: Icons.info_outline,
                title: 'À propos de YMS',
                onTap: () => _openAbout(context),
              ),
              _menuTile(
                context,
                icon: Icons.logout,
                title: 'Se déconnecter',
                danger: true,
                onTap: () => _confirmLogout(context),
              ),
            ],
          ),
      ],
    );
  }

  String _assiduiteLabel(BuildContext context) {
    final p = context.read<PresenceProvider>();
    final t = p.tauxAssiduite;
    return t == null ? '—' : '${t.round()} %';
  }

  Widget _menuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final color = danger ? AppColors.danger : AppColors.brown700;
    return Card(
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: IconTile(icon: icon, color: color),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: danger ? AppColors.danger : AppColors.ink,
              ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
        onTap: onTap,
      ),
    );
  }

  Future<void> _openEdit(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _EditProfileSheet(),
    );
  }

  Future<void> _openPresences(BuildContext context) {
    final presence = context.read<PresenceProvider>();
    return showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 420),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mes présences', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  '${presence.presences.length} séance(s) · ${presence.nbPresents} présence(s)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: presence.presences.isEmpty
                      ? const AppEmptyState(
                          icon: Icons.event_busy,
                          title: 'Aucune séance',
                          subtitle: 'Vos présences s\'afficheront ici.',
                        )
                      : ListView.separated(
                          itemCount: presence.presences.length,
                          separatorBuilder: (_, _) => const Divider(),
                          itemBuilder: (context, i) {
                            final p = presence.presences[i];
                            return _PresenceRow(entry: p);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openAbout(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const YmsLogo(),
              const SizedBox(height: 16),
              Text(
                'YMS accompagne les apprenants vers l\'excellence : formations, '
                'e-learning, suivi de l\'écolage et certificats professionnels.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
              ),
              const SizedBox(height: 16),
              Text('Version 1.0.0', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Se déconnecter ?'),
        content: const Text('Vous pourrez vous reconnecter à tout moment.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().logout();
    }
  }
}

class _IdentityCard extends StatelessWidget {
  final UserModel user;
  const _IdentityCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final initials =
        '${user.prenom.isNotEmpty ? user.prenom[0] : ''}${user.nom.isNotEmpty ? user.nom[0] : ''}'
            .toUpperCase();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brown800, AppColors.brown950],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.55)),
      ),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold,
              border: Border.all(color: AppColors.cream, width: 3),
            ),
            child: Center(
              child: Text(
                initials,
                style: GoogleFonts.manrope(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brown950,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${user.prenom} ${user.nom}'.trim(),
            style: GoogleFonts.cormorantGaramond(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.cream,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            user.email,
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: AppColors.goldSoft,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: user.roles
                .map((r) => StatusChip(
                      label: r.replaceFirst('ROLE_', ''),
                      color: AppColors.gold,
                      background: Colors.white.withValues(alpha: 0.12),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        child: Column(
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontFamily: 'Cormorant Garamond',
                    fontSize: 16,
                  ),
            ),
            const SizedBox(height: 3),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _PresenceRow extends StatelessWidget {
  final PresenceEntry entry;
  const _PresenceRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.circle, size: 10, color: entry.color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Séance #${entry.seanceId} · ${AppFormat.date(entry.datePresence, full: true)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          StatusChip(label: entry.statutLabel, color: entry.color),
        ],
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet();

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _prenom;
  late final TextEditingController _nom;
  late final TextEditingController _email;
  final _password = TextEditingController();

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _prenom = TextEditingController(text: user?.prenom ?? '');
    _nom = TextEditingController(text: user?.nom ?? '');
    _email = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _prenom.dispose();
    _nom.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);

    final auth = context.read<AuthProvider>();
    final ok = await auth.updateProfile(
      nom: _nom.text.trim(),
      prenom: _prenom.text.trim(),
      email: _email.text.trim(),
      password: _password.text.isEmpty ? null : _password.text,
    );

    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      Navigator.of(context).pop();
      AppToast.show(context, 'Profil mis à jour', isOk: true);
    } else {
      AppToast.show(context, auth.errorMessage ?? 'Erreur lors de la mise à jour',
          isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.page,
          16,
          AppSpacing.page,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Modifier mon profil',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _prenom,
                      decoration: const InputDecoration(labelText: 'Prénom'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requis' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _nom,
                      decoration: const InputDecoration(labelText: 'Nom'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requis' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requis';
                  if (!v.contains('@')) return 'Email invalide';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nouveau mot de passe (optionnel)',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  if (!RegExp(r'^(?=.*\d).{8,}$').hasMatch(v)) {
                    return 'Min. 8 caractères et 1 chiffre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _busy ? null : _save,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.cream,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}