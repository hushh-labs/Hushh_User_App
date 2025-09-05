import 'package:equatable/equatable.dart';

class LinkedInPosition extends Equatable {
  final int? id;
  final String userId;
  final String positionId;
  final String? companyId;
  final String? companyName;
  final String? companyUrn;
  final String? companyUrl;
  final String? companyLogoUrl;
  final String? companyIndustry;
  final String? companySize;
  final String? companyType;
  final String? title;
  final String? description;
  final String? summary;
  final String? locationName;
  final bool isCurrent;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? startDateYear;
  final int? startDateMonth;
  final int? endDateYear;
  final int? endDateMonth;
  final String? positionGroup;
  final String? regionCode;
  final bool isDefault;
  final DateTime? syncedAt;

  const LinkedInPosition({
    this.id,
    required this.userId,
    required this.positionId,
    this.companyId,
    this.companyName,
    this.companyUrn,
    this.companyUrl,
    this.companyLogoUrl,
    this.companyIndustry,
    this.companySize,
    this.companyType,
    this.title,
    this.description,
    this.summary,
    this.locationName,
    this.isCurrent = false,
    this.startDate,
    this.endDate,
    this.startDateYear,
    this.startDateMonth,
    this.endDateYear,
    this.endDateMonth,
    this.positionGroup,
    this.regionCode,
    this.isDefault = false,
    this.syncedAt,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    positionId,
    companyId,
    companyName,
    companyUrn,
    companyUrl,
    companyLogoUrl,
    companyIndustry,
    companySize,
    companyType,
    title,
    description,
    summary,
    locationName,
    isCurrent,
    startDate,
    endDate,
    startDateYear,
    startDateMonth,
    endDateYear,
    endDateMonth,
    positionGroup,
    regionCode,
    isDefault,
    syncedAt,
  ];

  LinkedInPosition copyWith({
    int? id,
    String? userId,
    String? positionId,
    String? companyId,
    String? companyName,
    String? companyUrn,
    String? companyUrl,
    String? companyLogoUrl,
    String? companyIndustry,
    String? companySize,
    String? companyType,
    String? title,
    String? description,
    String? summary,
    String? locationName,
    bool? isCurrent,
    DateTime? startDate,
    DateTime? endDate,
    int? startDateYear,
    int? startDateMonth,
    int? endDateYear,
    int? endDateMonth,
    String? positionGroup,
    String? regionCode,
    bool? isDefault,
    DateTime? syncedAt,
  }) {
    return LinkedInPosition(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      positionId: positionId ?? this.positionId,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      companyUrn: companyUrn ?? this.companyUrn,
      companyUrl: companyUrl ?? this.companyUrl,
      companyLogoUrl: companyLogoUrl ?? this.companyLogoUrl,
      companyIndustry: companyIndustry ?? this.companyIndustry,
      companySize: companySize ?? this.companySize,
      companyType: companyType ?? this.companyType,
      title: title ?? this.title,
      description: description ?? this.description,
      summary: summary ?? this.summary,
      locationName: locationName ?? this.locationName,
      isCurrent: isCurrent ?? this.isCurrent,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      startDateYear: startDateYear ?? this.startDateYear,
      startDateMonth: startDateMonth ?? this.startDateMonth,
      endDateYear: endDateYear ?? this.endDateYear,
      endDateMonth: endDateMonth ?? this.endDateMonth,
      positionGroup: positionGroup ?? this.positionGroup,
      regionCode: regionCode ?? this.regionCode,
      isDefault: isDefault ?? this.isDefault,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  /// Get formatted company and position display
  String get positionDisplay {
    if (title != null && companyName != null) {
      return '$title at $companyName';
    } else if (title != null) {
      return title!;
    } else if (companyName != null) {
      return companyName!;
    }
    return 'Position';
  }

  /// Get duration of position
  String get duration {
    if (startDate == null) return '';

    final start = startDate!;
    final end = isCurrent ? DateTime.now() : endDate ?? DateTime.now();

    final years = end.year - start.year;
    final months = end.month - start.month + (years * 12);

    if (months < 1) {
      return 'Less than a month';
    } else if (months < 12) {
      return '$months month${months > 1 ? 's' : ''}';
    } else {
      final totalYears = months ~/ 12;
      final remainingMonths = months % 12;

      String result = '$totalYears year${totalYears > 1 ? 's' : ''}';
      if (remainingMonths > 0) {
        result += ' $remainingMonths month${remainingMonths > 1 ? 's' : ''}';
      }
      return result;
    }
  }

  /// Get formatted date range
  String get dateRange {
    final startStr = startDate != null
        ? '${_monthName(startDate!.month)} ${startDate!.year}'
        : '';

    final endStr = isCurrent
        ? 'Present'
        : endDate != null
        ? '${_monthName(endDate!.month)} ${endDate!.year}'
        : '';

    if (startStr.isEmpty && endStr.isEmpty) return '';
    if (startStr.isEmpty) return endStr;
    if (endStr.isEmpty) return startStr;

    return '$startStr - $endStr';
  }

  String _monthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month];
  }

  /// Check if this is a current position
  bool get isCurrentPosition => isCurrent;

  /// Get company size display
  String get companySizeDisplay {
    if (companySize == null) return '';

    // Convert LinkedIn company size codes to readable format
    switch (companySize?.toUpperCase()) {
      case 'A':
        return '1 employee';
      case 'B':
        return '2-10 employees';
      case 'C':
        return '11-50 employees';
      case 'D':
        return '51-200 employees';
      case 'E':
        return '201-500 employees';
      case 'F':
        return '501-1000 employees';
      case 'G':
        return '1001-5000 employees';
      case 'H':
        return '5001-10000 employees';
      case 'I':
        return '10001+ employees';
      default:
        return companySize ?? '';
    }
  }
}
