class UserModel {
  final int id;
  final String email;
  final String nom;
  final String prenom;
  final bool isArchived;
  final String? lastLoginDate;
  final List<String> roles;

  UserModel({
    required this.id,
    required this.email,
    required this.nom,
    required this.prenom,
    required this.isArchived,
    required this.roles,
    this.lastLoginDate,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      email: json['email'] as String,
      nom: json['nom'] as String,
      prenom: json['prenom'] as String,
      isArchived: json['isArchived'] as bool? ?? false,
      lastLoginDate: json['lastLoginDate'] as String?,
      roles: (json['roles'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  UserModel copyWith({
    String? nom,
    String? prenom,
    String? email,
  }) {
    return UserModel(
      id: id,
      email: email ?? this.email,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      isArchived: isArchived,
      lastLoginDate: lastLoginDate,
      roles: roles,
    );
  }
}
