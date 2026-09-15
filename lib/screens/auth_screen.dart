import 'package:flutter/material.dart';
import '../services/inscription_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // Clés de formulaires pour la validation
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  // État de l'écran
  bool isLogin = true;
  bool _isLoading = false;

  // Masquage des mots de passe
  bool _obscureLoginPassword = true;
  bool _obscureRegisterPassword = true;
  bool _obscureConfirmPassword = true;

  // Couleurs du thème
  static const Color darkBrown = Color(0xFF3D261D);
  static const Color cardBg = Color(0xFFDCDCDC);
  static const Color goldAccent = Color(0xFFB89855);

  // Contrôleurs Connexion
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  // Contrôleurs Inscription (Le contrôleur Rôle a été retiré)
  final _registerNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerConfirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmPasswordController.dispose();
    super.dispose();
  }

  // --- ACTIONS METIER ---

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await InscriptionService.login(
      _loginEmailController.text.trim(),
      _loginPasswordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _showSnackBar('Connexion réussie !', isError: false);
      // Exemple de redirection : Navigator.pushReplacementNamed(context, '/home');
    } else {
      _showSnackBar(result['message'] ?? 'Échec de la connexion', isError: true);
    }
  }

  Future<void> _handleRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Le rôle par défaut 'USER' est transmis ici directement au service
    final result = await InscriptionService.register(
      name: _registerNameController.text.trim(),
      email: _registerEmailController.text.trim(),
      role: 'USER', // Rôle attribué par défaut
      password: _registerPasswordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _showSnackBar('Compte créé avec succès ! Connectez-vous.', isError: false);
      setState(() => isLogin = true);
    } else {
      _showSnackBar(result['message'] ?? 'Erreur lors de l\'inscription', isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // --- BUILD UI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBrown,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLogin) ...[
                  // Logo circulaire
                  Container(
                    width: 110,
                    height: 110,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.workspace_premium,
                            color: goldAccent,
                            size: 50,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Carte Principale
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 28.0),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(28.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isLogin ? _buildLoginForm() : _buildRegisterForm(),
                  ),
                ),

                if (isLogin) ...[
                  const SizedBox(height: 30),
                  const Text(
                    'Votre identification unique et votre email',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- FORMULAIRE DE CONNEXION ---

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        key: const ValueKey('LoginForm'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Email (identifiant unique)',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _loginEmailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Veuillez saisir votre email';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                return 'Format d\'email invalide';
              }
              return null;
            },
            decoration: _inputDecoration(
              suffixIcon: const Icon(Icons.email_outlined, color: goldAccent, size: 20),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Mot de passe',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _loginPasswordController,
            obscureText: _obscureLoginPassword,
            autofillHints: const [AutofillHints.password],
            validator: (value) =>
                (value == null || value.isEmpty) ? 'Veuillez saisir votre mot de passe' : null,
            decoration: _inputDecoration(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureLoginPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: goldAccent,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscureLoginPassword = !_obscureLoginPassword),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                // Action mot de passe oublié
              },
              child: const Text(
                'Mot de passe oublié?',
                style: TextStyle(
                  color: Colors.black87,
                  decoration: TextDecoration.underline,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _isLoading ? null : _handleLogin,
            style: _buttonStyle(darkBrown),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Se Connecter', style: TextStyle(color: Colors.white, fontSize: 15)),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _isLoading ? null : () => setState(() => isLogin = false),
            style: _buttonStyle(darkBrown),
            child: const Text('S\'inscrire', style: TextStyle(color: Colors.white, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  // --- FORMULAIRE D'INSCRIPTION ---

  Widget _buildRegisterForm() {
    return Form(
      key: _registerFormKey,
      child: Column(
        key: const ValueKey('RegisterForm'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Inscription',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: darkBrown,
            ),
          ),
          const SizedBox(height: 20),
          
          // Champ Nom & Prénom
          TextFormField(
            controller: _registerNameController,
            keyboardType: TextInputType.name,
            validator: (val) => (val == null || val.trim().isEmpty) ? 'Saisissez votre nom' : null,
            decoration: _inputDecoration(
              hintText: 'Nom et Prénom',
              prefixIcon: const Icon(Icons.person_outline, color: goldAccent),
            ),
          ),
          const SizedBox(height: 12),

          // Champ Email
          TextFormField(
            controller: _registerEmailController,
            keyboardType: TextInputType.emailAddress,
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Saisissez un email';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val.trim())) {
                return 'Email invalide';
              }
              return null;
            },
            decoration: _inputDecoration(
              hintText: 'Email',
              prefixIcon: const Icon(Icons.email_outlined, color: goldAccent),
            ),
          ),
          const SizedBox(height: 12),

          // Champ Mot de passe
          TextFormField(
            controller: _registerPasswordController,
            obscureText: _obscureRegisterPassword,
            validator: (val) {
              if (val == null || val.isEmpty) return 'Saisissez un mot de passe';
              if (val.length < 6) return '6 caractères minimum';
              return null;
            },
            decoration: _inputDecoration(
              hintText: 'Mot de passe',
              prefixIcon: const Icon(Icons.lock_outline, color: goldAccent),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureRegisterPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: goldAccent,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscureRegisterPassword = !_obscureRegisterPassword),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Champ Confirmation mot de passe
          TextFormField(
            controller: _registerConfirmPasswordController,
            obscureText: _obscureConfirmPassword,
            validator: (val) {
              if (val != _registerPasswordController.text) {
                return 'Les mots de passe ne correspondent pas';
              }
              return null;
            },
            decoration: _inputDecoration(
              hintText: 'Confirmer le mot de passe',
              prefixIcon: const Icon(Icons.lock_reset_outlined, color: goldAccent),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: goldAccent,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Bouton d'inscription
          ElevatedButton(
            onPressed: _isLoading ? null : _handleRegister,
            style: _buttonStyle(darkBrown),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Créer mon compte', style: TextStyle(color: Colors.white, fontSize: 15)),
          ),
          const SizedBox(height: 16),

          // Séparateur social
          Row(
            children: const [
              Expanded(child: Divider(color: Colors.black45)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'ou s\'inscrire avec',
                  style: TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w500),
                ),
              ),
              Expanded(child: Divider(color: Colors.black45)),
            ],
          ),
          const SizedBox(height: 16),

          // Boutons d'authentification sociale
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _socialButton(
                child: Image.network(
                  'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg',
                  width: 24,
                  height: 24,
                  errorBuilder: (c, e, s) => const Icon(Icons.g_mobiledata, size: 30, color: Colors.red),
                ),
              ),
              const SizedBox(width: 16),
              _socialButton(
                child: const Icon(Icons.apple, size: 28, color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Basculer vers la connexion
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Vous avez déjà un compte ? ',
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
              GestureDetector(
                onTap: () => setState(() => isLogin = true),
                child: const Text(
                  'se connecter',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- STYLES RÉUTILISABLES ---

  InputDecoration _inputDecoration({String? hintText, Widget? prefixIcon, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: goldAccent, fontSize: 13, fontWeight: FontWeight.w500),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      filled: true,
      fillColor: const Color(0xFFD1CFC9),
      errorStyle: const TextStyle(height: 0.8, fontSize: 11),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFF9E9E9E), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: darkBrown, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  ButtonStyle _buttonStyle(Color bg) {
    return ElevatedButton.styleFrom(
      backgroundColor: bg,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 2,
    );
  }

  Widget _socialButton({required Widget child}) {
    return InkWell(
      onTap: () {
        // Authentification Sociale
      },
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Center(child: child),
      ),
    );
  }
}