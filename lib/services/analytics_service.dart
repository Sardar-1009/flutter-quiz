import 'package:firebase_analytics/firebase_analytics.dart';

/// Central analytics service.
/// All Firebase Analytics calls go through here — never call FirebaseAnalytics
/// directly from ViewModels or Screens.
class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // ─────────────────────────────────────────────────────────────────
  // USER PROPERTIES
  // Set once during onboarding. Enables audience segmentation in the
  // Firebase console (e.g., "quiz score by experience level").
  // ─────────────────────────────────────────────────────────────────

  Future<void> setUserProperties({
    required String ageGroup,
    required String educationLevel,
    required String programmingExperience,
  }) async {
    await Future.wait([
      _analytics.setUserProperty(name: 'age_group', value: ageGroup),
      _analytics.setUserProperty(
          name: 'education_level', value: educationLevel),
      _analytics.setUserProperty(
          name: 'programming_experience', value: programmingExperience),
    ]);
  }

  // ─────────────────────────────────────────────────────────────────
  // AUTH EVENTS
  // ─────────────────────────────────────────────────────────────────

  /// User successfully signed up.
  Future<void> logSignUp() async {
    await _analytics.logSignUp(signUpMethod: 'email_password');
  }

  /// User successfully logged in.
  Future<void> logLogin() async {
    await _analytics.logLogin(loginMethod: 'email_password');
  }

  /// Auth attempt failed (login or register).
  Future<void> logAuthError({required String errorCode}) async {
    await _analytics.logEvent(
      name: 'auth_error',
      parameters: {'error_code': errorCode},
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // ONBOARDING EVENTS
  // ─────────────────────────────────────────────────────────────────

  /// User started the onboarding flow.
  Future<void> logOnboardingBegin() async {
    await _analytics.logTutorialBegin();
  }

  /// User viewed a specific onboarding step.
  /// [stepIndex] is 0-based; [stepName] is a human-readable label.
  Future<void> logOnboardingStepViewed({
    required int stepIndex,
    required String stepName,
  }) async {
    await _analytics.logEvent(
      name: 'onboarding_step_viewed',
      parameters: {
        'step_index': stepIndex,
        'step_name': stepName,
      },
    );
  }

  /// User completed all onboarding steps.
  Future<void> logOnboardingComplete() async {
    await _analytics.logTutorialComplete();
  }

  // ─────────────────────────────────────────────────────────────────
  // QUIZ EVENTS
  // ─────────────────────────────────────────────────────────────────

  /// User selected a topic on the home screen.
  Future<void> logTopicSelected({required String topic}) async {
    await _analytics.logSelectContent(
      contentType: 'quiz_topic',
      itemId: topic,
    );
  }

  /// User started a quiz.
  Future<void> logQuizStart({required String topic}) async {
    await _analytics.logEvent(
      name: 'quiz_start',
      parameters: {'topic_name': topic},
    );
  }

  /// User abandoned a quiz mid-way (returned to home without finishing).
  Future<void> logQuizAbandoned({
    required String topic,
    required int questionsAnswered,
    required int totalQuestions,
  }) async {
    await _analytics.logEvent(
      name: 'quiz_abandoned',
      parameters: {
        'topic_name': topic,
        'questions_answered': questionsAnswered,
        'total_questions': totalQuestions,
      },
    );
  }

  /// User completed a quiz.
  Future<void> logQuizComplete({
    required String topic,
    required int score,
    required int totalQuestions,
  }) async {
    final percentage = totalQuestions > 0
        ? ((score / totalQuestions) * 100).round()
        : 0;

    await _analytics.logEvent(
      name: 'quiz_complete',
      parameters: {
        'topic_name': topic,
        'score': score,
        'total_questions': totalQuestions,
        'percentage': percentage,
      },
    );
  }

  /// Questions failed to load.
  Future<void> logQuizLoadError({required String topic}) async {
    await _analytics.logEvent(
      name: 'quiz_load_error',
      parameters: {'topic_name': topic},
    );
  }
}
