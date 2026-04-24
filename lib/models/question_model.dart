class QuestionModel {
  final int id;
  final String text;
  final List<String> options;
  final int correctIndex;
  final String topic;

  const QuestionModel({
    required this.id,
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.topic,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] as int,
      text: json['text'] as String,
      options: List<String>.from(json['options'] as List),
      correctIndex: json['correctIndex'] as int,
      topic: json['topic'] as String,
    );
  }

  String get topicLabel {
    switch (topic) {
      case 'dart':
        return 'Dart основы';
      case 'widgets':
        return 'Widgets';
      case 'structure':
        return 'Структура проекта';
      case 'architecture':
        return 'Архитектура';
      default:
        return topic;
    }
  }
}
