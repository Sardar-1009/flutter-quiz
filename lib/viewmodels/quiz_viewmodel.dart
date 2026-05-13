import 'package:flutter/foundation.dart';
import '../models/question_model.dart';
import '../models/quiz_result_model.dart';
import '../services/analytics_service.dart';
import '../services/question_service.dart';

enum QuizState { idle, loading, inProgress, finished, error }

class QuizViewModel extends ChangeNotifier {
  final QuestionService _service;
  final AnalyticsService _analytics;

  QuizViewModel({QuestionService? service, AnalyticsService? analytics})
      : _service = service ?? QuestionService(),
        _analytics = analytics ?? AnalyticsService();

  // State
  QuizState _state = QuizState.idle;
  List<QuestionModel> _questions = [];
  int _currentIndex = 0;
  int? _selectedOptionIndex;
  bool _answerConfirmed = false;
  final List<int?> _userAnswers = [];
  String _selectedTopic = 'all';
  String _errorMessage = '';

  // Getters
  QuizState get state => _state;
  String get errorMessage => _errorMessage;
  String get selectedTopic => _selectedTopic;

  int get currentIndex => _currentIndex;
  int get totalQuestions => _questions.length;
  int? get selectedOptionIndex => _selectedOptionIndex;
  bool get answerConfirmed => _answerConfirmed;

  QuestionModel? get currentQuestion =>
      _questions.isNotEmpty ? _questions[_currentIndex] : null;

  bool get isLastQuestion => _currentIndex >= _questions.length - 1;

  bool isOptionSelected(int index) => _selectedOptionIndex == index;

  bool isOptionCorrect(int index) =>
      _answerConfirmed && index == currentQuestion?.correctIndex;

  bool isOptionWrong(int index) =>
      _answerConfirmed &&
      index == _selectedOptionIndex &&
      index != currentQuestion?.correctIndex;

  // Business logic (not in View!)
  int get _correctAnswersCount {
    int count = 0;
    for (int i = 0; i < _userAnswers.length; i++) {
      if (_userAnswers[i] == _questions[i].correctIndex) count++;
    }
    return count;
  }

  QuizResultModel? get result {
    if (_state != QuizState.finished) return null;
    return QuizResultModel(
      totalQuestions: _questions.length,
      correctAnswers: _correctAnswersCount,
    );
  }

  // Actions
  Future<void> startQuiz({String topic = 'all'}) async {
    // ← ANALYTICS: topic selection (before quiz starts)
    await _analytics.logTopicSelected(topic: topic);

    _state = QuizState.loading;
    _selectedTopic = topic;
    _currentIndex = 0;
    _selectedOptionIndex = null;
    _answerConfirmed = false;
    _userAnswers.clear();
    _questions = [];
    notifyListeners();

    try {
      _questions = await _service.loadQuestions(
        topic: topic == 'all' ? null : topic,
      );
      if (_questions.isEmpty) {
        _errorMessage = 'Вопросы не найдены';
        _state = QuizState.error;
        await _analytics.logQuizLoadError(topic: topic); // ← ANALYTICS
      } else {
        _state = QuizState.inProgress;
        await _analytics.logQuizStart(topic: topic); // ← ANALYTICS
      }
    } catch (e) {
      _errorMessage = e.toString();
      _state = QuizState.error;
      await _analytics.logQuizLoadError(topic: topic); // ← ANALYTICS
    }

    notifyListeners();
  }

  void selectOption(int index) {
    if (_answerConfirmed) return;
    _selectedOptionIndex = index;
    notifyListeners();
  }

  void confirmAnswer() {
    if (_selectedOptionIndex == null || _answerConfirmed) return;
    _answerConfirmed = true;
    _userAnswers.add(_selectedOptionIndex);
    notifyListeners();
  }

  void nextQuestion() {
    if (!_answerConfirmed) return;

    if (isLastQuestion) {
      _state = QuizState.finished;
      // ← ANALYTICS: quiz completed
      _analytics.logQuizComplete(
        topic: _selectedTopic,
        score: _correctAnswersCount,
        totalQuestions: _questions.length,
      );
    } else {
      _currentIndex++;
      _selectedOptionIndex = null;
      _answerConfirmed = false;
    }
    notifyListeners();
  }

  /// Called when user leaves quiz mid-way (presses back / resets to home).
  /// Logs abandon only if a quiz was actually in progress.
  Future<void> _logAbandonIfNeeded() async {
    if (_state == QuizState.inProgress && _questions.isNotEmpty) {
      await _analytics.logQuizAbandoned(
        topic: _selectedTopic,
        questionsAnswered: _userAnswers.length,
        totalQuestions: _questions.length,
      );
    }
  }

  Future<void> resetToHome() async {
    await _logAbandonIfNeeded(); // ← ANALYTICS
    _state = QuizState.idle;
    _questions = [];
    _currentIndex = 0;
    _selectedOptionIndex = null;
    _answerConfirmed = false;
    _userAnswers.clear();
    _selectedTopic = 'all';
    notifyListeners();
  }
}
