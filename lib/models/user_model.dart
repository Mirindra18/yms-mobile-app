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
      id: ((json['id'] ?? json['userId']) as num).toInt(),
      email: json['email'] as String,
      nom: (json['lastName'] ?? json['nom'] ?? '') as String,
      prenom: (json['firstName'] ?? json['prenom'] ?? '') as String,
      // Jackson serialize un champ Java `isArchived` sous le nom `archived`.
      // On accepte aussi l'ancien contrat mobile afin de rester compatible.
      isArchived: (json['archived'] ?? json['isArchived']) as bool? ?? false,
      lastLoginDate: json['lastLoginDate']?.toString(),
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
