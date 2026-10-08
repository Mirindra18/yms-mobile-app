import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';
import '../../models/presence_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/finance_provider.dart';
import '../../providers/formation_provider.dart';
import '../../providers/presence_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  Uint8List? _profileImageBytes;
  bool _loadingPhoto = false;

  UserModel? get _currentUser => context.read<AuthProvider>().currentUser;

  String? get _photoStorageKey {
    final user = _currentUser;

    if (user == null) return null;

    final email = user.email.trim().toLowerCase();

    if (email.isEmpty) return null;

    return 'yms_profile_photo_$email';
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProfile();
    });
  }

  Future<void> _initializeProfile() async {
    await _loadProfilePhoto();

    if (!mounted) return;

    await context.read<FormationProvider>().loadMesInscriptions();
  }

  // ============================================================
  // PHOTO DE PROFIL
  // ============================================================

  Future<void> _loadProfilePhoto() async {
    final key = _photoStorageKey;

    if (key == null) return;

    if (mounted) {
      setState(() {
        _loadingPhoto = true;
      });
    }

    try {
      final encodedImage = await _prefs.getString(key);

      if (encodedImage != null && encodedImage.isNotEmpty) {
        final bytes = base64Decode(encodedImage);

        if (!mounted) return;

        setState(() {
          _profileImageBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement de la photo : $e');
    } finally {
      if (mounted) {
        setState(() {
          _loadingPhoto = false;
        });
      }
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 900,
        maxHeight: 900,
      );

      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();

      final key = _photoStorageKey;

      if (key == null) return;

      final encodedImage = base64Encode(bytes);

      await _prefs.setString(key, encodedImage);

      if (!mounted) return;

      setState(() {
        _profileImageBytes = bytes;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo de profil mise à jour.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible de sélectionner la photo : $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deletePhoto() async {
    final key = _photoStorageKey;

    if (key == null) return;

    try {
      await _prefs.remove(key);

      if (!mounted) return;

      setState(() {
        _profileImageBytes = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo supprimée.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('Erreur suppression photo : $e');
    }
  }

  Future<void> _showPhotoOptions() async {
    final hasPhoto = _profileImageBytes != null;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Modifier ma photo',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brown800,
                  ),
                ),
                const SizedBox(height: 20),
                _PhotoOption(
                  icon: Icons.photo_library_outlined,
                  title: 'Choisir dans la galerie',
                  subtitle: 'Sélectionner une photo existante',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickPhoto(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 10),
                _PhotoOption(
                  icon: Icons.camera_alt_outlined,
                  title: 'Prendre une photo',
                  subtitle: 'Utiliser la caméra',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickPhoto(ImageSource.camera);
                  },
                ),
                if (hasPhoto) ...[
                  const SizedBox(height: 10),
                  _PhotoOption(
                    icon: Icons.delete_outline,
                    title: 'Supprimer la photo',
                    subtitle: 'Revenir aux initiales',
                    iconColor: Colors.red.shade700,
                    titleColor: Colors.red.shade700,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _deletePhoto();
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // MODIFIER PROFIL
  // ============================================================

  Future<void> _openEdit() async {
    final user = _currentUser;

    if (user == null) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _EditProfileSheet(user: user);
      },
    );
  }

  // ============================================================
  // PRESENCES
  // ============================================================

  Future<void> _openPresences() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return const _PresencesSheet();
      },
    );
  }

  // ============================================================
  // A PROPOS
  // ============================================================

  Future<void> _openAbout() async {
    await showDialog<void>(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'À propos de YMS',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: AppColors.brown800,
            ),
          ),
          content: Text(
            'Youth Malagasy Service accompagne '
            'les jeunes à travers des formations, '
            'des activités et des opportunités '
            'de développement.',
            style: GoogleFonts.poppins(fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // DECONNEXION
  // ============================================================

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Déconnexion',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Voulez-vous vraiment vous '
            'déconnecter ?',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brown800,
                foregroundColor: Colors.white,
              ),
              child: const Text('Se déconnecter'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;

    if (!mounted) return;

    await context.read<AuthProvider>().logout();
  }

  // ============================================================
  // ASSIDUITE
  // ============================================================

  String _assiduiteLabel(BuildContext context) {
    final presenceProvider = context.watch<PresenceProvider>();

    final presences = presenceProvider.presences;

    if (presences.isEmpty) {
      return '0%';
    }

    final entries = presences.whereType<PresenceEntry>().toList();

    if (entries.isEmpty) {
      return '0%';
    }

    final taux = PresenceStats.taux(entries);

    if (taux == null) {
      return '0%';
    }

    return '${taux.round()}%';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final formationProvider = context.watch<FormationProvider>();

    final financeProvider = context.watch<FinanceProvider>();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // ==================================================
            // HEADER
            // ==================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.brown800,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Mon profil',
                      style: GoogleFonts.poppins(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brown800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await Future.wait([
                    _loadProfilePhoto(),
                    context.read<FormationProvider>().loadMesInscriptions(),
                  ]);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ========================================
                      // IDENTITE
                      // ========================================
                      _IdentityCard(
                        user: user,
                        profileImageBytes: _profileImageBytes,
                        loadingPhoto: _loadingPhoto,
                        onPhotoTap: _showPhotoOptions,
                      ),

                      const SizedBox(height: 20),

                      // ========================================
                      // STATISTIQUES
                      // ========================================
                      Row(
                        children: [
                          Expanded(
                            child: _StatTile(
                              icon: Icons.fact_check_outlined,
                              label: 'Assiduité',
                              value: _assiduiteLabel(context),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatTile(
                              icon: Icons.payments_outlined,
                              label: 'Écolage',
                              value:
                                  '${financeProvider.soldeTotal.toStringAsFixed(0)} Ar',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatTile(
                              icon: Icons.school_outlined,
                              label: 'Formations',
                              value: formationProvider.nombreFormationsInscrites
                                  .toString(),
                            ),
                          ),
                        ],
                      ),

                      if (formationProvider.isLoadingInscriptions)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.brown800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Chargement des formations...',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),

                      // ========================================
                      // MENU
                      // ========================================
                      Text(
                        'Mon compte',
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brown800,
                        ),
                      ),

                      const SizedBox(height: 10),

                      _ProfileMenuItem(
                        icon: Icons.person_outline,
                        title: 'Modifier mon profil',
                        subtitle: 'Modifier mes informations personnelles',
                        onTap: _openEdit,
                      ),

                      _ProfileMenuItem(
                        icon: Icons.camera_alt_outlined,
                        title: 'Modifier ma photo',
                        subtitle: 'Choisir ou prendre une nouvelle photo',
                        onTap: _showPhotoOptions,
                      ),

                      _ProfileMenuItem(
                        icon: Icons.event_available_outlined,
                        title: 'Mes présences',
                        subtitle: 'Consulter mon historique de présence',
                        onTap: _openPresences,
                      ),

                      _ProfileMenuItem(
                        icon: Icons.info_outline,
                        title: 'À propos',
                        subtitle: 'En savoir plus sur Youth Malagasy Service',
                        onTap: _openAbout,
                      ),

                      const SizedBox(height: 8),

                      _ProfileMenuItem(
                        icon: Icons.logout,
                        title: 'Se déconnecter',
                        subtitle: 'Quitter mon compte YMS',
                        iconColor: Colors.red.shade700,
                        titleColor: Colors.red.shade700,
                        onTap: _confirmLogout,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// CARTE IDENTITE
// ================================================================

class _IdentityCard extends StatelessWidget {
  final UserModel user;
  final Uint8List? profileImageBytes;
  final bool loadingPhoto;
  final VoidCallback onPhotoTap;

  const _IdentityCard({
    required this.user,
    required this.profileImageBytes,
    required this.loadingPhoto,
    required this.onPhotoTap,
  });

  String get _initials {
    final firstName = user.prenom.trim();
    final lastName = user.nom.trim();

    String result = '';

    if (firstName.isNotEmpty) {
      result += firstName[0];
    }

    if (lastName.isNotEmpty) {
      result += lastName[0];
    }

    return result.isEmpty ? 'Y' : result.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final fullName = '${user.prenom} ${user.nom}'.trim();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.brown800, AppColors.brown700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.brown800.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: ClipOval(
                  child: profileImageBytes != null
                      ? Image.memory(profileImageBytes!, fit: BoxFit.cover)
                      : Container(
                          color: Colors.white.withValues(alpha: 0.18),
                          alignment: Alignment.center,
                          child: Text(
                            _initials,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 27,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                ),
              ),

              if (loadingPhoto)
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black26,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

              Positioned(
                right: -2,
                bottom: -2,
                child: GestureDetector(
                  onTap: onPhotoTap,
                  child: Container(
                    width: 31,
                    height: 31,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.brown800, width: 2),
                    ),
                    child: Icon(
                      Icons.camera_alt_outlined,
                      size: 16,
                      color: AppColors.brown800,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 17),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName.isEmpty ? 'Utilisateur' : fullName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  user.email,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 9),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'APPRENANT',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                GestureDetector(
                  onTap: onPhotoTap,
                  child: Text(
                    'Modifier la photo',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// STAT
// ================================================================

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: AppColors.brown800),
          const SizedBox(height: 7),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.brown800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 9,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// MENU
// ================================================================

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? titleColor;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.brown800;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        leading: Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: color, size: 21),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: titleColor ?? Colors.grey.shade900,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade600),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      ),
    );
  }
}

// ================================================================
// PHOTO OPTION
// ================================================================

class _PhotoOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? titleColor;

  const _PhotoOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.brown800;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: titleColor ?? Colors.grey.shade900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// MODIFICATION PROFIL
// ================================================================

class _EditProfileSheet extends StatefulWidget {
  final UserModel user;

  const _EditProfileSheet({required this.user});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nomController;

  late final TextEditingController _prenomController;

  late final TextEditingController _emailController;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _nomController = TextEditingController(text: widget.user.nom);

    _prenomController = TextEditingController(text: widget.user.prenom);

    _emailController = TextEditingController(text: widget.user.email);
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final nom = _nomController.text.trim();

    final prenom = _prenomController.text.trim();

    final email = _emailController.text.trim();

    if (nom.isEmpty || prenom.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs.')),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await context.read<AuthProvider>().updateProfile(
        nom: nom,
        prenom: prenom,
        email: email,
      );

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil mis à jour avec succès.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 25,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Modifier mon profil',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brown800,
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: _prenomController,
                decoration: InputDecoration(
                  labelText: 'Prénom',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              TextField(
                controller: _nomController,
                decoration: InputDecoration(
                  labelText: 'Nom',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brown800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Enregistrer',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
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

// ================================================================
// PRESENCES
// ================================================================

class _PresencesSheet extends StatelessWidget {
  const _PresencesSheet();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PresenceProvider>();

    final rawPresences = provider.presences;

    final presences = rawPresences.whereType<PresenceEntry>().toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),

            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
            ),

            const SizedBox(height: 18),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Mes présences',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brown800,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: presences.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.event_busy_outlined,
                            size: 45,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Aucune présence enregistrée.',
                            style: GoogleFonts.poppins(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 25),
                      itemCount: presences.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        return _PresenceRow(presence: presences[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// LIGNE PRESENCE
// ================================================================

class _PresenceRow extends StatelessWidget {
  final PresenceEntry presence;

  const _PresenceRow({required this.presence});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: presence.color.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              presence.estPresent ? Icons.check : Icons.close,
              color: presence.color,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              presence.statutLabel,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: presence.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              presence.statutLabel,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: presence.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
