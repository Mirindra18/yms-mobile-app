import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _adresseController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedFormation;
  String _selectedGenre = 'Homme';
  String _selectedRole = 'ETUDIANT'; // Rôle par défaut
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final List<String> _formations = [
    'Licence en Informatique (Web & Mobile)',
    'Licence en Gestion & Management',
    'Master en Génie Logiciel',
    'Master en Intelligence Artificielle',
  ];

  final Map<String, String> _rolesMap = {
    'ETUDIANT': 'Étudiant',
    'FORMATEUR': 'Formateur',
    'ADMIN': 'Administrateur',
  };

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    _emailController.dispose();
    _adresseController.dispose();
    _telephoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les mots de passe ne correspondent pas'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      await authProvider.register(
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole, // Utilisation du rôle sélectionné
        adresse: _adresseController.text.trim(),
        genre: _selectedGenre,
        telephone: _telephoneController.text.trim(),
        formationSouhaitee: _selectedFormation ?? 'Non spécifiée',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Compte créé avec succès ! En attente d\'activation.'),
          backgroundColor: Color.from(alpha: 1, red: 0.773, green: 0.627, blue: 0.349),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
    String? hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      labelStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      hintStyle: TextStyle(color: Colors.grey[600]),
      prefixIcon: Icon(icon, color: const Color(0xFFC5A059)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFF1E222B),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[800]!, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFC5A059), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B08),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0B08),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFC5A059)),
        title: const Text(
          'Inscription YMS',
          style: TextStyle(color: Color(0xFFC5A059), fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Prénom & Nom
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _prenomController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration(
                          label: 'Prénom',
                          icon: Icons.person_outline,
                          hintText: 'Nomena',
                        ),
                        validator: (v) => v!.isEmpty ? 'Champ requis' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _nomController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration(
                          label: 'Nom',
                          icon: Icons.person,
                          hintText: 'Ravel',
                        ),
                        validator: (v) => v!.isEmpty ? 'Champ requis' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: _buildInputDecoration(
                    label: 'Adresse e-mail',
                    icon: Icons.email_outlined,
                    hintText: 'vous@example.mg',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Veuillez entrer un email';
                    if (!v.contains('@')) return 'Email invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Rôle (Sélection)
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  dropdownColor: const Color(0xFF1E222B),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _buildInputDecoration(
                    label: 'Rôle',
                    icon: Icons.badge_outlined,
                  ),
                  items: _rolesMap.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value, style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedRole = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Adresse
                TextFormField(
                  controller: _adresseController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _buildInputDecoration(
                    label: 'Adresse',
                    icon: Icons.location_on_outlined,
                    hintText: 'Votre adresse',
                  ),
                  validator: (v) => v!.isEmpty ? 'Champ requis' : null,
                ),
                const SizedBox(height: 16),

                // Téléphone
                TextFormField(
                  controller: _telephoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: _buildInputDecoration(
                    label: 'Téléphone',
                    icon: Icons.phone_outlined,
                    hintText: '034 00 000 00',
                  ),
                  validator: (v) => v!.isEmpty ? 'Champ requis' : null,
                ),
                const SizedBox(height: 16),

                // Formation souhaitée
                DropdownButtonFormField<String>(
                  initialValue: _selectedFormation,
                  dropdownColor: const Color(0xFF1E222B),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _buildInputDecoration(
                    label: 'Formation souhaitée',
                    icon: Icons.school_outlined,
                  ),
                  hint: const Text('Choisir une formation', style: TextStyle(color: Colors.grey)),
                  items: _formations.map((String formation) {
                    return DropdownMenuItem<String>(
                      value: formation,
                      child: Text(formation, style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedFormation = newValue;
                    });
                  },
                  validator: (v) => v == null ? 'Veuillez choisir une formation' : null,
                ),
                const SizedBox(height: 16),

                // Genre
                DropdownButtonFormField<String>(
                  initialValue: _selectedGenre,
                  dropdownColor: const Color(0xFF1E222B),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _buildInputDecoration(
                    label: 'Genre',
                    icon: Icons.wc_outlined,
                  ),
                  items: ['Homme', 'Femme', 'Autre'].map((String genre) {
                    return DropdownMenuItem<String>(
                      value: genre,
                      child: Text(genre, style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedGenre = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Mot de passe
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: _buildInputDecoration(
                    label: 'Mot de passe',
                    icon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.length < 6) return 'Minimum 6 caractères requis';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirmer le mot de passe
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: _buildInputDecoration(
                    label: 'Confirmer le mot de passe',
                    icon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                  validator: (v) => v!.isEmpty ? 'Veuillez confirmer votre mot de passe' : null,
                ),
                const SizedBox(height: 20),

                // Encadré d'information
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFC5A059).withValues(alpha: 0.5), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_outlined, color: Color(0xFFC5A059), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Votre compte sera activé après vérification de votre demande par l\'administration YMS.',
                          style: TextStyle(color: Colors.grey[300], fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Bouton Envoyer ma demande
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC5A059),
                      foregroundColor: const Color(0xFF0D0B08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Color(0xFF0D0B08),
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Envoyer ma demande',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 20),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}