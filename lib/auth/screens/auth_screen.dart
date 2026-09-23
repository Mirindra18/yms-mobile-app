import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:provider/provider.dart';



import '../../providers/auth_provider.dart';

import '../../core/theme/app_theme.dart';



class AuthScreen extends StatefulWidget {

  const AuthScreen({super.key});



  @override

  State<AuthScreen> createState() => _AuthScreenState();

}



class _AuthScreenState extends State<AuthScreen> {

  final _loginFormKey = GlobalKey<FormState>();

  final _registerFormKey = GlobalKey<FormState>();



  bool isLogin = true;



  bool _obscureLoginPassword = true;

  bool _obscureRegisterPassword = true;

  bool _obscureConfirmPassword = true;



  // ============================================================

  // CONNEXION

  // ============================================================



  final _loginEmailController = TextEditingController();

  final _loginPasswordController = TextEditingController();



  // ============================================================

  // INSCRIPTION

  // ============================================================



  final _registerPrenomController = TextEditingController();

  final _registerNomController = TextEditingController();

  final _registerEmailController = TextEditingController();

  final _registerPasswordController = TextEditingController();

  final _registerConfirmPasswordController = TextEditingController();



  // Rôle sélectionné

 String _selectedRole = 'ROLE_APPRENANT';



  @override

  void dispose() {

    _loginEmailController.dispose();

    _loginPasswordController.dispose();



    _registerPrenomController.dispose();

    _registerNomController.dispose();

    _registerEmailController.dispose();

    _registerPasswordController.dispose();

    _registerConfirmPasswordController.dispose();



    super.dispose();

  }



  // ============================================================

  // CONNEXION

  // ============================================================



  Future<void> _handleLogin() async {

    if (!_loginFormKey.currentState!.validate()) return;



    final auth = context.read<AuthProvider>();



    final success = await auth.login(

      _loginEmailController.text.trim(),

      _loginPasswordController.text,

    );



    if (!mounted) return;



    if (!success) {

      _showMessage(

        auth.errorMessage ?? 'Échec de la connexion',

        isError: true,

      );

    }

  }



  // ============================================================

  // INSCRIPTION

  // ============================================================



  Future<void> _handleRegister() async {

    if (!_registerFormKey.currentState!.validate()) return;



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

        auth.errorMessage ?? 'Erreur lors de l\'inscription',

        isError: true,

      );

      return;

    }



    _showMessage(

      message,

      isError: false,

    );



    setState(() {

      isLogin = true;

    });

  }



  // ============================================================

  // MESSAGE

  // ============================================================



  void _showMessage(

    String message, {

    required bool isError,

  }) {

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(

        content: Text(message),

        backgroundColor: isError

            ? AppColors.danger

            : AppColors.ok,

        behavior: SnackBarBehavior.floating,

        shape: RoundedRectangleBorder(

          borderRadius: BorderRadius.circular(20),

        ),

      ),

    );

  }



  // ============================================================

  // BUILD

  // ============================================================



  @override

  Widget build(BuildContext context) {

    final isLoading = context.watch<AuthProvider>().isLoading;



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

                mainAxisAlignment: MainAxisAlignment.center,

                children: [

                  const _BrandBlock(),



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

                      borderRadius: BorderRadius.circular(28),

                      border: Border.all(

                        color: AppColors.cardBorder,

                      ),

                      boxShadow: [

                        BoxShadow(

                          color: AppColors.brown950.withValues(

                            alpha: 0.10,

                          ),

                          blurRadius: 20,

                          offset: const Offset(0, 8),

                        ),

                      ],

                    ),

                    child: AnimatedSwitcher(

                      duration: const Duration(

                        milliseconds: 250,

                      ),

                      child: isLogin

                          ? _buildLoginForm(isLoading)

                          : _buildRegisterForm(isLoading),

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



  // ============================================================

  // FORMULAIRE CONNEXION

  // ============================================================



  Widget _buildLoginForm(bool isLoading) {

    return Form(

      key: _loginFormKey,

      child: Column(

        key: const ValueKey('LoginForm'),

        crossAxisAlignment: CrossAxisAlignment.stretch,

        children: [

          Text(

            'Bon retour parmi nous',

            textAlign: TextAlign.center,

            style: Theme.of(context).textTheme.headlineSmall,

          ),



          const SizedBox(height: 4),



          Text(

            'Connectez-vous à votre espace',

            textAlign: TextAlign.center,

            style: Theme.of(context).textTheme.bodySmall,

          ),



          const SizedBox(height: 20),



          // ======================================================

          // EMAIL

          // ======================================================



          TextFormField(

            controller: _loginEmailController,

            keyboardType: TextInputType.emailAddress,

            autofillHints: const [

              AutofillHints.email,

            ],

            validator: (value) {

              if (value == null || value.trim().isEmpty) {

                return 'Veuillez saisir votre email';

              }



              if (!RegExp(

                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',

              ).hasMatch(value.trim())) {

                return 'Format d\'email invalide';

              }



              return null;

            },

            decoration: const InputDecoration(

              hintText: 'Adresse email',

              prefixIcon: Icon(

                Icons.email_outlined,

                color: AppColors.brown700,

              ),

            ),

          ),



          const SizedBox(height: 12),



          // ======================================================

          // MOT DE PASSE

          // ======================================================



          TextFormField(

            controller: _loginPasswordController,

            obscureText: _obscureLoginPassword,

            autofillHints: const [

              AutofillHints.password,

            ],

            validator: (value) {

              if (value == null || value.isEmpty) {

                return 'Veuillez saisir votre mot de passe';

              }



              return null;

            },

            decoration: InputDecoration(

              hintText: 'Mot de passe',

              prefixIcon: const Icon(

                Icons.lock_outline,

                color: AppColors.brown700,

              ),

              suffixIcon: IconButton(

                icon: Icon(

                  _obscureLoginPassword

                      ? Icons.visibility_outlined

                      : Icons.visibility_off_outlined,

                  color: AppColors.brown700,

                  size: 20,

                ),

                onPressed: () {

                  setState(() {

                    _obscureLoginPassword =

                        !_obscureLoginPassword;

                  });

                },

              ),

            ),

          ),



          // ======================================================

          // MOT DE PASSE OUBLIÉ

          // ======================================================



          Align(

            alignment: Alignment.centerRight,

            child: TextButton(

              onPressed: () {},

              style: TextButton.styleFrom(

                foregroundColor: AppColors.muted,

              ),

              child: const Text(

                'Mot de passe oublié ?',

                style: TextStyle(

                  fontSize: 12,

                  decoration: TextDecoration.underline,

                ),

              ),

            ),

          ),



          const SizedBox(height: 8),



          // ======================================================

          // BOUTON CONNEXION

          // ======================================================



          ElevatedButton(

            onPressed: isLoading ? null : _handleLogin,

            child: isLoading

                ? const SizedBox(

                    height: 20,

                    width: 20,

                    child: CircularProgressIndicator(

                      color: AppColors.cream,

                      strokeWidth: 2,

                    ),

                  )

                : const Text('Se connecter'),

          ),



          const SizedBox(height: 14),



          // ======================================================

          // PASSER À L'INSCRIPTION

          // ======================================================



          Wrap(

            alignment: WrapAlignment.center,

            crossAxisAlignment: WrapCrossAlignment.center,

            children: [

              Text(

                'Pas encore de compte ? ',

                style: GoogleFonts.manrope(

                  fontSize: 12.5,

                  color: AppColors.muted,

                ),

              ),

              GestureDetector(

                onTap: () {

                  setState(() {

                    isLogin = false;

                  });

                },

                child: Text(

                  'Créer mon compte',

                  style: GoogleFonts.manrope(

                    fontSize: 12.5,

                    fontWeight: FontWeight.w800,

                    color: AppColors.brown900,

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



  // ============================================================

  // FORMULAIRE INSCRIPTION

  // ============================================================



  Widget _buildRegisterForm(bool isLoading) {

    return Form(

      key: _registerFormKey,

      child: Column(

        key: const ValueKey('RegisterForm'),

        crossAxisAlignment: CrossAxisAlignment.stretch,

        children: [

          Text(

            'Créer mon compte',

            textAlign: TextAlign.center,

            style: Theme.of(context).textTheme.headlineSmall,

          ),



          const SizedBox(height: 4),



          Text(

            'Rejoignez la communauté YMS',

            textAlign: TextAlign.center,

            style: Theme.of(context).textTheme.bodySmall,

          ),



          const SizedBox(height: 20),



          // ======================================================

          // PRÉNOM ET NOM

          // ======================================================



          LayoutBuilder(

            builder: (context, constraints) {

              // Sur un écran très petit, les champs passent

              // automatiquement l'un sous l'autre.

              if (constraints.maxWidth < 330) {

                return Column(

                  children: [

                    TextFormField(

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

                    ),



                    const SizedBox(height: 12),



                    TextFormField(

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

                    ),

                  ],

                );

              }



              return Row(

                children: [

                  Expanded(

                    child: TextFormField(

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

                    ),

                  ),



                  const SizedBox(width: 10),



                  Expanded(

                    child: TextFormField(

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

                    ),

                  ),

                ],

              );

            },

          ),



          const SizedBox(height: 12),



          // ======================================================

          // EMAIL

          // ======================================================



          TextFormField(

            controller: _registerEmailController,

            keyboardType: TextInputType.emailAddress,

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

            decoration: const InputDecoration(

              hintText: 'Adresse email',

              prefixIcon: Icon(

                Icons.email_outlined,

                color: AppColors.brown700,

              ),

            ),

          ),



          const SizedBox(height: 12),



          // ======================================================

          // RÔLE

          // ======================================================



          DropdownButtonFormField<String>(

            value: _selectedRole,

            decoration: const InputDecoration(

              hintText: 'Choisissez votre rôle',

              prefixIcon: Icon(

                Icons.badge_outlined,

                color: AppColors.brown700,

              ),

            ),

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

            onChanged: isLoading

                ? null

                : (value) {

                    if (value == null) return;



                    setState(() {

                      _selectedRole = value;

                    });

                  },

            validator: (value) {

              if (value == null || value.isEmpty) {

                return 'Veuillez choisir votre rôle';

              }



              return null;

            },

          ),



          const SizedBox(height: 12),



          // ======================================================

          // MOT DE PASSE

          // ======================================================



          TextFormField(

            controller: _registerPasswordController,

            obscureText: _obscureRegisterPassword,

            validator: (value) {

              if (value == null || value.isEmpty) {

                return 'Saisissez un mot de passe';

              }



              if (!RegExp(

                r'^(?=.*\d).{12,}$',

              ).hasMatch(value)) {

                return 'Au moins 12 caractères et 1 chiffre';

              }



              return null;

            },

            decoration: InputDecoration(

              hintText: 'Mot de passe',

              prefixIcon: const Icon(

                Icons.lock_outline,

                color: AppColors.brown700,

              ),

              suffixIcon: IconButton(

                icon: Icon(

                  _obscureRegisterPassword

                      ? Icons.visibility_outlined

                      : Icons.visibility_off_outlined,

                  color: AppColors.brown700,

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



          // ======================================================

          // CONFIRMATION

          // ======================================================



          TextFormField(

            controller: _registerConfirmPasswordController,

            obscureText: _obscureConfirmPassword,

            validator: (value) {

              if (value == null || value.isEmpty) {

                return 'Confirmez votre mot de passe';

              }



              if (value !=

                  _registerPasswordController.text) {

                return 'Les mots de passe ne correspondent pas';

              }



              return null;

            },

            decoration: InputDecoration(

              hintText: 'Confirmer le mot de passe',

              prefixIcon: const Icon(

                Icons.lock_reset_outlined,

                color: AppColors.brown700,

              ),

              suffixIcon: IconButton(

                icon: Icon(

                  _obscureConfirmPassword

                      ? Icons.visibility_outlined

                      : Icons.visibility_off_outlined,

                  color: AppColors.brown700,

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



          // ======================================================

          // BOUTON INSCRIPTION

          // ======================================================



          ElevatedButton(

            onPressed: isLoading ? null : _handleRegister,

            child: isLoading

                ? const SizedBox(

                    height: 20,

                    width: 20,

                    child: CircularProgressIndicator(

                      color: AppColors.cream,

                      strokeWidth: 2,

                    ),

                  )

                : const Text('Créer mon compte'),

          ),



          const SizedBox(height: 14),



          // ======================================================

          // RETOUR CONNEXION

          // ======================================================



          Wrap(

            alignment: WrapAlignment.center,

            crossAxisAlignment: WrapCrossAlignment.center,

            children: [

              Text(

                'Vous avez déjà un compte ? ',

                style: GoogleFonts.manrope(

                  fontSize: 12.5,

                  color: AppColors.muted,

                ),

              ),

              GestureDetector(

                onTap: () {

                  setState(() {

                    isLogin = true;

                  });

                },

                child: Text(

                  'Se connecter',

                  style: GoogleFonts.manrope(

                    fontSize: 12.5,

                    fontWeight: FontWeight.w800,

                    color: AppColors.brown900,

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

}



// ================================================================

// BLOC YMS

// ================================================================



class _BrandBlock extends StatelessWidget {

  const _BrandBlock();



  @override

  Widget build(BuildContext context) {

    return Container(

      padding: const EdgeInsets.symmetric(

        horizontal: 32,

        vertical: 26,

      ),

      decoration: BoxDecoration(

        gradient: const LinearGradient(

          begin: Alignment.topLeft,

          end: Alignment.bottomRight,

          colors: [

            AppColors.brown800,

            AppColors.brown950,

          ],

        ),

        borderRadius: BorderRadius.circular(28),

        border: Border.all(

          color: AppColors.gold.withValues(alpha: 0.6),

        ),

      ),

      child: Column(

        children: [

          Container(

            width: 78,

            height: 78,

            decoration: const BoxDecoration(

              shape: BoxShape.circle,

              color: AppColors.gold,

            ),

            child: const Icon(

              Icons.workspace_premium,

              color: AppColors.brown950,

              size: 38,

            ),

          ),



          const SizedBox(height: 12),



          Text(

            'YMS',

            style: GoogleFonts.cormorantGaramond(

              fontSize: 34,

              fontWeight: FontWeight.w700,

              color: AppColors.cream,

              letterSpacing: 1.5,

              height: 1,

            ),

          ),



          const SizedBox(height: 4),



          Text(

            'Formation & Excellence',

            style: GoogleFonts.manrope(

              fontSize: 11,

              fontWeight: FontWeight.w600,

              letterSpacing: 2,

              color: AppColors.gold,

            ),

          ),

        ],

      ),

    );

  }

} 

