import 'package:equatable/equatable.dart';

class LinkedInEducation extends Equatable {
  final int? id;
  final String userId;
  final String educationId;
  final String? schoolId;
  final String? schoolName;
  final String? schoolUrn;
  final String? schoolUrl;
  final String? schoolLogoUrl;
  final String? fieldOfStudy;
  final String? degree;
  final String? degreeUrn;
  final String? grade;
  final String? activities;
  final String? notes;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? startDateYear;
  final int? startDateMonth;
  final int? endDateYear;
  final int? endDateMonth;
  final DateTime? syncedAt;

  const LinkedInEducation({
    this.id,
    required this.userId,
    required this.educationId,
    this.schoolId,
    this.schoolName,
    this.schoolUrn,
    this.schoolUrl,
    this.schoolLogoUrl,
    this.fieldOfStudy,
    this.degree,
    this.degreeUrn,
    this.grade,
    this.activities,
    this.notes,
    this.description,
    this.startDate,
    this.endDate,
    this.startDateYear,
    this.startDateMonth,
    this.endDateYear,
    this.endDateMonth,
    this.syncedAt,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    educationId,
    schoolId,
    schoolName,
    schoolUrn,
    schoolUrl,
    schoolLogoUrl,
    fieldOfStudy,
    degree,
    degreeUrn,
    grade,
    activities,
    notes,
    description,
    startDate,
    endDate,
    startDateYear,
    startDateMonth,
    endDateYear,
    endDateMonth,
    syncedAt,
  ];

  LinkedInEducation copyWith({
    int? id,
    String? userId,
    String? educationId,
    String? schoolId,
    String? schoolName,
    String? schoolUrn,
    String? schoolUrl,
    String? schoolLogoUrl,
    String? fieldOfStudy,
    String? degree,
    String? degreeUrn,
    String? grade,
    String? activities,
    String? notes,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    int? startDateYear,
    int? startDateMonth,
    int? endDateYear,
    int? endDateMonth,
    DateTime? syncedAt,
  }) {
    return LinkedInEducation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      educationId: educationId ?? this.educationId,
      schoolId: schoolId ?? this.schoolId,
      schoolName: schoolName ?? this.schoolName,
      schoolUrn: schoolUrn ?? this.schoolUrn,
      schoolUrl: schoolUrl ?? this.schoolUrl,
      schoolLogoUrl: schoolLogoUrl ?? this.schoolLogoUrl,
      fieldOfStudy: fieldOfStudy ?? this.fieldOfStudy,
      degree: degree ?? this.degree,
      degreeUrn: degreeUrn ?? this.degreeUrn,
      grade: grade ?? this.grade,
      activities: activities ?? this.activities,
      notes: notes ?? this.notes,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      startDateYear: startDateYear ?? this.startDateYear,
      startDateMonth: startDateMonth ?? this.startDateMonth,
      endDateYear: endDateYear ?? this.endDateYear,
      endDateMonth: endDateMonth ?? this.endDateMonth,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  /// Get formatted education display
  String get educationDisplay {
    final parts = <String>[];

    if (degree != null && degree!.isNotEmpty) {
      parts.add(degree!);
    }

    if (fieldOfStudy != null && fieldOfStudy!.isNotEmpty) {
      if (parts.isNotEmpty) {
        parts.add('in ${fieldOfStudy!}');
      } else {
        parts.add(fieldOfStudy!);
      }
    }

    if (schoolName != null && schoolName!.isNotEmpty) {
      if (parts.isNotEmpty) {
        parts.add('from ${schoolName!}');
      } else {
        parts.add(schoolName!);
      }
    }

    return parts.isNotEmpty ? parts.join(' ') : 'Education';
  }

  /// Get formatted date range
  String get dateRange {
    final startStr = startDate != null
        ? startDate!.year.toString()
        : startDateYear?.toString() ?? '';

    final endStr = endDate != null
        ? endDate!.year.toString()
        : endDateYear?.toString() ?? '';

    if (startStr.isEmpty && endStr.isEmpty) return '';
    if (startStr.isEmpty) return endStr;
    if (endStr.isEmpty) return startStr;
    if (startStr == endStr) return startStr;

    return '$startStr - $endStr';
  }

  /// Get school and degree combined
  String get schoolAndDegree {
    if (schoolName != null && degree != null) {
      return '$degree, $schoolName';
    } else if (schoolName != null) {
      return schoolName!;
    } else if (degree != null) {
      return degree!;
    }
    return 'Education';
  }

  /// Check if education is currently ongoing
  bool get isOngoing {
    return endDate == null && endDateYear == null;
  }

  /// Get duration in years
  int? get durationInYears {
    final start = startDateYear ?? startDate?.year;
    final end = endDateYear ?? endDate?.year ?? DateTime.now().year;

    if (start == null) return null;
    return end - start;
  }

  /// Get grade display with proper formatting
  String get gradeDisplay {
    if (grade == null || grade!.isEmpty) return '';

    // Add common grade formatting
    final gradeStr = grade!.trim();
    if (gradeStr.contains('GPA') || gradeStr.contains('gpa')) {
      return gradeStr;
    } else if (double.tryParse(gradeStr) != null) {
      return 'GPA: $gradeStr';
    }

    return gradeStr;
  }

  /// Check if this education entry has complete information
  bool get hasCompleteInfo {
    return schoolName != null &&
        (degree != null || fieldOfStudy != null) &&
        (startDate != null || startDateYear != null);
  }
}

