import 'package:flutter/foundation.dart';
import '../models/question_model.dart';
import '../models/quiz_result_model.dart';
import '../services/question_service.dart';

enum QuizState { idle, loading, inProgress, finished, error }

class QuizViewModel extends ChangeNotifier {
  final QuestionService _service;

  QuizViewModel({QuestionService? service})
      : _service = service ?? QuestionService();

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
      } else {
        _state = QuizState.inProgress;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _state = QuizState.error;
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
    } else {
      _currentIndex++;
      _selectedOptionIndex = null;
      _answerConfirmed = false;
    }
    notifyListeners();
  }

  void resetToHome() {
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
