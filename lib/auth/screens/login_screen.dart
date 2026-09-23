import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // CONNEXION
  // ============================================================

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final auth = context.read<AuthProvider>();

    final success = await auth.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      _showMessage(
        auth.errorMessage ?? 'Échec de la connexion.',
        isError: true,
      );
    }
  }

  // ============================================================
  // INSCRIPTION
  // ============================================================

  Future<void> _openRegister() async {
    if (context.read<AuthProvider>().isLoading) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RegisterScreen(),
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    required bool isError,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor:
              isError ? AppColors.danger : AppColors.ok,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
  }

  // ============================================================
  // VALIDATION EMAIL
  // ============================================================

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Veuillez saisir votre adresse e-mail.';
    }

    final emailRegex = RegExp(
      r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$',
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Veuillez saisir une adresse e-mail valide.';
    }

    return null;
  }

  // ============================================================
  // VALIDATION MOT DE PASSE
  // ============================================================

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez saisir votre mot de passe.';
    }

    return null;
  }

  // ============================================================
  // LABEL
  // ============================================================

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.manrope(
        fontSize: 13,
        color: Colors.grey[500],
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      prefixIcon: Icon(
        icon,
        color: Colors.grey[400],
        size: 20,
      ),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.grey[800]!,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFFF5722),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppColors.danger,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppColors.danger,
          width: 1.5,
        ),
      ),
      errorStyle: GoogleFonts.manrope(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.danger,
      ),
    );
  }

  // ============================================================
  // CHAMP EMAIL
  // ============================================================

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Adresse e-mail'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
          validator: _validateEmail,
          decoration: _inputDecoration(
            hintText: 'exemple@email.com',
            icon: Icons.email_outlined,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CHAMP MOT DE PASSE
  // ============================================================

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Mot de passe'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
          validator: _validatePassword,
          onFieldSubmitted: (_) {
            if (!context.read<AuthProvider>().isLoading) {
              _handleLogin();
            }
          },
          decoration: _inputDecoration(
            hintText: 'Votre mot de passe',
            icon: Icons.lock_outline_rounded,
            suffixIcon: IconButton(
              tooltip: _obscurePassword
                  ? 'Afficher le mot de passe'
                  : 'Masquer le mot de passe',
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.grey[400],
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MOT DE PASSE OUBLIÉ
  // ============================================================

  void _forgotPassword() {
    _showMessage(
      'La récupération du mot de passe sera disponible prochainement.',
      isError: false,
    );
  }

  // ============================================================
  // BOUTON CONNEXION
  // ============================================================

  Widget _buildLoginButton(bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 201, 172, 45),
          disabledBackgroundColor:
              const Color.fromARGB(255, 226, 198, 39).withValues(alpha: 0.55),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isLoading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  key: const ValueKey('button'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Se connecter',
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 19,
                      color: Colors.white,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ============================================================
  // SE SOUVENIR DE MOI
  // ============================================================

  Widget _buildRememberMe() {
    return Row(
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: Checkbox(
            value: _rememberMe,
            onChanged: (value) {
              setState(() {
                _rememberMe = value ?? false;
              });
            },
            activeColor: const Color.fromARGB(255, 197, 181, 39),
            checkColor: Colors.white,
            side: BorderSide(
              color: Colors.grey[600]!,
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Se souvenir de moi',
          style: GoogleFonts.manrope(
            fontSize: 12,
            color: Colors.grey[400],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 460,
              ),
              child: Column(
                children: [
                  // ==================================================
                  // LOGO YMS
                  // ==================================================

                  Image.asset(
                    'assets/images/logo_yms.png',
                    height: 100,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Column(
                        children: [
                          Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.grey[600],
                            size: 50,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Logo YMS introuvable',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 22),

                  // ==================================================
                  // FORMULAIRE
                  // ==================================================

                  Container(
                    padding: const EdgeInsets.fromLTRB(
                      22,
                      30,
                      22,
                      30,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.grey[800]!,
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'BIENVENUE À BORD',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: const Color.fromARGB(255, 214, 189, 49),
                              letterSpacing: 1.2,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            'Connexion',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            'Connectez-vous à votre espace YMS.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              color: Colors.grey[400],
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 28),

                          // EMAIL
                          _buildEmailField(),

                          const SizedBox(height: 18),

                          // MOT DE PASSE
                          _buildPasswordField(),

                          const SizedBox(height: 14),

                          // OPTIONS
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            crossAxisAlignment:
                                CrossAxisAlignment.center,
                            children: [
                              _buildRememberMe(),

                              TextButton(
                                onPressed:
                                    isLoading ? null : _forgotPassword,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 4,
                                  ),
                                ),
                                child: Text(
                                  'Mot de passe oublié ?',
                                  style: GoogleFonts.manrope(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey[400],
                                    decoration:
                                        TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // BOUTON CONNEXION
                          _buildLoginButton(isLoading),

                          const SizedBox(height: 28),

                          // INSCRIPTION
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Text(
                                'Pas encore de compte ?',
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  color: Colors.grey[400],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              TextButton(
                                onPressed:
                                    isLoading ? null : _openRegister,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.only(
                                    left: 6,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Créer un compte',
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    decoration:
                                        TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // FOOTER
                  Text(
                    'Youth Malagasy Service',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}