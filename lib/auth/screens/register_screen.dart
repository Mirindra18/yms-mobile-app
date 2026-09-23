import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/auth_brand_block.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _registerFormKey =
      GlobalKey<FormState>();

  final _registerPrenomController =
      TextEditingController();

  final _registerNomController =
      TextEditingController();

  final _registerEmailController =
      TextEditingController();

  final _registerPasswordController =
      TextEditingController();

  final _registerConfirmPasswordController =
      TextEditingController();

  bool _obscureRegisterPassword = true;
  bool _obscureConfirmPassword = true;

  String _selectedRole = 'ROLE_APPRENANT';

  @override
  void dispose() {
    _registerPrenomController.dispose();
    _registerNomController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmPasswordController.dispose();

    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_registerFormKey.currentState!.validate()) {
      return;
    }

    final auth = context.read<AuthProvider>();

    final message = await auth.register(
      nom: _registerNomController.text.trim(),
      prenom: _registerPrenomController.text.trim(),
      email: _registerEmailController.text.trim(),
      password: _registerPasswordController.text,
      role: _selectedRole,
    );

    if (!mounted) return;

    if (message == null) {
      _showMessage(
        auth.errorMessage ??
            'Erreur lors de l\'inscription',
        isError: true,
      );

      return;
    }

    _showMessage(
      message,
      isError: false,
    );

    // Après une inscription réussie,
    // retour vers l'écran de connexion.
    Navigator.pop(context);
  }

  void _showMessage(
    String message, {
    required bool isError,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? AppColors.danger : AppColors.ok,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 460,
              ),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  const AuthBrandBlock(),

                  const SizedBox(height: 22),

                  Container(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      24,
                      20,
                      24,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius:
                          BorderRadius.circular(28),
                      border: Border.all(
                        color: AppColors.cardBorder,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brown950
                              .withValues(alpha: 0.10),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _registerFormKey,
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Créer mon compte',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall,
                          ),

                          const SizedBox(height: 4),

                          Text(
                            'Rejoignez la communauté YMS',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall,
                          ),

                          const SizedBox(height: 20),

                          // PRÉNOM ET NOM
                          LayoutBuilder(
                            builder:
                                (context, constraints) {
                              if (constraints.maxWidth <
                                  330) {
                                return Column(
                                  children: [
                                    _buildPrenomField(),
                                    const SizedBox(
                                      height: 12,
                                    ),
                                    _buildNomField(),
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  Expanded(
                                    child:
                                        _buildPrenomField(),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Expanded(
                                    child:
                                        _buildNomField(),
                                  ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 12),

                          // EMAIL
                          TextFormField(
                            controller:
                                _registerEmailController,
                            keyboardType:
                                TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty) {
                                return 'Saisissez un email';
                              }

                              if (!RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              ).hasMatch(value.trim())) {
                                return 'Email invalide';
                              }

                              return null;
                            },
                            decoration:
                                const InputDecoration(
                              hintText: 'Adresse email',
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color:
                                    AppColors.brown700,
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // RÔLE
                          DropdownButtonFormField<String>(
                            initialValue:
                                _selectedRole,
                            decoration:
                                const InputDecoration(
                              hintText:
                                  'Choisissez votre rôle',
                              prefixIcon: Icon(
                                Icons.badge_outlined,
                                color:
                                    AppColors.brown700,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value:
                                    'ROLE_APPRENANT',
                                child:
                                    Text('Apprenant'),
                              ),
                              DropdownMenuItem(
                                value:
                                    'ROLE_FORMATEUR',
                                child:
                                    Text('Formateur'),
                              ),
                            ],
                            onChanged: isLoading
                                ? null
                                : (value) {
                                    if (value ==
                                        null) {
                                      return;
                                    }

                                    setState(() {
                                      _selectedRole =
                                          value;
                                    });
                                  },
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty) {
                                return 'Veuillez choisir votre rôle';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 12),

                          // MOT DE PASSE
                          TextFormField(
                            controller:
                                _registerPasswordController,
                            obscureText:
                                _obscureRegisterPassword,
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty) {
                                return 'Saisissez un mot de passe';
                              }

                              if (!RegExp(
                                r'^(?=.*\d).{12,}$',
                              ).hasMatch(value)) {
                                return 'Au moins 12 caractères et 1 chiffre';
                              }

                              return null;
                            },
                            decoration:
                                InputDecoration(
                              hintText:
                                  'Mot de passe',
                              prefixIcon:
                                  const Icon(
                                Icons.lock_outline,
                                color:
                                    AppColors.brown700,
                              ),
                              suffixIcon:
                                  IconButton(
                                icon: Icon(
                                  _obscureRegisterPassword
                                      ? Icons
                                          .visibility_outlined
                                      : Icons
                                          .visibility_off_outlined,
                                  color:
                                      AppColors.brown700,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureRegisterPassword =
                                        !_obscureRegisterPassword;
                                  });
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // CONFIRMATION
                          TextFormField(
                            controller:
                                _registerConfirmPasswordController,
                            obscureText:
                                _obscureConfirmPassword,
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty) {
                                return 'Confirmez votre mot de passe';
                              }

                              if (value !=
                                  _registerPasswordController
                                      .text) {
                                return 'Les mots de passe ne correspondent pas';
                              }

                              return null;
                            },
                            decoration:
                                InputDecoration(
                              hintText:
                                  'Confirmer le mot de passe',
                              prefixIcon:
                                  const Icon(
                                Icons
                                    .lock_reset_outlined,
                                color:
                                    AppColors.brown700,
                              ),
                              suffixIcon:
                                  IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons
                                          .visibility_outlined
                                      : Icons
                                          .visibility_off_outlined,
                                  color:
                                      AppColors.brown700,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // BOUTON INSCRIPTION
                          ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : _handleRegister,
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child:
                                        CircularProgressIndicator(
                                      color:
                                          AppColors.cream,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Créer mon compte',
                                  ),
                          ),

                          const SizedBox(height: 14),

                          // RETOUR CONNEXION
                          Wrap(
                            alignment:
                                WrapAlignment.center,
                            crossAxisAlignment:
                                WrapCrossAlignment.center,
                            children: [
                              Text(
                                'Vous avez déjà un compte ? ',
                                style:
                                    GoogleFonts.manrope(
                                  fontSize: 12.5,
                                  color:
                                      AppColors.muted,
                                ),
                              ),
                              GestureDetector(
                                onTap: isLoading
                                    ? null
                                    : () {
                                        Navigator.pop(
                                          context,
                                        );
                                      },
                                child: Text(
                                  'Se connecter',
                                  style:
                                      GoogleFonts.manrope(
                                    fontSize: 12.5,
                                    fontWeight:
                                        FontWeight.w800,
                                    color:
                                        AppColors.brown900,
                                    decoration:
                                        TextDecoration
                                            .underline,
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

                  Text(
                    'Votre identification unique et votre email',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrenomField() {
    return TextFormField(
      controller: _registerPrenomController,
      keyboardType: TextInputType.name,
      textCapitalization:
          TextCapitalization.words,
      validator: (value) {
        if (value == null ||
            value.trim().isEmpty) {
          return 'Prénom requis';
        }

        return null;
      },
      decoration: const InputDecoration(
        hintText: 'Prénom',
        prefixIcon: Icon(
          Icons.person_outline,
          color: AppColors.brown700,
        ),
      ),
    );
  }

  Widget _buildNomField() {
    return TextFormField(
      controller: _registerNomController,
      keyboardType: TextInputType.name,
      textCapitalization:
          TextCapitalization.words,
      validator: (value) {
        if (value == null ||
            value.trim().isEmpty) {
          return 'Nom requis';
        }

        return null;
      },
      decoration: const InputDecoration(
        hintText: 'Nom',
        prefixIcon: Icon(
          Icons.badge_outlined,
          color: AppColors.brown700,
        ),
      ),
    );
  }
}