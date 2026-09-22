import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../admin/admin_shell.dart';
import '../formateur/formateur_shell.dart';
import '../apprenant/apprenant_shell.dart';

class RoleRouter {
  static Widget getHome(UserModel user) {
    if (user.roles.contains('ADMIN')) {
      return const AdminShell();
    }

    if (user.roles.contains('FORMATEUR')) {
      return const FormateurShell();
    }

    if (user.roles.contains('APPRENANT')) {
      return const ApprenantShell();
    }

    return const Scaffold(
      body: Center(
        child: Text(
          'Aucun rôle reconnu',
          style: TextStyle(
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}