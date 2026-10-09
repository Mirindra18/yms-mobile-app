import 'package:flutter/foundation.dart';

import '../models/user_model.dart';

class FormateurProvider extends ChangeNotifier {
  UserModel? _profile;

  UserModel? get profile => _profile;
  String get email => _profile?.email ?? '';
  String get nomComplet => [
    _profile?.prenom ?? '',
    _profile?.nom ?? '',
  ].where((part) => part.isNotEmpty).join(' ');

  void setProfile(UserModel user) {
    if (identical(_profile, user)) return;
    _profile = user;
    notifyListeners();
  }
}
