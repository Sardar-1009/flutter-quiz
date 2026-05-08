import 'package:shared_preferences/shared_preferences.dart';

/// Service that persists onboarding completion status and user profile data.
class OnboardingService {
  static const String _keyOnboardingComplete = 'onboarding_complete';
  static const String _keyName = 'user_name';
  static const String _keyAge = 'user_age_range';
  static const String _keyEducation = 'user_education';
  static const String _keyExperience = 'user_experience';

  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingComplete) ?? false;
  }

  Future<void> completeOnboarding({
    required String name,
    required String ageRange,
    required String educationLevel,
    required String programmingExperience,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name);
    await prefs.setString(_keyAge, ageRange);
    await prefs.setString(_keyEducation, educationLevel);
    await prefs.setString(_keyExperience, programmingExperience);
    await prefs.setBool(_keyOnboardingComplete, true);
  }

  Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyName) ?? '';
  }
}
