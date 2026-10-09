import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../services/api_client.dart';

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

  late final Dio _dio;

  final _formKey = GlobalKey<FormState>();

  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _adresseController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referenceController = TextEditingController();

  int _currentStep = 0;

  String _role = 'ROLE_APPRENANT';
  String _genre = 'FEMININ';
  String _modePaiement = 'ESPECES';

  String? _formationId;
  List<Map<String, dynamic>> _formations = [];

  bool _isLoadingFormations = true;
  bool _isSubmitting = false;
  bool _accountCreated = false;
  Map<String, dynamic>? _pendingPaymentRequest;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _registrationSent = false;

  String? _errorMessage;

  Map<String, dynamic>? get _selectedFormation {
    if (_formationId == null) return null;

    for (final formation in _formations) {
      if (formation['id'].toString() == _formationId) {
        return formation;
      }
    }

    return null;
  }

  double get _registrationFee {
    final value = _selectedFormation?['droitInscription'];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  bool get _isApprenant => _role == 'ROLE_APPRENANT';

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

  // Chargement dynamique des formations et de leur droit d'inscription.
  Future<void> _loadFormations() async {
    setState(() {
      _isLoadingFormations = true;
      _errorMessage = null;
    });

    try {
      final response = await _dio.get('/api/formations');
      final data = response.data;

      List<dynamic> items;

      if (data is List) {
        items = data;
      } else if (data is Map<String, dynamic>) {
        if (data['content'] is List) {
          items = data['content'] as List;
        } else if (data['data'] is List) {
          items = data['data'] as List;
        } else {
          throw Exception('Format de réponse des formations non reconnu.');
        }
      } else {
        throw Exception('Réponse des formations invalide.');
      }

      final formations = items
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .where((item) => item['id'] != null && item['titre'] != null)
          .toList();

      if (!mounted) return;

      setState(() {
        _formations = formations;
        _isLoadingFormations = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingFormations = false;
        _errorMessage =
            'Impossible de charger les formations. '
            'Vérifie la connexion au serveur.';
      });

      debugPrint('Erreur formations : ${e.message}');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingFormations = false;
        _errorMessage = e.toString();
      });
    }
  }

  String _formatAr(double amount) {
    final value = amount.toStringAsFixed(0);
    final buffer = StringBuffer();

    for (int i = 0; i < value.length; i++) {
      buffer.write(value[i]);

      final remaining = value.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write(' ');
      }
    }

    return '${buffer.toString()} Ar';
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ce champ est obligatoire.';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'L’adresse e-mail est obligatoire.';
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
      return 'Adresse e-mail invalide.';
    }

    return null;
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est obligatoire.';
    }

    if (value.length < 8) {
      return '8 caractères minimum.';
    }

    if (!RegExp(r'\d').hasMatch(value)) {
      return 'Ajoute au moins un chiffre.';
    }

    return null;
  }

  String? _confirmPasswordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirme ton mot de passe.';
    }

    if (value != _passwordController.text) {
      return 'Les mots de passe ne correspondent pas.';
    }

    return null;
  }

  void _goToNextStep() {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_isApprenant && _selectedFormation == null) {
      _showMessage('Choisis une formation.');
      return;
    }

    if (_isApprenant && _registrationFee <= 0) {
      _showMessage('Le droit d’inscription de cette formation est invalide.');
      return;
    }

    if (_isApprenant) {
      setState(() => _currentStep = 1);
    } else {
      // Le formateur ne passe pas par le paiement.
      setState(() => _currentStep = 2);
    }
  }

  void _validatePaymentStep() {
    if (_modePaiement != 'ESPECES' &&
        _referenceController.text.trim().isEmpty) {
      _showMessage('Saisis la référence de la transaction mobile.');
      return;
    }

    // Étape suivante : récapitulatif avant envoi.
    setState(() => _currentStep = 2);
  }

  Future<void> _submitRegistration() async {
    if (_isSubmitting) return;

    final formation = _selectedFormation;
    final formationId = int.tryParse(_formationId ?? '');
    if (_isApprenant &&
        (formation == null || formationId == null || _registrationFee <= 0)) {
      setState(() {
        _errorMessage =
            'La formation sélectionnée ou son droit d’inscription est invalide.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      if (!_accountCreated) {
        final body = <String, dynamic>{
          'prenom': _prenomController.text.trim(),
          'nom': _nomController.text.trim(),
          'email': _emailController.text.trim(),
          'adresse': _adresseController.text.trim(),
          'telephone': _telephoneController.text.trim(),
          'password': _passwordController.text,
          'role': _role,
          'genre': _genre,
        };

        if (_isApprenant && formation != null) {
          body['formationSouhaitee'] = formation['titre'];
        }

        await _dio.post('/api/auth/register', data: body);
        _accountCreated = true;

        if (_isApprenant) {
          _pendingPaymentRequest = {
            'email': _emailController.text.trim(),
            'formationId': formationId,
            'montant': _registrationFee,
            'modePaiement': _modePaiement,
            'referenceTransaction': _modePaiement == 'ESPECES'
                ? null
                : _referenceController.text.trim(),
          };
        }
      }

      if (_isApprenant) {
        await _dio.post(
          '/api/finance/droit-inscription',
          data: _pendingPaymentRequest,
        );
      }

      if (!mounted) return;

      setState(() {
        _registrationSent = true;
        _isSubmitting = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = _accountCreated && _isApprenant
            ? 'Compte créé, mais paiement non enregistré : '
                  '${_registrationErrorMessage(e)} '
                  'Réessaie pour enregistrer le paiement sans recréer le compte.'
            : _registrationErrorMessage(e);
        _isSubmitting = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Une erreur est survenue : $e';
        _isSubmitting = false;
      });
    }
  }

  String _registrationErrorMessage(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    if (statusCode == 409) {
      return 'Cette adresse e-mail est déjà utilisée.';
    }

    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }

    if (data is Map) {
      for (final key in ['message', 'error']) {
        final value = data[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }

      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          return firstError.first.toString();
        }
        return firstError.toString();
      }
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return 'Impossible de joindre le serveur. Vérifie l’adresse API et la connexion réseau.';
    }

    if (statusCode != null) {
      return 'Le serveur a refusé l’inscription (HTTP $statusCode).';
    }

    return 'Échec de l’inscription. Réessaie.';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
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

  void _goBack() {
    if (_accountCreated && !_registrationSent) {
      _showMessage(
        'La demande est déjà créée. Réessaie l’enregistrement du paiement.',
      );
      return;
    }

    if (_currentStep == 2 && _isApprenant) {
      setState(() => _currentStep = 1);
    } else if (_currentStep > 0) {
      setState(() => _currentStep = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final darkTheme = Theme.of(context).copyWith(
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

    return Theme(
      data: darkTheme,
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
          leading: _currentStep > 0 && !_registrationSent
              ? IconButton(
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
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: _registrationSent
                  ? _buildSuccessScreen()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: DefaultTextStyle(
                        style: const TextStyle(color: _textColor),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildStepIndicator(),
                            const SizedBox(height: 28),
                            if (_currentStep == 0) _buildRegistrationForm(),
                            if (_currentStep == 1) _buildPaymentStep(),
                            if (_currentStep == 2) _buildConfirmationStep(),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    final labels = _isApprenant
        ? ['Inscription', 'Paiement', 'Confirmation']
        : ['Inscription', 'Confirmation'];

    final activeIndex = _isApprenant
        ? _currentStep
        : (_currentStep == 0 ? 0 : 1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final active = index <= activeIndex;

          return Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: active ? _goldColor : _fieldColor,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: active ? _backgroundColor : _mutedColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                      color: active ? _goldLightColor : _mutedColor,
                    ),
                  ),
                ),
                if (index < labels.length - 1)
                  Container(width: 10, height: 1, color: _borderColor),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Créer un compte',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: _goldLightColor,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Remplis les informations pour envoyer ta demande.',
            style: TextStyle(color: _mutedColor, height: 1.5),
          ),
          const SizedBox(height: 28),

          _sectionTitle('Type de compte'),

          DropdownButtonFormField<String>(
            initialValue: _role,
            isExpanded: true,
            dropdownColor: _surfaceColor,
            style: const TextStyle(color: _textColor),
            iconEnabledColor: _goldColor,
            decoration: _decoration('Je souhaite m’inscrire comme'),
            items: const [
              DropdownMenuItem(
                value: 'ROLE_APPRENANT',
                child: Text('Apprenant'),
              ),
              DropdownMenuItem(
                value: 'ROLE_FORMATEUR',
                child: Text('Formateur'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _role = value;
                _formationId = null;
              });
            },
          ),

          const SizedBox(height: 26),
          _sectionTitle('Informations personnelles'),

          _textField(
            controller: _prenomController,
            label: 'Prénom',
            validator: _requiredValidator,
            prefixIcon: Icons.person_outline,
          ),
          _textField(
            controller: _nomController,
            label: 'Nom',
            validator: _requiredValidator,
            prefixIcon: Icons.badge_outlined,
          ),
          _textField(
            controller: _emailController,
            label: 'Adresse e-mail',
            keyboardType: TextInputType.emailAddress,
            validator: _emailValidator,
            prefixIcon: Icons.email_outlined,
          ),
          _textField(
            controller: _adresseController,
            label: 'Adresse',
            validator: _requiredValidator,
            prefixIcon: Icons.location_on_outlined,
          ),
          _textField(
            controller: _telephoneController,
            label: 'Téléphone',
            keyboardType: TextInputType.phone,
            validator: _requiredValidator,
            prefixIcon: Icons.phone_outlined,
          ),

          DropdownButtonFormField<String>(
            initialValue: _genre,
            dropdownColor: _surfaceColor,
            style: const TextStyle(color: _textColor),
            iconEnabledColor: _goldColor,
            decoration: _decoration(
              'Genre',
            ).copyWith(prefixIcon: const Icon(Icons.wc_outlined)),
            items: const [
              DropdownMenuItem(value: 'FEMININ', child: Text('Féminin')),
              DropdownMenuItem(value: 'MASCULIN', child: Text('Masculin')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _genre = value);
              }
            },
          ),

          if (_isApprenant) ...[
            const SizedBox(height: 28),
            _sectionTitle('Formation souhaitée'),

            if (_isLoadingFormations)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_formations.isEmpty)
              Container(
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
                    const Text(
                      'Aucune formation disponible ou impossible '
                      'de contacter le serveur.',
                      style: TextStyle(color: _mutedColor),
                    ),
                    TextButton.icon(
                      onPressed: _loadFormations,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                      style: TextButton.styleFrom(
                        foregroundColor: _goldLightColor,
                      ),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<String>(
                initialValue: _formationId,
                isExpanded: true,
                dropdownColor: _surfaceColor,
                style: const TextStyle(color: _textColor),
                iconEnabledColor: _goldColor,
                decoration: _decoration(
                  'Choisir une formation',
                ).copyWith(prefixIcon: const Icon(Icons.school_outlined)),
                items: _formations.map((formation) {
                  return DropdownMenuItem<String>(
                    value: formation['id'].toString(),
                    child: Text(
                      formation['titre'].toString(),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                validator: (value) {
                  if (value == null) {
                    return 'Choisis une formation.';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() => _formationId = value);
                },
              ),

            if (_selectedFormation != null) ...[
              const SizedBox(height: 14),
              _buildPriceCard(),
            ],
          ],

          const SizedBox(height: 28),
          _sectionTitle('Sécurité'),

          _textField(
            controller: _passwordController,
            label: 'Mot de passe',
            obscureText: _obscurePassword,
            validator: _passwordValidator,
            prefixIcon: Icons.lock_outline,
            suffixIcon: IconButton(
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: _goldLightColor,
              ),
            ),
          ),

          _textField(
            controller: _confirmPasswordController,
            label: 'Confirmer le mot de passe',
            obscureText: _obscureConfirmPassword,
            validator: _confirmPasswordValidator,
            prefixIcon: Icons.lock_reset_outlined,
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: _goldLightColor,
              ),
            ),
          ),

          if (_errorMessage != null) _buildErrorMessage(),

          const SizedBox(height: 26),

          _primaryButton(
            label: _isApprenant
                ? 'Continuer vers le paiement'
                : 'Vérifier mes informations',
            icon: Icons.arrow_forward_rounded,
            onPressed: _isLoadingFormations && _isApprenant
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
    );
  }

  Widget _buildPaymentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Droit d’inscription',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: _goldLightColor,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Vérifie la formation et choisis ton moyen de paiement.',
          style: TextStyle(color: _mutedColor, height: 1.5),
        ),
        const SizedBox(height: 24),

        _buildPriceCard(),

        const SizedBox(height: 28),
        _sectionTitle('Moyen de paiement'),

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

        if (_modePaiement != 'ESPECES') ...[
          const SizedBox(height: 18),
          _textField(
            controller: _referenceController,
            label: 'Référence de transaction',
            validator: _requiredValidator,
            prefixIcon: Icons.receipt_long_outlined,
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderColor),
            ),
            child: const Text(
              'La référence et les informations de paiement seront '
              'enregistrées avec votre demande. L’administration '
              'vérifiera le paiement avant de valider votre inscription.',
              style: TextStyle(fontSize: 12, color: _mutedColor, height: 1.5),
            ),
          ),
        ],

        const SizedBox(height: 28),
        _primaryButton(
          label: 'Continuer',
          icon: Icons.arrow_forward_rounded,
          onPressed: _validatePaymentStep,
        ),
      ],
    );
  }

  Widget _buildConfirmationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Vérifier ma demande',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: _goldLightColor,
          ),
        ),
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
                '${_prenomController.text.trim()} '
                '${_nomController.text.trim()}',
            'E-mail': _emailController.text.trim(),
            'Téléphone': _telephoneController.text.trim(),
            'Rôle': _isApprenant ? 'Apprenant' : 'Formateur',
          },
        ),

        if (_isApprenant) ...[
          const SizedBox(height: 16),
          _summaryCard(
            title: 'Formation et paiement',
            rows: {
              'Formation':
                  _selectedFormation?['titre']?.toString() ?? 'Non choisie',
              'Droit d’inscription': _formatAr(_registrationFee),
              'Moyen de paiement': _paymentLabel(_modePaiement),
              if (_modePaiement != 'ESPECES')
                'Référence': _referenceController.text.trim(),
            },
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _goldColor.withValues(alpha: 0.45)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: _goldLightColor, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Le paiement sera enregistré comme étant en attente. '
                    'L’administration confirmera la réception des espèces '
                    'avant de valider votre inscription.',
                    style: TextStyle(
                      fontSize: 12,
                      color: _mutedColor,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
          onPressed: _isSubmitting ? null : _submitRegistration,
        ),
      ],
    );
  }

  Widget _buildSuccessScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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

          const SizedBox(height: 14),

          const Text(
            'Ta demande d’inscription a été transmise. '
            'Elle reste soumise à la vérification de '
            'l’administration.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _mutedColor, height: 1.6),
          ),

          if (_isApprenant) ...[
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
              icon: const Icon(Icons.arrow_back),
              label: const Text('Retour'),
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
            _formatAr(_registrationFee),
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
        groupValue: _modePaiement,
        onChanged: (newValue) {
          if (newValue == null) return;
          setState(() => _modePaiement = newValue);
        },
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
          Row(
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
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _goldLightColor,
                  ),
                ),
              ),
            ],
          ),

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
                      entry.value,
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
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    IconData? prefixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: const TextStyle(color: _textColor, fontSize: 14),
        cursorColor: _goldColor,
        decoration: _decoration(label).copyWith(
          prefixIcon: prefixIcon == null
              ? null
              : Icon(prefixIcon, color: _mutedColor, size: 21),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  InputDecoration _decoration(String label) {
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
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _goldColor, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
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
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _goldLightColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
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
    );
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: _backgroundColor),
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: _backgroundColor,
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
}
