import '../models/qna_session_model.dart';
import '../models/answer_model.dart';
import '../models/question_model.dart';

abstract class QnARemoteDataSource {
  Future<QnASessionModel> startQnASession(String agentId, String agentName);
  Future<QnASessionModel> submitAnswer(String sessionId, AnswerModel answer);
  Future<QnASessionModel> completeQnASession(String sessionId);
  Future<QnASessionModel> getQnASession(String sessionId);
}

class QnARemoteDataSourceImpl implements QnARemoteDataSource {
  // Helper method to get the questions list
  List<Map<String, dynamic>> _getQuestions() {
    return [
      {
        'id': '1',
        'text': 'What\'s your shopping style?',
        'type': 'multipleChoice',
        'options': [
          'Curated Collections',
          'Latest Trends',
          'Timeless Classics',
          'Unique Finds',
        ],
        'order': 1,
      },
      {
        'id': '2',
        'text': 'What\'s your preferred price range?',
        'type': 'multipleChoice',
        'options': [
          'Under ₹50,000',
          '₹50,000 - ₹2,00,000',
          '₹2,00,000 - ₹5,00,000',
          'Above ₹5,00,000',
        ],
        'order': 2,
      },
      {
        'id': '3',
        'text': 'How often do you shop for luxury items?',
        'type': 'multipleChoice',
        'options': ['Monthly', 'Quarterly', 'Bi-annually', 'Annually'],
        'order': 3,
      },
      {
        'id': '4',
        'text': 'What\'s your preferred shopping experience?',
        'type': 'multipleChoice',
        'options': [
          'Online only',
          'In-store only',
          'Both equally',
          'Concierge service',
        ],
        'order': 4,
      },
      {
        'id': '5',
        'text': 'Tell us about your style preferences and any specific needs',
        'type': 'textInput',
        'placeholder': 'Share your style story...',
        'order': 5,
      },
    ];
  }

  @override
  Future<QnASessionModel> startQnASession(
    String agentId,
    String agentName,
  ) async {
    // Mock implementation - in real app, this would make API calls
    await Future.delayed(const Duration(milliseconds: 500));

    final questions = _getQuestions();

    return QnASessionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      agentId: agentId,
      agentName: agentName,
      questions: questions.map((q) => QuestionModel.fromJson(q)).toList(),
      answers: [],
      createdAt: DateTime.now(),
      isCompleted: false,
    );
  }

  @override
  Future<QnASessionModel> submitAnswer(
    String sessionId,
    AnswerModel answer,
  ) async {
    // Mock implementation - in real app, this would make API calls
    await Future.delayed(const Duration(milliseconds: 300));

    // Return the same questions as in startQnASession to maintain consistency
    final questions = _getQuestions();

    return QnASessionModel(
      id: sessionId,
      agentId: 'agent_1',
      agentName: 'Sarah Chen',
      questions: questions.map((q) => QuestionModel.fromJson(q)).toList(),
      answers: [answer],
      createdAt: DateTime.now(),
      isCompleted: false,
    );
  }

  @override
  Future<QnASessionModel> completeQnASession(String sessionId) async {
    // Mock implementation - in real app, this would make API calls
    await Future.delayed(const Duration(milliseconds: 500));

    // Return the same questions as in startQnASession to maintain consistency
    final questions = _getQuestions();

    return QnASessionModel(
      id: sessionId,
      agentId: 'agent_1',
      agentName: 'Sarah Chen',
      questions: questions.map((q) => QuestionModel.fromJson(q)).toList(),
      answers: [],
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
      isCompleted: true,
    );
  }

  @override
  Future<QnASessionModel> getQnASession(String sessionId) async {
    // Mock implementation - in real app, this would make API calls
    await Future.delayed(const Duration(milliseconds: 300));

    // Return the same questions as in startQnASession to maintain consistency
    final questions = _getQuestions();

    return QnASessionModel(
      id: sessionId,
      agentId: 'agent_1',
      agentName: 'Sarah Chen',
      questions: questions.map((q) => QuestionModel.fromJson(q)).toList(),
      answers: [],
      createdAt: DateTime.now(),
      isCompleted: false,
    );
  }
}
