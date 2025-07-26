enum UserGuideQuestionType {
  name,
  email,
  phone,
  dateOfBirth,
  categories,
  location,
  fileUpload,
  multiChoice,
  multiSelect,
}

extension UserGuideQuestionTypeExtension on UserGuideQuestionType {
  String get displayName {
    switch (this) {
      case UserGuideQuestionType.name:
        return 'Name';
      case UserGuideQuestionType.email:
        return 'Email';
      case UserGuideQuestionType.phone:
        return 'Phone Number';
      case UserGuideQuestionType.dateOfBirth:
        return 'Date of Birth';
      case UserGuideQuestionType.categories:
        return 'Categories';
      case UserGuideQuestionType.location:
        return 'Location';
      case UserGuideQuestionType.fileUpload:
        return 'File Upload';
      case UserGuideQuestionType.multiChoice:
        return 'Multiple Choice';
      case UserGuideQuestionType.multiSelect:
        return 'Multiple Select';
    }
  }
}
