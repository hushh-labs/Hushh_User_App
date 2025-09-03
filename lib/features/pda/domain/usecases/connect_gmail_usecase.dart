import '../repositories/gmail_repository.dart';

class ConnectGmailUseCase {
  final GmailRepository repository;

  ConnectGmailUseCase(this.repository);

  Future<bool> call({
    required String userId,
    required String accessToken,
    String? refreshToken,
    String? idToken,
    required String email,
    required List<String> scopes,
  }) async {
    try {
      return await repository.connectGmail(
        userId,
        accessToken: accessToken,
        refreshToken: refreshToken,
        idToken: idToken,
        email: email,
        scopes: scopes,
      );
    } catch (e) {
      throw Exception('Failed to connect Gmail: $e');
    }
  }
}
