import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/question_model.dart';

class QuestionService {
  static const String _questionsPath = 'assets/data/questions.json';

  Future<List<QuestionModel>> loadQuestions({String? topic}) async {
    try {
      final String jsonString = await rootBundle.loadString(_questionsPath);
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      final allQuestions = jsonList
          .map((e) => QuestionModel.fromJson(e as Map<String, dynamic>))
          .toList();

      if (topic != null && topic != 'all') {
        return allQuestions.where((q) => q.topic == topic).toList();
      }

      // Return a shuffled selection of 10 questions (balanced across topics)
      return _getBalancedQuestions(allQuestions);
    } catch (e) {
      throw Exception('Ошибка загрузки вопросов: $e');
    }
  }

  List<QuestionModel> _getBalancedQuestions(List<QuestionModel> all) {
    final byTopic = <String, List<QuestionModel>>{};
    for (final q in all) {
      byTopic.putIfAbsent(q.topic, () => []).add(q);
    }

    final selected = <QuestionModel>[];
    final limits = {
      'dart': 4,
      'widgets': 3,
      'structure': 2,
      'architecture': 3,
    };

    for (final entry in limits.entries) {
      final pool = byTopic[entry.key] ?? [];
      pool.shuffle();
      selected.addAll(pool.take(entry.value));
    }

    selected.shuffle();
    return selected.take(10).toList();
  }

  Future<List<String>> getAvailableTopics() async {
    final jsonString = await rootBundle.loadString(_questionsPath);
    final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
    final questions = jsonList
        .map((e) => QuestionModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final topics = questions.map((q) => q.topic).toSet().toList();
    return ['all', ...topics];
  }
}
