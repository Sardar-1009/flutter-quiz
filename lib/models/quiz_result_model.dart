class QuizResultModel {
  final int totalQuestions;
  final int correctAnswers;

  const QuizResultModel({
    required this.totalQuestions,
    required this.correctAnswers,
  });

  double get percentage =>
      totalQuestions == 0 ? 0 : (correctAnswers / totalQuestions) * 100;

  String get interpretation {
    final p = percentage;
    if (p >= 90) return 'Отлично! 🏆';
    if (p >= 70) return 'Хорошо! 👍';
    if (p >= 50) return 'Неплохо, но есть куда расти 📚';
    return 'Нужно подтянуть знания 💪';
  }

  String get interpretationDetail {
    final p = percentage;
    if (p >= 90) return 'Превосходный результат! Вы отлично знаете Dart и Flutter.';
    if (p >= 70) return 'Хороший уровень знаний. Продолжайте практику!';
    if (p >= 50) return 'Базовые знания есть. Рекомендуем повторить материал.';
    return 'Стоит уделить больше времени изучению Dart и Flutter.';
  }
}
