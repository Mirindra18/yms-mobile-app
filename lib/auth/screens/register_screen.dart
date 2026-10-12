import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/api_client.dart';

/// Règles de validation à garder IDENTIQUES entre le web (Register.tsx)
/// et le mobile. Le backend doit aussi les appliquer.
class RegisterRules {
  RegisterRules._();

  static const int minPasswordLength = 8;

  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  // Mobile : 03X XX XXX XX ; fixe : 020 XX XXX XX ; ou +261 / 261 suivi du numéro sans le 0.
  static final RegExp _phone = RegExp(r'^(?:\+?261|0)(?:3\d|20)\d{7}$');

  static String? requiredField(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Ce champ est obligatoire.' : null;

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) {
      return 'L’adresse e-mail est obligatoire.';
    }
    if (!_email.hasMatch(v.trim())) return 'Adresse e-mail invalide.';
    return null;
  }

  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Le téléphone est obligatoire.';
    final normalized = v.replaceAll(RegExp(r'[\s().-]'), '');
    if (!_phone.hasMatch(normalized)) {
      return 'Numéro invalide (ex. 034 00 000 00).';
    }
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Le mot de passe est obligatoire.';
    if (v.length < minPasswordLength) {
      return '$minPasswordLength caractères minimum.';
    }
    if (!RegExp(r'\d').hasMatch(v)) return 'Ajoute au moins un chiffre.';
    return null;
  }

  /// Score de 0 à 4, purement indicatif (la règle bloquante reste [password]).
  static int passwordScore(String v) {
    var score = 0;
    if (v.length >= minPasswordLength) score++;
    if (RegExp(r'\d').hasMatch(v)) score++;
    if (RegExp(r'[a-z]').hasMatch(v) && RegExp(r'[A-Z]').hasMatch(v)) score++;
    if (v.length >= 12 || RegExp(r'[^A-Za-z0-9]').hasMatch(v)) score++;
    return score;
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Palette YMS : noir, blanc et doré.
  static const Color _backgroundColor = Color(0xFF0B0B0D);
  static const Color _surfaceColor = Color(0xFF171719);
  static const Color _fieldColor = Color(0xFF202023);
  static const Color _goldColor = Color(0xFFD4AF37);
  static const Color _goldLightColor = Color(0xFFF3D77A);
  static const Color _textColor = Color(0xFFF5F5F5);
  static const Color _mutedColor = Color(0xFFB0B0B5);
  static const Color _borderColor = Color(0xFF38383D);

  static const int _stepForm = 0;
  static const int _stepDynamicForm = 1;
  static const int _stepPayment = 2;
  static const int _stepConfirm = 3;

  late final Dio _dio;

  final _formKey = GlobalKey<FormState>();
  final _dynamicFormKey = GlobalKey<FormState>();
  final _paymentFormKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _adresseController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referenceController = TextEditingController();
  final _imagePicker = ImagePicker();

  int _currentStep = _stepForm;

  String _role = 'ROLE_APPRENANT';
  String _genre = 'FEMININ';
  String _modePaiement = 'MVOLA';

  String? _formationId;
  List<Map<String, dynamic>> _formations = [];
  Map<String, dynamic>? _publishedForm;
  final Map<String, dynamic> _formAnswers = {};
  DateTime? _dateNaissance;
  Uint8List? _avatarBytes;
  String? _avatarUrl;
  String? _avatarFileName;
  String? _receiptUrl;
  String? _receiptFileName;

  bool _isLoadingFormations = true;
  bool _isLoadingForm = false;
  bool _isUploadingAvatar = false;
  bool _isUploadingReceipt = false;
  int? _uploadingFieldId;
  int _formLoadGeneration = 0;
  bool _isSubmitting = false;
  bool _accountCreated = false;
  bool _registrationSent = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Map<String, dynamic>? _pendingPaymentRequest;

  /// Erreur de chargement des formations (séparée de l'erreur d'envoi).
  String? _formationsError;

  /// Erreur d'envoi du formulaire.
  String? _errorMessage;
  String? _numeroDossier;

  Map<String, dynamic>? get _selectedFormation {
    if (_formationId == null) return null;
    for (final formation in _formations) {
      if (formation['id'].toString() == _formationId) return formation;
    }
    return null;
  }

  double get _registrationFee {
    final value = _selectedFormation?['droitInscription'];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  bool get _isApprenant => _role == 'ROLE_APPRENANT';

  /// Après création du compte, on ne revient plus en arrière (évite les doublons).
  bool get _isLocked => _accountCreated && !_registrationSent;

  @override
  void initState() {
    super.initState();

    _dio = Dio(
      BaseOptions(
        baseUrl: ApiClient.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _loadFormations();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _prenomController.dispose();
    _nomController.dispose();
    _emailController.dispose();
    _adresseController.dispose();
    _telephoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referenceController.dispose();
    _dio.close();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Données
  // ---------------------------------------------------------------------------

  List<Map<String, dynamic>> _parseFormations(dynamic data) {
    final List<dynamic> items;

    if (data is List) {
      items = data;
    } else if (data is Map && data['content'] is List) {
      items = data['content'] as List;
    } else if (data is Map && data['data'] is List) {
      items = data['data'] as List;
    } else {
      throw const FormatException(
        'Format de réponse des formations non reconnu.',
      );
    }

    return items
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where((item) => item['id'] != null && item['titre'] != null)
        .toList();
  }

  Future<void> _loadFormations() async {
    setState(() {
      _isLoadingFormations = true;
      _formationsError = null;
    });

    try {
      final response = await _dio.get('/api/formations');
      final formations = _parseFormations(response.data);

      if (!mounted) return;
      setState(() {
        _formations = formations;
        _isLoadingFormations = false;
        // Si la formation choisie a disparu de la liste, on la réinitialise.
        if (_selectedFormation == null) _formationId = null;
      });
    } on DioException catch (e) {
      debugPrint('Erreur formations : ${e.message}');
      if (!mounted) return;
      setState(() {
        _isLoadingFormations = false;
        _formationsError =
            'Impossible de charger les formations. Vérifie ta connexion.';
      });
    } catch (e) {
      debugPrint('Erreur formations : $e');
      if (!mounted) return;
      setState(() {
        _isLoadingFormations = false;
        _formationsError = 'Les formations n’ont pas pu être lues.';
      });
    }
  }

  Future<bool> _loadPublishedFormulaire(int formationId) async {
    final generation = ++_formLoadGeneration;
    setState(() {
      _isLoadingForm = true;
      _publishedForm = null;
      _formAnswers.clear();
    });

    try {
      final response = await _dio.get(
        '/api/formulaires/formations/$formationId/published',
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      if (!mounted || generation != _formLoadGeneration) return false;
      if (response.statusCode != null &&
          response.statusCode! >= 400 &&
          response.statusCode != 404) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
        );
      }
      setState(() {
        if (response.statusCode != 204 &&
            response.statusCode != 404 &&
            response.data is Map) {
          _publishedForm = Map<String, dynamic>.from(response.data as Map);
        }
        _isLoadingForm = false;
      });
      return true;
    } on DioException catch (e) {
      if (!mounted || generation != _formLoadGeneration) return false;
      setState(() => _isLoadingForm = false);
      _showMessage(
        'Impossible de charger le formulaire de cette formation. '
        'Vérifie ta connexion puis réessaie.',
      );
      debugPrint('Erreur formulaire dynamique : ${e.message}');
      return false;
    } catch (e) {
      if (!mounted || generation != _formLoadGeneration) return false;
      setState(() => _isLoadingForm = false);
      _showMessage('Le formulaire de cette formation est illisible.');
      debugPrint('Erreur formulaire dynamique : $e');
      return false;
    }
  }

  List<String> _parseOptions(dynamic rawOptions) {
    if (rawOptions is List) {
      return rawOptions.map((value) => value.toString()).toList();
    }
    if (rawOptions is! String || rawOptions.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(rawOptions);
      if (decoded is List) {
        return decoded.map((value) => value.toString()).toList();
      }
    } on FormatException {
      // Les anciennes options sont stockées sous forme de liste séparée par des virgules.
    }
    return rawOptions
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  Future<Map<String, dynamic>> _uploadFile(
    Uint8List bytes,
    String fileName,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/files/upload',
      data: FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      }),
      options: Options(contentType: Headers.multipartFormDataContentType),
    );
    final data = response.data;
    if (data == null || data['url'] is! String) {
      throw const FormatException('Réponse de téléversement invalide.');
    }
    return data;
  }

  Future<void> _pickAvatar(ImageSource source) async {
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        _showMessage('La photo de profil ne doit pas dépasser 5 Mo.');
        return;
      }
      final extension = image.name.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
        _showMessage('Formats acceptés : JPG, PNG ou WebP.');
        return;
      }

      setState(() {
        _avatarBytes = bytes;
        _avatarFileName = image.name;
        _avatarUrl = null;
        _isUploadingAvatar = true;
        _errorMessage = null;
      });
      final uploaded = await _uploadFile(bytes, image.name);
      if (!mounted) return;
      setState(() {
        _avatarUrl = uploaded['url'] as String;
        _isUploadingAvatar = false;
      });
      _showMessage('Photo de profil enregistrée.');
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingAvatar = false);
      _showMessage(_registrationErrorMessage(e));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingAvatar = false);
      debugPrint('Erreur photo de profil : $e');
      _showMessage('Impossible d’enregistrer la photo de profil.');
    }
  }

  Future<void> _showAvatarSourcePicker() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: _surfaceColor,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: _goldLightColor,
              ),
              title: const Text('Choisir dans la galerie'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_outlined,
                color: _goldLightColor,
              ),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source != null) await _pickAvatar(source);
  }

  Future<void> _pickDynamicFile(Map<String, dynamic> field) async {
    final isPhoto = field['typeChamp'] == 'PHOTO';
    try {
      late final Uint8List bytes;
      late final String fileName;
      if (isPhoto) {
        final image = await _imagePicker.pickImage(source: ImageSource.gallery);
        if (image == null) return;
        bytes = await image.readAsBytes();
        fileName = image.name;
      } else {
        final files = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: [
            'pdf',
            'doc',
            'docx',
            'jpg',
            'jpeg',
            'png',
            'webp',
          ],
        );
        if (files.isEmpty) return;
        final file = files.first;
        bytes = await file.readAsBytes();
        fileName = file.name;
      }
      if (bytes.length > 10 * 1024 * 1024) {
        _showMessage('Le fichier ne doit pas dépasser 10 Mo.');
        return;
      }

      final fieldId = field['id'] is num ? (field['id'] as num).toInt() : 0;
      setState(() => _uploadingFieldId = fieldId);
      final uploaded = await _uploadFile(bytes, fileName);
      if (!mounted) return;
      setState(() {
        _formAnswers[field['label'].toString()] = {
          'url': uploaded['url'],
          'filename': uploaded['originalName'] ?? fileName,
          'size': uploaded['size'] ?? bytes.length,
        };
        _uploadingFieldId = null;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _uploadingFieldId = null);
      _showMessage(_registrationErrorMessage(e));
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingFieldId = null);
      debugPrint('Erreur téléversement champ dynamique : $e');
      _showMessage('Impossible de téléverser le fichier sélectionné.');
    }
  }

  Future<void> _pickReceipt() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      );
      if (files.isEmpty) return;
      final file = files.first;
      final bytes = await file.readAsBytes();
      if (bytes.length > 10 * 1024 * 1024) {
        _showMessage('Le reçu ne doit pas dépasser 10 Mo.');
        return;
      }

      setState(() => _isUploadingReceipt = true);
      final uploaded = await _uploadFile(bytes, file.name);
      if (!mounted) return;
      setState(() {
        _receiptUrl = uploaded['url'] as String;
        _receiptFileName = (uploaded['originalName'] ?? file.name).toString();
        _isUploadingReceipt = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingReceipt = false);
      _showMessage(_registrationErrorMessage(e));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingReceipt = false);
      debugPrint('Erreur téléversement reçu : $e');
      _showMessage('Impossible de téléverser le reçu de paiement.');
    }
  }

  Future<void> _pickBirthDate() async {
    final today = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate:
          _dateNaissance ?? DateTime(today.year - 18, today.month, today.day),
      firstDate: DateTime(1900),
      lastDate: today,
      helpText: 'Date de naissance',
      cancelText: 'Annuler',
      confirmText: 'Choisir',
      builder: (context, child) =>
          Theme(data: _buildTheme(context), child: child!),
    );
    if (selected != null) setState(() => _dateNaissance = selected);
  }

  bool _validateDynamicForm() {
    final fields = _publishedForm?['champs'];
    if (fields is! List) return true;
    for (final rawField in fields.whereType<Map>()) {
      final field = Map<String, dynamic>.from(rawField);
      if (field['actif'] != true || field['obligatoire'] != true) continue;
      final key = field['label']?.toString() ?? '';
      final value = _formAnswers[key];
      final empty =
          value == null ||
          (value is String && value.trim().isEmpty) ||
          (value is List && value.isEmpty);
      if (empty) {
        _showMessage('Le champ « $key » est obligatoire.');
        return false;
      }
    }
    return true;
  }

  String? _paymentOperatorError() {
    if (_modePaiement == 'ESPECES') return null;
    var digits = _telephoneController.text.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('261')) digits = '0${digits.substring(3)}';
    final prefixes = switch (_modePaiement) {
      'MVOLA' => ['034', '038'],
      'ORANGE_MONEY' => ['032', '037'],
      'AIRTEL_MONEY' => ['033', '035'],
      _ => <String>[],
    };
    final label = _paymentLabel(_modePaiement);
    if (digits.length != 10) {
      return 'Le numéro doit comporter 10 chiffres pour utiliser $label.';
    }
    if (!prefixes.contains(digits.substring(0, 3))) {
      return 'Pour $label, le numéro doit commencer par ${prefixes.join(' ou ')}.';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Navigation entre étapes
  // ---------------------------------------------------------------------------

  void _setStep(int step) {
    setState(() {
      _currentStep = step;
      _errorMessage = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
    });
  }

  void _goToNextStep() {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      _showMessage('Corrige les champs en rouge pour continuer.');
      return;
    }

    if (_avatarUrl == null) {
      _showMessage('La photo de profil est obligatoire.');
      return;
    }
    if (_isUploadingAvatar) {
      _showMessage('Attends la fin du téléversement de la photo.');
      return;
    }

    if (_isApprenant) {
      _setStep(_stepDynamicForm);
    } else {
      _setStep(_stepConfirm);
    }
  }

  void _continueFromDynamicForm() {
    if (_selectedFormation == null) {
      _showMessage('Choisis une formation.');
      return;
    }
    if (!(_dynamicFormKey.currentState?.validate() ?? false)) {
      _showMessage('Choisis une formation pour continuer.');
      return;
    }
    if (!_validateDynamicForm()) return;
    _setStep(_stepPayment);
  }

  void _validatePaymentStep() {
    FocusScope.of(context).unfocus();
    if (!(_paymentFormKey.currentState?.validate() ?? false)) return;
    final operatorError = _paymentOperatorError();
    if (operatorError != null) {
      _showMessage(operatorError);
      return;
    }
    if (_isUploadingReceipt) {
      _showMessage('Attends la fin du téléversement du reçu.');
      return;
    }
    _setStep(_stepConfirm);
  }

  void _goBack() {
    if (_isLocked) {
      _showMessage(
        'La demande est déjà créée. Réessaie l’enregistrement du paiement.',
      );
      return;
    }

    if (_currentStep == _stepConfirm) {
      _setStep(_isApprenant ? _stepPayment : _stepForm);
    } else if (_currentStep == _stepPayment) {
      _setStep(_stepDynamicForm);
    } else if (_currentStep == _stepDynamicForm) {
      _setStep(_stepForm);
    }
  }

  // ---------------------------------------------------------------------------
  // Envoi
  // ---------------------------------------------------------------------------

  Future<void> _submitRegistration() async {
    if (_isSubmitting) return;

    final formation = _selectedFormation;
    final formationId = int.tryParse(_formationId ?? '');

    if (_isApprenant && (formation == null || formationId == null)) {
      setState(() {
        _errorMessage = 'La formation sélectionnée est invalide.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      if (!_accountCreated) {
        final email = _emailController.text.trim().toLowerCase();

        final body = <String, dynamic>{
          'prenom': _prenomController.text.trim(),
          'nom': _nomController.text.trim(),
          'email': email,
          'adresse': _adresseController.text.trim(),
          'telephone': _telephoneController.text.trim(),
          'password': _passwordController.text,
          'role': _role,
          'genre': _genre,
        };

        if (_isApprenant && formation != null) {
          body['formationSouhaitee'] = formation['titre'];
          // Plus fiable que le titre : à activer quand le backend l'accepte.
          // body['formationId'] = formationId;
        }

        body['dateNaissance'] = _dateNaissance == null
            ? null
            : '${_dateNaissance!.year.toString().padLeft(4, '0')}-'
                  '${_dateNaissance!.month.toString().padLeft(2, '0')}-'
                  '${_dateNaissance!.day.toString().padLeft(2, '0')}';
        body['avatarPhoto'] = _avatarUrl;
        if (_isApprenant) {
          body['reponsesFormulaire'] = _formAnswers.isEmpty
              ? null
              : jsonEncode(_formAnswers);
          body['preuvePaiement'] = _receiptUrl;
        }

        final response = await _dio.post('/api/auth/register', data: body);
        _accountCreated = true;
        if (response.data is Map) {
          _numeroDossier = (response.data as Map)['numeroDossier']?.toString();
        }

        if (_isApprenant && _registrationFee > 0) {
          // NB : le backend doit recalculer le montant à partir de formationId
          // et ne jamais faire confiance à la valeur envoyée par le client.
          _pendingPaymentRequest = {
            'email': email,
            'formationId': formationId,
            'montant': _registrationFee,
            'modePaiement': _modePaiement,
            'referenceTransaction': _modePaiement == 'ESPECES'
                ? null
                : _referenceController.text.trim(),
          };
        }
      }

      if (_isApprenant && _registrationFee > 0) {
        await _dio.post(
          '/api/finance/droit-inscription',
          data: _pendingPaymentRequest,
        );
      }

      if (!mounted) return;
      setState(() {
        _registrationSent = true;
        _numeroDossier ??=
            'DOS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
        _isSubmitting = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      final reason = _registrationErrorMessage(e);
      setState(() {
        _errorMessage = _accountCreated && _isApprenant
            ? 'Compte créé, mais paiement non enregistré : $reason '
                  'Réessaie pour enregistrer le paiement sans recréer le compte.'
            : reason;
        _isSubmitting = false;
      });
    } catch (e) {
      debugPrint('Erreur inscription : $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Une erreur inattendue est survenue. Réessaie.';
        _isSubmitting = false;
      });
    }
  }

  String _registrationErrorMessage(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    if (statusCode == 409) return 'Cette adresse e-mail est déjà utilisée.';

    if (data is String && data.trim().isNotEmpty && data.length < 200) {
      return data.trim();
    }

    if (data is Map) {
      for (final key in ['message', 'error']) {
        final value = data[key];
        if (value is String && value.trim().isNotEmpty) return value.trim();
      }

      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
        return first.toString();
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return 'Impossible de joindre le serveur. Vérifie ta connexion réseau.';
      default:
        break;
    }

    if (statusCode != null) {
      return 'Le serveur a refusé l’inscription (HTTP $statusCode).';
    }

    return 'Échec de l’inscription. Réessaie.';
  }

  // ---------------------------------------------------------------------------
  // Utilitaires
  // ---------------------------------------------------------------------------

  String _formatAr(double amount) {
    final value = amount.toStringAsFixed(0);
    final buffer = StringBuffer();

    for (var i = 0; i < value.length; i++) {
      buffer.write(value[i]);
      final remaining = value.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) buffer.write(' ');
    }

    return '$buffer Ar';
  }

  String _paymentLabel(String value) {
    switch (value) {
      case 'ESPECES':
        return 'Espèces';
      case 'MVOLA':
        return 'MVola';
      case 'ORANGE_MONEY':
        return 'Orange Money';
      case 'AIRTEL_MONEY':
        return 'Airtel Money';
      default:
        return value;
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: _surfaceColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: _goldColor),
          ),
        ),
      );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  ThemeData _buildTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _backgroundColor,
      canvasColor: _surfaceColor,
      colorScheme: const ColorScheme.dark(
        primary: _goldColor,
        onPrimary: _backgroundColor,
        secondary: _goldLightColor,
        onSecondary: _backgroundColor,
        surface: _surfaceColor,
        onSurface: _textColor,
        error: Colors.redAccent,
        onError: Colors.white,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: _goldColor,
        selectionColor: Color(0x665A4A20),
        selectionHandleColor: _goldColor,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _goldColor,
      ),
      dividerTheme: const DividerThemeData(color: _borderColor, thickness: 1),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: _surfaceColor,
        contentTextStyle: TextStyle(color: _textColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _buildTheme(context),
      // Le bouton retour système suit la logique des étapes.
      child: PopScope(
        canPop:
            _registrationSent ||
            (_currentStep == _stepForm && !_accountCreated),
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _goBack();
        },
        child: Scaffold(
          backgroundColor: _backgroundColor,
          appBar: AppBar(
            backgroundColor: _surfaceColor,
            foregroundColor: _goldLightColor,
            elevation: 0,
            centerTitle: true,
            title: const Text(
              'Inscription YMS',
              style: TextStyle(
                color: _goldLightColor,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            leading:
                _currentStep > _stepForm && !_registrationSent && !_isLocked
                ? IconButton(
                    tooltip: 'Étape précédente',
                    onPressed: _goBack,
                    icon: const Icon(Icons.arrow_back),
                  )
                : null,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                color: _goldColor.withValues(alpha: 0.45),
              ),
            ),
          ),
          body: SafeArea(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusScope.of(context).unfocus(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: _registrationSent
                      ? _buildSuccessScreen()
                      : SingleChildScrollView(
                          controller: _scrollController,
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.all(20),
                          child: DefaultTextStyle(
                            style: const TextStyle(color: _textColor),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildStepIndicator(),
                                const SizedBox(height: 28),
                                if (_currentStep == _stepForm)
                                  _buildRegistrationForm(),
                                if (_currentStep == _stepDynamicForm)
                                  _buildDynamicFormStep(),
                                if (_currentStep == _stepPayment)
                                  _buildPaymentStep(),
                                if (_currentStep == _stepConfirm)
                                  _buildConfirmationStep(),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Indicateur d'étapes
  // ---------------------------------------------------------------------------

  Widget _buildStepIndicator() {
    final labels = _isApprenant
        ? ['Inscription', 'Formation', 'Paiement', 'Confirmation']
        : ['Inscription', 'Confirmation'];

    final activeIndex = _isApprenant
        ? _currentStep
        : (_currentStep == _stepForm ? 0 : 1);

    final children = <Widget>[];

    for (var i = 0; i < labels.length; i++) {
      final done = i < activeIndex;
      final active = i <= activeIndex;

      children.add(
        Semantics(
          label:
              'Étape ${i + 1} sur ${labels.length} : ${labels[i]}'
              '${i == activeIndex
                  ? ', en cours'
                  : done
                  ? ', terminée'
                  : ''}',
          excludeSemantics: true,
          child: SizedBox(
            width: 84,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: active ? _goldColor : _fieldColor,
                  child: done
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: _backgroundColor,
                        )
                      : Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: active ? _backgroundColor : _mutedColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 6),
                Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    color: active ? _goldLightColor : _mutedColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      if (i < labels.length - 1) {
        children.add(
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Container(
                height: 2,
                color: i < activeIndex ? _goldColor : _borderColor,
              ),
            ),
          ),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Étape 1 : formulaire
  // ---------------------------------------------------------------------------

  Widget _buildRegistrationForm() {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _screenTitle('Créer un compte'),
            const SizedBox(height: 8),
            const Text(
              'Remplis les informations pour envoyer ta demande.',
              style: TextStyle(color: _mutedColor, height: 1.5),
            ),
            const SizedBox(height: 28),

            _sectionTitle('Je souhaite m’inscrire comme'),
            Row(
              children: [
                Expanded(
                  child: _roleCard(
                    value: 'ROLE_APPRENANT',
                    label: 'Apprenant',
                    icon: Icons.school_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _roleCard(
                    value: 'ROLE_FORMATEUR',
                    label: 'Formateur',
                    icon: Icons.co_present_outlined,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            _buildAvatarPicker(),
            const SizedBox(height: 26),
            _sectionTitle('Informations personnelles'),

            _textField(
              controller: _prenomController,
              label: 'Prénom',
              validator: RegisterRules.requiredField,
              prefixIcon: Icons.person_outline,
              autofillHints: const [AutofillHints.givenName],
              textCapitalization: TextCapitalization.words,
            ),
            _textField(
              controller: _nomController,
              label: 'Nom',
              validator: RegisterRules.requiredField,
              prefixIcon: Icons.badge_outlined,
              autofillHints: const [AutofillHints.familyName],
              textCapitalization: TextCapitalization.words,
            ),
            _textField(
              controller: _emailController,
              label: 'Adresse e-mail',
              keyboardType: TextInputType.emailAddress,
              validator: RegisterRules.email,
              prefixIcon: Icons.email_outlined,
              autofillHints: const [AutofillHints.email],
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'\s')),
              ],
            ),
            _textField(
              controller: _adresseController,
              label: 'Adresse',
              validator: RegisterRules.requiredField,
              prefixIcon: Icons.location_on_outlined,
              autofillHints: const [AutofillHints.fullStreetAddress],
              textCapitalization: TextCapitalization.sentences,
            ),
            _textField(
              controller: _telephoneController,
              label: 'Téléphone',
              hint: '034 00 000 00',
              keyboardType: TextInputType.phone,
              validator: RegisterRules.phone,
              prefixIcon: Icons.phone_outlined,
              autofillHints: const [AutofillHints.telephoneNumber],
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+()\s-]')),
                LengthLimitingTextInputFormatter(20),
              ],
            ),

            InkWell(
              onTap: _pickBirthDate,
              borderRadius: BorderRadius.circular(14),
              child: InputDecorator(
                decoration: _decoration('Date de naissance (facultatif)')
                    .copyWith(
                      prefixIcon: const Icon(
                        Icons.calendar_today_outlined,
                        color: _mutedColor,
                      ),
                      suffixIcon: _dateNaissance == null
                          ? const Icon(
                              Icons.arrow_drop_down,
                              color: _mutedColor,
                            )
                          : IconButton(
                              tooltip: 'Effacer la date',
                              onPressed: () =>
                                  setState(() => _dateNaissance = null),
                              icon: const Icon(Icons.close, color: _mutedColor),
                            ),
                    ),
                child: Text(
                  _dateNaissance == null
                      ? 'Sélectionner une date'
                      : '${_dateNaissance!.day.toString().padLeft(2, '0')}/'
                            '${_dateNaissance!.month.toString().padLeft(2, '0')}/'
                            '${_dateNaissance!.year}',
                  style: TextStyle(
                    color: _dateNaissance == null ? _mutedColor : _textColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _genre,
              isExpanded: true,
              dropdownColor: _surfaceColor,
              style: const TextStyle(color: _textColor),
              iconEnabledColor: _goldColor,
              decoration: _decoration('Genre').copyWith(
                prefixIcon: const Icon(Icons.wc_outlined, color: _mutedColor),
              ),
              items: const [
                DropdownMenuItem(value: 'FEMININ', child: Text('Féminin')),
                DropdownMenuItem(value: 'MASCULIN', child: Text('Masculin')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _genre = value);
              },
            ),

            const SizedBox(height: 28),
            _sectionTitle('Sécurité'),

            _textField(
              controller: _passwordController,
              label: 'Mot de passe',
              hint: '8 caractères min., 1 chiffre',
              obscureText: _obscurePassword,
              validator: RegisterRules.password,
              prefixIcon: Icons.lock_outline,
              autofillHints: const [AutofillHints.newPassword],
              bottomPadding: 8,
              suffixIcon: IconButton(
                tooltip: _obscurePassword
                    ? 'Afficher le mot de passe'
                    : 'Masquer le mot de passe',
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: _goldLightColor,
                ),
              ),
            ),
            _buildPasswordStrength(),

            _textField(
              controller: _confirmPasswordController,
              label: 'Confirmer le mot de passe',
              obscureText: _obscureConfirmPassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Confirme ton mot de passe.';
                }
                if (value != _passwordController.text) {
                  return 'Les mots de passe ne correspondent pas.';
                }
                return null;
              },
              prefixIcon: Icons.lock_reset_outlined,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.done,
              suffixIcon: IconButton(
                tooltip: _obscureConfirmPassword
                    ? 'Afficher le mot de passe'
                    : 'Masquer le mot de passe',
                onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: _goldLightColor,
                ),
              ),
            ),

            const SizedBox(height: 10),
            _infoBox(
              icon: Icons.verified_user_outlined,
              text:
                  'Ton compte sera activé après vérification de ta demande '
                  'par l’administration YMS.',
            ),

            const SizedBox(height: 26),
            _primaryButton(
              label: _isApprenant
                  ? 'Continuer vers la formation'
                  : 'Vérifier mes informations',
              icon: Icons.arrow_forward_rounded,
              onPressed: (_isLoadingFormations && _isApprenant)
                  ? null
                  : _goToNextStep,
            ),

            const SizedBox(height: 12),
            const Text(
              'YMS • Youth Malagasy Service',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _mutedColor,
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicFormStep() {
    final rawFields = _publishedForm?['champs'];
    final fields = rawFields is List
        ? rawFields
              .whereType<Map>()
              .map((field) => Map<String, dynamic>.from(field))
              .where((field) => field['actif'] == true)
              .toList()
        : <Map<String, dynamic>>[];
    fields.sort(
      (a, b) => ((a['ordre'] as num?)?.toInt() ?? 0).compareTo(
        (b['ordre'] as num?)?.toInt() ?? 0,
      ),
    );

    return Form(
      key: _dynamicFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _screenTitle('Formation souhaitée'),
          const SizedBox(height: 8),
          const Text(
            'Sélectionne ton parcours et complète les informations demandées.',
            style: TextStyle(color: _mutedColor, height: 1.5),
          ),
          const SizedBox(height: 24),
          _sectionTitle('Formation'),
          _buildFormationPicker(),
          if (_selectedFormation != null) ...[
            const SizedBox(height: 12),
            _buildPriceCard(),
          ],
          if (_isLoadingForm)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (fields.isNotEmpty) ...[
            const SizedBox(height: 26),
            _sectionTitle(
              _publishedForm?['titre']?.toString().trim().isNotEmpty == true
                  ? _publishedForm!['titre'].toString()
                  : 'Informations complémentaires',
            ),
            if ((_publishedForm?['description'] as String?)?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  _publishedForm!['description'].toString(),
                  style: const TextStyle(color: _mutedColor, height: 1.5),
                ),
              ),
            ...fields.map(_buildDynamicField),
          ] else if (_publishedForm == null)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: _infoBox(
                icon: Icons.info_outline,
                text:
                    'Aucun formulaire complémentaire n’est configuré pour cette formation.',
              ),
            ),
          if (_errorMessage != null) _buildErrorMessage(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLocked ? null : _goBack,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Retour'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _goldLightColor,
                    side: const BorderSide(color: _borderColor),
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _primaryButton(
                  label: 'Continuer vers le paiement',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: _isLoadingForm ? null : _continueFromDynamicForm,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicField(Map<String, dynamic> field) {
    final label = field['label']?.toString() ?? '';
    final type = field['typeChamp']?.toString() ?? 'TEXT';
    final required = field['obligatoire'] == true;
    final currentValue = _formAnswers[label];
    final options = _parseOptions(field['options']);

    Widget input;
    switch (type) {
      case 'TEXT':
      case 'NUMBER':
        input = TextFormField(
          key: ValueKey('dynamic-$label'),
          initialValue: currentValue?.toString() ?? '',
          keyboardType: type == 'NUMBER'
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          decoration: _decoration(
            label,
          ).copyWith(hintText: field['placeholder']?.toString()),
          onChanged: (value) => setState(() => _formAnswers[label] = value),
        );
        break;
      case 'TEXTAREA':
        input = TextFormField(
          key: ValueKey('dynamic-$label'),
          initialValue: currentValue?.toString() ?? '',
          minLines: 3,
          maxLines: 5,
          keyboardType: TextInputType.multiline,
          decoration: _decoration(label).copyWith(
            hintText: field['placeholder']?.toString(),
            alignLabelWithHint: true,
          ),
          onChanged: (value) => setState(() => _formAnswers[label] = value),
        );
        break;
      case 'DATE':
        input = InkWell(
          onTap: () async {
            final selected = await showDatePicker(
              context: context,
              initialDate:
                  DateTime.tryParse(currentValue?.toString() ?? '') ??
                  DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
              builder: (context, child) =>
                  Theme(data: _buildTheme(context), child: child!),
            );
            if (selected != null) {
              setState(() {
                _formAnswers[label] =
                    '${selected.year.toString().padLeft(4, '0')}-'
                    '${selected.month.toString().padLeft(2, '0')}-'
                    '${selected.day.toString().padLeft(2, '0')}';
              });
            }
          },
          child: InputDecorator(
            decoration: _decoration(label).copyWith(
              suffixIcon: const Icon(
                Icons.calendar_today_outlined,
                color: _mutedColor,
              ),
            ),
            child: Text(
              currentValue?.toString().isNotEmpty == true
                  ? currentValue.toString()
                  : required
                  ? 'Choisir une date *'
                  : 'Choisir une date',
              style: TextStyle(
                color: currentValue?.toString().isNotEmpty == true
                    ? _textColor
                    : _mutedColor,
              ),
            ),
          ),
        );
        break;
      case 'SELECT':
        final selected = options.contains(currentValue)
            ? currentValue as String
            : null;
        input = DropdownButtonFormField<String>(
          initialValue: selected,
          isExpanded: true,
          dropdownColor: _surfaceColor,
          decoration: _decoration(label),
          items: options
              .map(
                (option) =>
                    DropdownMenuItem(value: option, child: Text(option)),
              )
              .toList(),
          onChanged: (value) => setState(() => _formAnswers[label] = value),
        );
        break;
      case 'CHECKBOX':
        final choices = options.isEmpty ? ['Oui'] : options;
        final checked = currentValue is List
            ? currentValue.map((value) => value.toString()).toSet()
            : <String>{};
        input = Column(
          children: choices.map((option) {
            return CheckboxListTile(
              value: checked.contains(option),
              title: Text(option, style: const TextStyle(color: _textColor)),
              activeColor: _goldColor,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (value) {
                final next = {...checked};
                if (value == true) {
                  next.add(option);
                } else {
                  next.remove(option);
                }
                setState(() => _formAnswers[label] = next.toList());
              },
            );
          }).toList(),
        );
        break;
      case 'PHOTO':
      case 'DOCUMENT':
        final fieldId = field['id'] is num ? (field['id'] as num).toInt() : 0;
        final uploaded = currentValue is Map ? currentValue : null;
        input = OutlinedButton.icon(
          onPressed: _uploadingFieldId == fieldId
              ? null
              : () => _pickDynamicFile(field),
          icon: _uploadingFieldId == fieldId
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  type == 'PHOTO'
                      ? Icons.add_photo_alternate_outlined
                      : Icons.upload_file,
                ),
          label: Text(
            _uploadingFieldId == fieldId
                ? 'Téléversement…'
                : uploaded?['filename']?.toString() ??
                      (type == 'PHOTO'
                          ? 'Choisir une image'
                          : 'Choisir un document'),
            overflow: TextOverflow.ellipsis,
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: _goldLightColor,
            side: const BorderSide(color: _borderColor),
            minimumSize: const Size.fromHeight(50),
          ),
        );
        break;
      default:
        input = TextFormField(
          key: ValueKey('dynamic-$label'),
          initialValue: currentValue?.toString() ?? '',
          decoration: _decoration(label),
          onChanged: (value) => setState(() => _formAnswers[label] = value),
        );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label${required ? ' *' : ''}',
            style: const TextStyle(
              color: _textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          if ((field['description'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(
              field['description'].toString(),
              style: const TextStyle(color: _mutedColor, fontSize: 12),
            ),
          ],
          const SizedBox(height: 8),
          input,
        ],
      ),
    );
  }

  Widget _buildAvatarPicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _avatarUrl == null
              ? _goldColor.withValues(alpha: 0.55)
              : _borderColor,
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 68,
              height: 68,
              child: _avatarBytes == null
                  ? Container(
                      color: _fieldColor,
                      child: const Icon(
                        Icons.person_outline,
                        color: _goldLightColor,
                        size: 34,
                      ),
                    )
                  : Image.memory(_avatarBytes!, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Photo de profil *',
                  style: TextStyle(
                    color: _textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isUploadingAvatar
                      ? 'Téléversement en cours…'
                      : _avatarFileName ?? 'JPG, PNG ou WebP — 5 Mo maximum',
                  style: const TextStyle(color: _mutedColor, fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _isUploadingAvatar
                          ? null
                          : _showAvatarSourcePicker,
                      icon: const Icon(Icons.add_a_photo_outlined, size: 16),
                      label: Text(_avatarBytes == null ? 'Ajouter' : 'Changer'),
                    ),
                    if (_avatarBytes != null)
                      TextButton(
                        onPressed: _isUploadingAvatar
                            ? null
                            : () => setState(() {
                                _avatarBytes = null;
                                _avatarUrl = null;
                                _avatarFileName = null;
                              }),
                        child: const Text('Retirer'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormationPicker() {
    if (_isLoadingFormations) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_formations.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: _goldColor,
              size: 30,
            ),
            const SizedBox(height: 8),
            Text(
              _formationsError ?? 'Aucune formation disponible pour le moment.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _mutedColor),
            ),
            TextButton.icon(
              onPressed: _loadFormations,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: TextButton.styleFrom(foregroundColor: _goldLightColor),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: _formationId,
      isExpanded: true,
      dropdownColor: _surfaceColor,
      style: const TextStyle(color: _textColor),
      iconEnabledColor: _goldColor,
      decoration: _decoration('Choisir une formation').copyWith(
        prefixIcon: const Icon(Icons.school_outlined, color: _mutedColor),
      ),
      items: _formations
          .map(
            (formation) => DropdownMenuItem<String>(
              value: formation['id'].toString(),
              child: Text(
                formation['titre'].toString(),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      validator: (value) => value == null ? 'Choisis une formation.' : null,
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _formationId = value;
          _formAnswers.clear();
        });
        final selectedId = int.tryParse(value);
        if (selectedId != null) _loadPublishedFormulaire(selectedId);
      },
    );
  }

  Widget _buildPasswordStrength() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _passwordController,
      builder: (context, value, _) {
        if (value.text.isEmpty) return const SizedBox(height: 8);

        final score = RegisterRules.passwordScore(value.text);
        const labels = ['Très faible', 'Faible', 'Moyen', 'Bon', 'Excellent'];
        const colors = [
          Colors.redAccent,
          Colors.deepOrangeAccent,
          Colors.amber,
          Colors.lightGreen,
          Colors.greenAccent,
        ];

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Semantics(
            label: 'Force du mot de passe : ${labels[score]}',
            excludeSemantics: true,
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (score + 1) / 5,
                      minHeight: 5,
                      backgroundColor: _borderColor,
                      color: colors[score],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  labels[score],
                  style: TextStyle(fontSize: 12, color: colors[score]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _roleCard({
    required String value,
    required String label,
    required IconData icon,
  }) {
    final selected = _role == value;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          if (selected) {
            return;
          }
          setState(() {
            _role = value;
            _formationId = null;
            _errorMessage = null;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: selected
                ? _goldColor.withValues(alpha: 0.12)
                : _surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? _goldColor : _borderColor,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? _goldLightColor : _mutedColor,
                size: 26,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: selected ? _goldLightColor : _textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Étape 2 : paiement
  // ---------------------------------------------------------------------------

  Widget _buildPaymentStep() {
    return Form(
      key: _paymentFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _screenTitle('Droit d’inscription'),
          const SizedBox(height: 8),
          const Text(
            'Vérifie la formation et choisis ton moyen de paiement.',
            style: TextStyle(color: _mutedColor, height: 1.5),
          ),
          const SizedBox(height: 24),

          _buildPriceCard(),

          if (_registrationFee <= 0) ...[
            const SizedBox(height: 18),
            _infoBox(
              icon: Icons.verified_outlined,
              highlighted: true,
              text:
                  'Cette formation ne nécessite aucun droit d’inscription. '
                  'Tu peux continuer directement vers le récapitulatif.',
            ),
            const SizedBox(height: 28),
            _primaryButton(
              label: 'Continuer',
              icon: Icons.arrow_forward_rounded,
              onPressed: _validatePaymentStep,
            ),
          ] else ...[
            const SizedBox(height: 28),
            _sectionTitle('Moyen de paiement'),

            RadioGroup<String>(
              groupValue: _modePaiement,
              onChanged: (value) {
                if (value != null) setState(() => _modePaiement = value);
              },
              child: Column(
                children: [
                  _paymentOption(
                    value: 'ESPECES',
                    title: 'Espèces',
                    subtitle: 'Paiement au bureau',
                    icon: Icons.payments_outlined,
                  ),
                  _paymentOption(
                    value: 'MVOLA',
                    title: 'MVola',
                    subtitle: 'Paiement mobile MVola',
                    icon: Icons.phone_android,
                  ),
                  _paymentOption(
                    value: 'ORANGE_MONEY',
                    title: 'Orange Money',
                    subtitle: 'Paiement mobile Orange Money',
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                  _paymentOption(
                    value: 'AIRTEL_MONEY',
                    title: 'Airtel Money',
                    subtitle: 'Paiement mobile Airtel Money',
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                ],
              ),
            ),

            if (_modePaiement != 'ESPECES') ...[
              const SizedBox(height: 18),
              _textField(
                controller: _referenceController,
                label: 'Référence de transaction',
                validator: RegisterRules.requiredField,
                prefixIcon: Icons.receipt_long_outlined,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [LengthLimitingTextInputFormatter(30)],
              ),
              _infoBox(
                icon: Icons.info_outline,
                text:
                    'La référence sera enregistrée avec ta demande. '
                    'L’administration vérifiera le paiement avant de valider '
                    'ton inscription.',
              ),
            ],

            if (_paymentOperatorError() != null) ...[
              const SizedBox(height: 10),
              _infoBox(
                icon: Icons.warning_amber_rounded,
                text: _paymentOperatorError()!,
              ),
            ],

            const SizedBox(height: 18),
            _sectionTitle('Preuve de paiement (facultatif)'),
            OutlinedButton.icon(
              onPressed: _isUploadingReceipt ? null : _pickReceipt,
              icon: _isUploadingReceipt
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file_outlined),
              label: Text(
                _isUploadingReceipt
                    ? 'Téléversement en cours…'
                    : _receiptFileName ?? 'Joindre un reçu ou une capture',
                overflow: TextOverflow.ellipsis,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _goldLightColor,
                side: const BorderSide(color: _borderColor),
                minimumSize: const Size.fromHeight(50),
              ),
            ),

            const SizedBox(height: 28),
            _primaryButton(
              label: 'Continuer',
              icon: Icons.arrow_forward_rounded,
              onPressed: _validatePaymentStep,
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Étape 3 : confirmation
  // ---------------------------------------------------------------------------

  Widget _buildConfirmationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _screenTitle('Vérifier ma demande'),
        const SizedBox(height: 8),
        const Text(
          'Vérifie les informations avant d’envoyer ta demande.',
          style: TextStyle(color: _mutedColor, height: 1.5),
        ),
        const SizedBox(height: 24),

        _summaryCard(
          title: 'Informations personnelles',
          rows: {
            'Nom complet':
                '${_prenomController.text.trim()} ${_nomController.text.trim()}',
            'E-mail': _emailController.text.trim().toLowerCase(),
            'Téléphone': _telephoneController.text.trim(),
            'Adresse': _adresseController.text.trim(),
            'Date de naissance': _dateNaissance == null
                ? ''
                : '${_dateNaissance!.day.toString().padLeft(2, '0')}/'
                      '${_dateNaissance!.month.toString().padLeft(2, '0')}/'
                      '${_dateNaissance!.year}',
            'Photo de profil': _avatarFileName ?? '',
            'Genre': _genre == 'FEMININ' ? 'Féminin' : 'Masculin',
            'Rôle': _isApprenant ? 'Apprenant' : 'Formateur',
          },
        ),

        if (_isApprenant) ...[
          const SizedBox(height: 16),
          _summaryCard(
            title: 'Formation et formulaire',
            rows: {
              'Formation':
                  _selectedFormation?['titre']?.toString() ?? 'Non choisie',
              ..._formAnswers.map(
                (key, value) => MapEntry(
                  key,
                  value is Map
                      ? value['filename']?.toString() ?? ''
                      : value is List
                      ? value.join(', ')
                      : value?.toString() ?? '',
                ),
              ),
            },
          ),
          const SizedBox(height: 16),
          _summaryCard(
            title: 'Paiement',
            rows: _registrationFee <= 0
                ? {'Droit d’inscription': 'Gratuit'}
                : {
                    'Droit d’inscription': _formatAr(_registrationFee),
                    'Moyen de paiement': _paymentLabel(_modePaiement),
                    if (_modePaiement != 'ESPECES')
                      'Référence': _referenceController.text.trim(),
                    'Preuve de paiement': ?_receiptFileName,
                  },
          ),
          if (_registrationFee > 0) ...[
            const SizedBox(height: 14),
            _infoBox(
              icon: Icons.info_outline,
              highlighted: true,
              text:
                  'Le paiement sera enregistré comme étant en attente. '
                  'L’administration confirmera sa réception avant de valider '
                  'ton inscription.',
            ),
          ],
        ],

        if (_errorMessage != null) _buildErrorMessage(),

        const SizedBox(height: 28),
        _primaryButton(
          label: _isSubmitting
              ? 'Envoi en cours...'
              : _accountCreated
              ? 'Réessayer le paiement'
              : 'Envoyer ma demande',
          icon: Icons.check_circle_outline,
          loading: _isSubmitting,
          onPressed: _isSubmitting ? null : _submitRegistration,
        ),
      ],
    );
  }

  Widget _buildSuccessScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 48),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: _surfaceColor,
              shape: BoxShape.circle,
              border: Border.all(color: _goldColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: _goldColor.withValues(alpha: 0.12),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 58,
              color: _goldLightColor,
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Demande envoyée !',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _goldLightColor,
            ),
          ),
          if (_numeroDossier != null) ...[
            const SizedBox(height: 16),
            _infoBox(
              icon: Icons.confirmation_number_outlined,
              text: 'Numéro de dossier : $_numeroDossier',
              highlighted: true,
            ),
          ],
          const SizedBox(height: 14),
          const Text(
            'Ta demande d’inscription a été transmise. L’équipe YMS va '
            'l’examiner et te prévenir par e-mail. Tu pourras te connecter '
            'après validation.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _mutedColor, height: 1.6),
          ),
          if (_isApprenant && _registrationFee > 0) ...[
            const SizedBox(height: 24),
            _buildPriceCard(),
            const SizedBox(height: 14),
            const Text(
              'Le paiement est enregistré en attente de confirmation '
              'par l’administration.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: _mutedColor, height: 1.5),
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.login),
              label: const Text('Retour à la connexion'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _goldLightColor,
                side: const BorderSide(color: _goldColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Composants
  // ---------------------------------------------------------------------------

  Widget _buildPriceCard() {
    final formation = _selectedFormation;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _goldColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _goldColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school_outlined,
                  color: _goldLightColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Formation sélectionnée',
                  style: TextStyle(fontSize: 13, color: _mutedColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            formation?['titre']?.toString() ?? 'Aucune formation',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: _textColor,
              height: 1.4,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: _borderColor),
          ),
          const Text(
            'Droit d’inscription',
            style: TextStyle(fontSize: 13, color: _mutedColor),
          ),
          const SizedBox(height: 6),
          Text(
            _registrationFee > 0
                ? _formatAr(_registrationFee)
                : 'Formation gratuite (0 Ar)',
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.bold,
              color: _goldLightColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = _modePaiement == value;

    return Card(
      color: _surfaceColor,
      elevation: selected ? 3 : 0,
      shadowColor: _goldColor.withValues(alpha: 0.12),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? _goldColor : _borderColor,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: RadioListTile<String>(
        value: value,
        secondary: Icon(
          icon,
          color: selected ? _goldLightColor : _mutedColor,
          size: 26,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: _textColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: _mutedColor, fontSize: 12),
        ),
        activeColor: _goldColor,
        controlAffinity: ListTileControlAffinity.trailing,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      ),
    );
  }

  Widget _summaryCard({
    required String title,
    required Map<String, String> rows,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(title, bottom: 0),
          const Divider(height: 28, color: _borderColor),
          ...rows.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      entry.key,
                      style: const TextStyle(color: _mutedColor, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 6,
                    child: Text(
                      entry.value.isEmpty ? '—' : entry.value,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _textColor,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    IconData? prefixIcon,
    Iterable<String>? autofillHints,
    List<TextInputFormatter>? inputFormatters,
    TextInputAction textInputAction = TextInputAction.next,
    TextCapitalization textCapitalization = TextCapitalization.none,
    double bottomPadding = 16,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        obscureText: obscureText,
        autofillHints: autofillHints,
        inputFormatters: inputFormatters,
        textInputAction: textInputAction,
        textCapitalization: textCapitalization,
        autocorrect: !obscureText && keyboardType != TextInputType.emailAddress,
        enableSuggestions: !obscureText,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        style: const TextStyle(color: _textColor, fontSize: 14),
        cursorColor: _goldColor,
        decoration: _decoration(label).copyWith(
          hintText: hint,
          hintStyle: TextStyle(
            color: _mutedColor.withValues(alpha: 0.6),
            fontSize: 14,
          ),
          prefixIcon: prefixIcon == null
              ? null
              : Icon(prefixIcon, color: _mutedColor, size: 21),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  InputDecoration _decoration(String label) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _mutedColor, fontSize: 14),
      floatingLabelStyle: const TextStyle(
        color: _goldLightColor,
        fontWeight: FontWeight.w600,
      ),
      filled: true,
      fillColor: _fieldColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: border(_borderColor),
      enabledBorder: border(_borderColor),
      focusedBorder: border(_goldColor, 1.6),
      errorBorder: border(Colors.redAccent),
      focusedErrorBorder: border(Colors.redAccent, 1.5),
      errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
    );
  }

  Widget _screenTitle(String text) {
    return Semantics(
      header: true,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: _goldLightColor,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, {double bottom = 14}) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: _goldColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _goldLightColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox({
    required IconData icon,
    required String text,
    bool highlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlighted
              ? _goldColor.withValues(alpha: 0.45)
              : _borderColor,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _goldLightColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: _mutedColor,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF35191C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Color(0xFFFFB9BD), height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    bool loading = false,
  }) {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _mutedColor,
                ),
              )
            : Icon(icon, color: _backgroundColor),
        label: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: onPressed == null ? _mutedColor : _backgroundColor,
            letterSpacing: 0.2,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _goldColor,
          foregroundColor: _backgroundColor,
          disabledBackgroundColor: _borderColor,
          disabledForegroundColor: _mutedColor,
          elevation: 2,
          shadowColor: _goldColor.withValues(alpha: 0.18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
