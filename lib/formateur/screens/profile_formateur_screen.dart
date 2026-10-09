import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/formateur_model.dart';
import '../../services/api_client.dart';
import '../../services/formateur_service.dart';
import '../../providers/formateur_provider.dart';
import '../widgets/formateur_colors.dart';
import '../widgets/formateur_common.dart';

enum _PhotoAction { gallery, camera, remove }

class ProfileFormateurScreen extends StatefulWidget {
  const ProfileFormateurScreen({super.key});

  @override
  State<ProfileFormateurScreen> createState() => _ProfileFormateurScreenState();
}

class _ProfileFormateurScreenState extends State<ProfileFormateurScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();
  Uint8List? _profileImageBytes;
  bool _loadingPhoto = false;
  bool _loadingFormations = true;
  String? _formationsError;
  List<Formation> _formations = [];

  String? get _photoStorageKey {
    final email = context.read<FormateurProvider>().email.trim().toLowerCase();
    return email.isEmpty ? null : 'yms_profile_photo_$email';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfilePhoto();
      _loadFormations();
    });
  }

  Future<void> _loadFormations() async {
    try {
      final formations = await FormateurService.formations(
        context.read<ApiClient>(),
        context.read<FormateurProvider>().email,
      );
      if (!mounted) return;
      setState(() {
        _formations = formations;
        _formationsError = null;
        _loadingFormations = false;
      });
    } catch (error) {
      debugPrint('Erreur lors du chargement des formations formateur : $error');
      if (!mounted) return;
      setState(() {
        _formationsError = 'Impossible de charger vos formations : $error';
        _loadingFormations = false;
      });
    }
  }

  Future<void> _loadProfilePhoto() async {
    final key = _photoStorageKey;
    if (key == null) return;

    setState(() => _loadingPhoto = true);
    try {
      final encodedImage = await _prefs.getString(key);
      if (!mounted) return;
      setState(() {
        _profileImageBytes = encodedImage == null || encodedImage.isEmpty
            ? null
            : base64Decode(encodedImage);
      });
    } catch (error) {
      debugPrint('Erreur lors du chargement de la photo de profil : $error');
      if (!mounted) return;
      setState(() => _profileImageBytes = null);
    } finally {
      if (mounted) setState(() => _loadingPhoto = false);
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 900,
        maxHeight: 900,
      );
      if (pickedFile == null) return;

      final key = _photoStorageKey;
      if (key == null) {
        throw StateError('Aucun compte formateur n’est connecté.');
      }

      final bytes = await pickedFile.readAsBytes();
      await _prefs.setString(key, base64Encode(bytes));
      if (!mounted) return;
      setState(() => _profileImageBytes = bytes);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo de profil mise à jour sur cet appareil.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible de sélectionner la photo : $error'),
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
      setState(() => _profileImageBytes = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo de profil supprimée.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible de supprimer la photo : $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showPhotoOptions() async {
    final hasPhoto = _profileImageBytes != null;
    final action = await showModalBottomSheet<_PhotoAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: FormateurColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: FormateurColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Photo de profil',
                style: TextStyle(
                  color: FormateurColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: FormateurColors.gold,
                ),
                title: const Text('Choisir dans la galerie'),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_PhotoAction.gallery),
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: FormateurColors.gold,
                ),
                title: const Text('Prendre une photo'),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_PhotoAction.camera),
              ),
              if (hasPhoto)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: FormateurColors.rose,
                  ),
                  title: const Text(
                    'Supprimer la photo',
                    style: TextStyle(color: FormateurColors.rose),
                  ),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(_PhotoAction.remove),
                ),
            ],
          ),
        ),
      ),
    );

    if (!mounted) return;
    switch (action) {
      case _PhotoAction.gallery:
        await _pickPhoto(ImageSource.gallery);
      case _PhotoAction.camera:
        await _pickPhoto(ImageSource.camera);
      case _PhotoAction.remove:
        await _deletePhoto();
      case null:
        break;
    }
  }

  Future<void> _planifierSeance() async {
    if (_loadingFormations) return;
    if (_formations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune formation ne vous est attribuée.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final titleController = TextEditingController();
    var selectedFormationId = _formations.first.id;
    var sessionDate = DateTime.now();
    var startTime = const TimeOfDay(hour: 9, minute: 0);
    var endTime = const TimeOfDay(hour: 12, minute: 0);
    var isSaving = false;
    String? error;

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> pickDate() async {
            final selected = await showDatePicker(
              context: context,
              initialDate: sessionDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
              locale: const Locale('fr', 'FR'),
            );
            if (selected != null) {
              setDialogState(() => sessionDate = selected);
            }
          }

          Future<void> pickTime({required bool isStart}) async {
            final selected = await showTimePicker(
              context: context,
              initialTime: isStart ? startTime : endTime,
            );
            if (selected != null) {
              setDialogState(() {
                if (isStart) {
                  startTime = selected;
                } else {
                  endTime = selected;
                }
              });
            }
          }

          String formattedTime(TimeOfDay time) =>
              '${time.hour.toString().padLeft(2, '0')}:'
              '${time.minute.toString().padLeft(2, '0')}';

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: const Text(
              'Planifier une séance',
              style: TextStyle(
                color: FormateurColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: selectedFormationId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Formation',
                      prefixIcon: Icon(Icons.menu_book_rounded),
                    ),
                    items: [
                      for (final formation in _formations)
                        DropdownMenuItem(
                          value: formation.id,
                          child: Text(
                            formation.titre,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: isSaving
                        ? null
                        : (value) {
                            if (value != null) {
                              setDialogState(() => selectedFormationId = value);
                            }
                          },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    enabled: !isSaving,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Thème ou module *',
                      hintText: 'Ex. Atelier pratique',
                      prefixIcon: Icon(Icons.edit_calendar_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: isSaving ? null : pickDate,
                    icon: const Icon(Icons.calendar_month_rounded),
                    label: Text(
                      DateFormat(
                        'EEEE d MMMM yyyy',
                        'fr_FR',
                      ).format(sessionDate),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isSaving
                              ? null
                              : () => pickTime(isStart: true),
                          icon: const Icon(Icons.schedule_rounded),
                          label: Text('Début ${formattedTime(startTime)}'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isSaving
                              ? null
                              : () => pickTime(isStart: false),
                          icon: const Icon(Icons.schedule_rounded),
                          label: Text('Fin ${formattedTime(endTime)}'),
                        ),
                      ),
                    ],
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      error!,
                      style: const TextStyle(
                        color: FormateurColors.rose,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: const Text('Annuler'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: FormateurColors.ink,
                  foregroundColor: Colors.white,
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        final title = titleController.text.trim();
                        if (title.isEmpty) {
                          setDialogState(
                            () => error = 'Saisissez le thème de la séance.',
                          );
                          return;
                        }

                        final start = DateTime(
                          sessionDate.year,
                          sessionDate.month,
                          sessionDate.day,
                          startTime.hour,
                          startTime.minute,
                        );
                        final end = DateTime(
                          sessionDate.year,
                          sessionDate.month,
                          sessionDate.day,
                          endTime.hour,
                          endTime.minute,
                        );
                        if (!end.isAfter(start)) {
                          setDialogState(
                            () => error =
                                'L’heure de fin doit être après l’heure de début.',
                          );
                          return;
                        }

                        setDialogState(() {
                          isSaving = true;
                          error = null;
                        });
                        try {
                          await FormateurService.createPresenceSession(
                            context.read<ApiClient>(),
                            selectedFormationId,
                            title,
                            start,
                            end,
                          );
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop(true);
                          }
                        } catch (exception) {
                          setDialogState(() {
                            isSaving = false;
                            error = 'Création impossible : $exception';
                          });
                        }
                      },
                icon: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_rounded),
                label: Text(isSaving ? 'Création...' : 'Créer la séance'),
              ),
            ],
          );
        },
      ),
    );

    titleController.dispose();
    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Séance planifiée avec succès.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<FormateurProvider>().profile;
    final name = [
      profile?.prenom ?? '',
      profile?.nom ?? '',
    ].where((part) => part.trim().isNotEmpty).join(' ');
    final initials = [profile?.prenom ?? '', profile?.nom ?? '']
        .where((part) => part.trim().isNotEmpty)
        .map((part) => part.trim()[0].toUpperCase())
        .join();

    return ColoredBox(
      color: FormateurColors.bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [FormateurColors.ink, Color(0xFF4A2C1A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Semantics(
                    button: true,
                    label: 'Modifier la photo de profil',
                    child: InkWell(
                      onTap: _showPhotoOptions,
                      customBorder: const CircleBorder(),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: FormateurColors.accent,
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: _profileImageBytes == null
                                  ? Container(
                                      color: const Color(0x33D4AF37),
                                      alignment: Alignment.center,
                                      child: Text(
                                        initials.isEmpty ? 'YMS' : initials,
                                        style: const TextStyle(
                                          color: FormateurColors.accent,
                                          fontSize: 25,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    )
                                  : Image.memory(
                                      _profileImageBytes!,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                          if (_loadingPhoto)
                            const Positioned.fill(
                              child: Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: FormateurColors.accent,
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: FormateurColors.accent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: FormateurColors.ink,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 15,
                                color: FormateurColors.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    name.isEmpty ? 'Formateur' : name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    profile?.specialite?.trim().isNotEmpty == true
                        ? profile!.specialite!
                        : 'Espace formateur YMS',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFE8DFC8),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Informations personnelles',
              style: TextStyle(
                color: FormateurColors.ink,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: cardDecoration(),
              child: Column(
                children: [
                  _profileLine(
                    Icons.email_outlined,
                    'Adresse e-mail',
                    profile?.email,
                  ),
                  _profileLine(
                    Icons.phone_outlined,
                    'Téléphone',
                    profile?.telephone,
                  ),
                  _profileLine(
                    Icons.location_on_outlined,
                    'Adresse',
                    profile?.adresse,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const IconBox(
                        icon: Icons.event_available_rounded,
                        dark: true,
                        size: 42,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Planifier une nouvelle séance de cours',
                              style: TextStyle(
                                color: FormateurColors.ink,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _loadingFormations
                                  ? 'Chargement de vos formations...'
                                  : _formationsError != null
                                  ? _formationsError!
                                  : _formations.isEmpty
                                  ? 'Aucune formation ne vous est attribuée.'
                                  : '${_formations.length} formation'
                                        '${_formations.length == 1 ? '' : 's'} disponible'
                                        '${_formations.length == 1 ? '' : 's'}',
                              style: const TextStyle(
                                color: FormateurColors.muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _loadingFormations
                          ? null
                          : _formationsError != null
                          ? _loadFormations
                          : _formations.isEmpty
                          ? null
                          : _planifierSeance,
                      style: FilledButton.styleFrom(
                        backgroundColor: FormateurColors.ink,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: Icon(
                        _formationsError != null
                            ? Icons.refresh_rounded
                            : Icons.add_rounded,
                      ),
                      label: Text(
                        _formationsError != null
                            ? 'Réessayer'
                            : 'Planifier une séance',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3EBD9),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: FormateurColors.border),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: FormateurColors.gold,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'La photo est enregistrée uniquement sur cet appareil. '
                      'Les autres informations proviennent de votre compte YMS.',
                      style: TextStyle(
                        color: FormateurColors.ink,
                        fontSize: 12,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileLine(IconData icon, String label, String? value) {
    if (value == null || value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: FormateurColors.soft,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: FormateurColors.gold, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: FormateurColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: FormateurColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
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
