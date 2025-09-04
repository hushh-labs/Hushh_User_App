import 'package:equatable/equatable.dart';

class LinkedInCertification extends Equatable {
  final int? id;
  final String userId;
  final String certificationId;
  final String? name;
  final String? authority;
  final String? number;
  final String? url;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? startDateYear;
  final int? startDateMonth;
  final int? endDateYear;
  final int? endDateMonth;
  final DateTime? syncedAt;

  const LinkedInCertification({
    this.id,
    required this.userId,
    required this.certificationId,
    this.name,
    this.authority,
    this.number,
    this.url,
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
    certificationId,
    name,
    authority,
    number,
    url,
    description,
    startDate,
    endDate,
    startDateYear,
    startDateMonth,
    endDateYear,
    endDateMonth,
    syncedAt,
  ];

  LinkedInCertification copyWith({
    int? id,
    String? userId,
    String? certificationId,
    String? name,
    String? authority,
    String? number,
    String? url,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    int? startDateYear,
    int? startDateMonth,
    int? endDateYear,
    int? endDateMonth,
    DateTime? syncedAt,
  }) {
    return LinkedInCertification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      certificationId: certificationId ?? this.certificationId,
      name: name ?? this.name,
      authority: authority ?? this.authority,
      number: number ?? this.number,
      url: url ?? this.url,
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

  /// Get formatted certification display
  String get certificationDisplay {
    if (name != null && authority != null) {
      return '$name from $authority';
    } else if (name != null) {
      return name!;
    } else if (authority != null) {
      return 'Certification from $authority';
    }
    return 'Certification';
  }

  /// Check if certification is currently valid
  bool get isCurrentlyValid {
    if (endDate == null && endDateYear == null) return true; // No expiry

    final now = DateTime.now();
    if (endDate != null) {
      return endDate!.isAfter(now);
    } else if (endDateYear != null) {
      return endDateYear! >= now.year;
    }

    return true;
  }

  /// Get status of certification
  String get status {
    if (isCurrentlyValid) {
      return 'Valid';
    } else {
      return 'Expired';
    }
  }

  /// Get formatted date range
  String get dateRange {
    final startStr = startDate != null
        ? '${startDate!.month}/${startDate!.year}'
        : startDateYear?.toString() ?? '';

    final endStr = endDate != null
        ? '${endDate!.month}/${endDate!.year}'
        : endDateYear?.toString() ?? '';

    if (startStr.isEmpty && endStr.isEmpty) return '';
    if (startStr.isEmpty) return endStr;
    if (endStr.isEmpty) return 'Since $startStr';

    return '$startStr - $endStr';
  }

  /// Check if certification has verification URL
  bool get hasVerificationUrl => url != null && url!.isNotEmpty;

  /// Get certification authority display
  String get authorityDisplay => authority ?? 'Unknown Authority';

  /// Get certification number display
  String get numberDisplay {
    return number != null && number!.isNotEmpty ? 'Certificate #$number' : '';
  }
}

