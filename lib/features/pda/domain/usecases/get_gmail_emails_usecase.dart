import '../entities/gmail_email.dart';
import '../repositories/gmail_repository.dart';

class GetGmailEmailsUseCase {
  final GmailRepository repository;

  GetGmailEmailsUseCase(this.repository);

  Future<List<GmailEmail>> call(
    String userId, {
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
    int? offset,
  }) async {
    try {
      return await repository.getEmails(
        userId,
        fromDate: fromDate,
        toDate: toDate,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      throw Exception('Failed to get Gmail emails: $e');
    }
  }

  Stream<List<GmailEmail>> getEmailsStream(String userId) {
    return repository.getEmailsStream(userId);
  }
}
