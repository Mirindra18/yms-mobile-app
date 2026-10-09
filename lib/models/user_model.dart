class UserModel {
  final int id;
  final String email;
  final String nom;
  final String prenom;
  final String? adresse;
  final String? telephone;
  final String? specialite;
  final bool isArchived;
  final String? lastLoginDate;
  final List<String> roles;
  final String? roleDemandeEnAttente;

  UserModel({
    required this.id,
    required this.email,
    required this.nom,
    required this.prenom,
    this.adresse,
    this.telephone,
    this.specialite,
    required this.isArchived,
    required this.roles,
    this.lastLoginDate,
    this.roleDemandeEnAttente,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: ((json['id'] ?? json['userId']) as num).toInt(),
      email: json['email'] as String,
      nom: (json['lastName'] ?? json['nom'] ?? '') as String,
      prenom: (json['firstName'] ?? json['prenom'] ?? '') as String,
      adresse: json['adresse'] as String?,
      telephone: json['telephone'] as String?,
      specialite: json['specialite'] as String?,
      isArchived: (json['archived'] ?? json['isArchived']) as bool? ?? false,
      lastLoginDate: json['lastLoginDate']?.toString(),
      roles: (json['roles'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      roleDemandeEnAttente: json['roleDemandeEnAttente'] as String?,
    );
  }

  UserModel copyWith({String? nom, String? prenom, String? email}) {
    return UserModel(
      id: id,
      email: email ?? this.email,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      adresse: adresse,
      telephone: telephone,
      specialite: specialite,
      isArchived: isArchived,
      lastLoginDate: lastLoginDate,
      roles: roles,
      roleDemandeEnAttente: roleDemandeEnAttente,
    );
  }
}
