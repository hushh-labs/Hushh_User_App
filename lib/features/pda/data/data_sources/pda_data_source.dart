import 'package:hushh_user_app/features/pda/data/models/pda_message_model.dart';

abstract class PdaDataSource {
  Future<List<PdaMessageModel>> getMessages(String userId);
  Future<void> saveMessage(PdaMessageModel message);
  Future<void> deleteMessage(String messageId);
  Future<void> clearMessages(String userId);
  Future<String> sendToGemini(String message, List<PdaMessageModel> context);
  Future<void> prewarmUserContext(String hushhId);
  Future<Map<String, dynamic>> getUserContext(String hushhId);
}
