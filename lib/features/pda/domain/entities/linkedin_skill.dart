import 'package:equatable/equatable.dart';

class LinkedInSkill extends Equatable {
  final int? id;
  final String userId;
  final String skillId;
  final String? skillName;
  final String? skillUrn;
  final String? standardizedSkillUrn;
  final int numEndorsements;
  final List<dynamic>? topEndorsers;
  final bool isDisplayed;
  final int? displayOrder;
  final DateTime? syncedAt;

  const LinkedInSkill({
    this.id,
    required this.userId,
    required this.skillId,
    this.skillName,
    this.skillUrn,
    this.standardizedSkillUrn,
    this.numEndorsements = 0,
    this.topEndorsers,
    this.isDisplayed = true,
    this.displayOrder,
    this.syncedAt,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    skillId,
    skillName,
    skillUrn,
    standardizedSkillUrn,
    numEndorsements,
    topEndorsers,
    isDisplayed,
    displayOrder,
    syncedAt,
  ];

  LinkedInSkill copyWith({
    int? id,
    String? userId,
    String? skillId,
    String? skillName,
    String? skillUrn,
    String? standardizedSkillUrn,
    int? numEndorsements,
    List<dynamic>? topEndorsers,
    bool? isDisplayed,
    int? displayOrder,
    DateTime? syncedAt,
  }) {
    return LinkedInSkill(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      skillId: skillId ?? this.skillId,
      skillName: skillName ?? this.skillName,
      skillUrn: skillUrn ?? this.skillUrn,
      standardizedSkillUrn: standardizedSkillUrn ?? this.standardizedSkillUrn,
      numEndorsements: numEndorsements ?? this.numEndorsements,
      topEndorsers: topEndorsers ?? this.topEndorsers,
      isDisplayed: isDisplayed ?? this.isDisplayed,
      displayOrder: displayOrder ?? this.displayOrder,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  /// Get display name for the skill
  String get displayName {
    return skillName ?? 'Skill';
  }

  /// Get endorsement count display
  String get endorsementDisplay {
    if (numEndorsements == 0) {
      return 'No endorsements';
    } else if (numEndorsements == 1) {
      return '1 endorsement';
    } else {
      return '$numEndorsements endorsements';
    }
  }

  /// Check if skill is highly endorsed (>= 10 endorsements)
  bool get isHighlyEndorsed => numEndorsements >= 10;

  /// Check if skill is popular (>= 5 endorsements)
  bool get isPopular => numEndorsements >= 5;

  /// Get endorsement level description
  String get endorsementLevel {
    if (numEndorsements == 0) {
      return 'No endorsements';
    } else if (numEndorsements < 3) {
      return 'Few endorsements';
    } else if (numEndorsements < 10) {
      return 'Some endorsements';
    } else if (numEndorsements < 50) {
      return 'Many endorsements';
    } else {
      return 'Highly endorsed';
    }
  }

  /// Get skill category based on name (simple categorization)
  String get category {
    if (skillName == null) return 'Other';

    final name = skillName!.toLowerCase();

    // Programming and Technical Skills
    if (name.contains('programming') ||
        name.contains('software') ||
        name.contains('development') ||
        name.contains('coding') ||
        name.contains('javascript') ||
        name.contains('python') ||
        name.contains('java') ||
        name.contains('react') ||
        name.contains('flutter') ||
        name.contains('dart') ||
        name.contains('html') ||
        name.contains('css') ||
        name.contains('sql') ||
        name.contains('database')) {
      return 'Technical';
    }

    // Management and Leadership
    if (name.contains('management') ||
        name.contains('leadership') ||
        name.contains('team') ||
        name.contains('project') ||
        name.contains('strategy')) {
      return 'Management';
    }

    // Marketing and Sales
    if (name.contains('marketing') ||
        name.contains('sales') ||
        name.contains('advertising') ||
        name.contains('social media') ||
        name.contains('seo') ||
        name.contains('content')) {
      return 'Marketing';
    }

    // Design and Creative
    if (name.contains('design') ||
        name.contains('creative') ||
        name.contains('photoshop') ||
        name.contains('illustrator') ||
        name.contains('ui') ||
        name.contains('ux')) {
      return 'Design';
    }

    // Languages
    if (name.contains('language') ||
        name.contains('english') ||
        name.contains('spanish') ||
        name.contains('french') ||
        name.contains('german') ||
        name.contains('chinese') ||
        name.contains('japanese')) {
      return 'Languages';
    }

    // Finance and Analytics
    if (name.contains('finance') ||
        name.contains('accounting') ||
        name.contains('analytics') ||
        name.contains('excel') ||
        name.contains('financial') ||
        name.contains('budget')) {
      return 'Finance';
    }

    return 'Other';
  }

  /// Get top endorsers count
  int get topEndorsersCount {
    return topEndorsers?.length ?? 0;
  }

  /// Check if skill has top endorsers
  bool get hasTopEndorsers => topEndorsersCount > 0;
}

