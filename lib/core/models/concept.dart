class Concept {
  final String id;
  final String name;
  final String description;
  final List<String> prerequisites; // IDs of prerequisite concepts
  final String subject;
  final int difficulty; // 1-5
  final bool isLocked;
  final bool isMastered;
  final double? masteryPercentage;

  Concept({
    required this.id,
    required this.name,
    required this.description,
    required this.prerequisites,
    required this.subject,
    required this.difficulty,
    this.isLocked = false,
    this.isMastered = false,
    this.masteryPercentage,
  });

  factory Concept.fromJson(Map<String, dynamic> json) {
    return Concept(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      prerequisites: List<String>.from(json['prerequisites'] ?? []),
      subject: json['subject'],
      difficulty: json['difficulty'],
      isLocked: json['isLocked'] ?? false,
      isMastered: json['isMastered'] ?? false,
      masteryPercentage: json['masteryPercentage']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'prerequisites': prerequisites,
      'subject': subject,
      'difficulty': difficulty,
      'isLocked': isLocked,
      'isMastered': isMastered,
      'masteryPercentage': masteryPercentage,
    };
  }

  Concept copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? prerequisites,
    String? subject,
    int? difficulty,
    bool? isLocked,
    bool? isMastered,
    double? masteryPercentage,
  }) {
    return Concept(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      prerequisites: prerequisites ?? this.prerequisites,
      subject: subject ?? this.subject,
      difficulty: difficulty ?? this.difficulty,
      isLocked: isLocked ?? this.isLocked,
      isMastered: isMastered ?? this.isMastered,
      masteryPercentage: masteryPercentage ?? this.masteryPercentage,
    );
  }
}
