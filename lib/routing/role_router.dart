import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../admin/admin_shell.dart';
import '../formateur/formateur_shell.dart';
import '../apprenant/apprenant_shell.dart';

class RoleRouter {
  static Widget getHome(UserModel user) {
    debugPrint('===== ROLE DEBUG =====');
    debugPrint('Nom : ${user.nom}');
    debugPrint('Prénom : ${user.prenom}');
    debugPrint('Roles reçus : ${user.roles}');
    debugPrint('=====================');

    if (user.roles.contains('ROLE_ADMIN')) {
      return const AdminShell();
    }

    if (user.roles.contains('ROLE_FORMATEUR')) {
      return const FormateurShell();
    }

    if (user.roles.contains('ROLE_APPRENANT')) {
      return const ApprenantShell();
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Aucun rôle reconnu\n\n'
            'Rôles reçus : ${user.roles}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }
}