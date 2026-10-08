class User {
  final String id;
  final String name;
  final String email;
  final String role; // 'student', 'teacher', 'admin'
  final int? gradeLevel;
  final double? abilityTheta;
  final int xp;
  final int level;
  final int streak;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.gradeLevel,
    this.abilityTheta,
    this.xp = 0,
    this.level = 1,
    this.streak = 0,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      gradeLevel: json['gradeLevel'],
      abilityTheta: json['abilityTheta']?.toDouble(),
      xp: json['xp'] ?? 0,
      level: json['level'] ?? 1,
      streak: json['streak'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'gradeLevel': gradeLevel,
      'abilityTheta': abilityTheta,
      'xp': xp,
      'level': level,
      'streak': streak,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    int? gradeLevel,
    double? abilityTheta,
    int? xp,
    int? level,
    int? streak,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      abilityTheta: abilityTheta ?? this.abilityTheta,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      streak: streak ?? this.streak,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
