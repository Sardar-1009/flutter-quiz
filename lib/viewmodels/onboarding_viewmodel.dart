import 'package:flutter/foundation.dart';
import '../services/onboarding_service.dart';

/// ViewModel that manages the onboarding flow state.
class OnboardingViewModel extends ChangeNotifier {
  final OnboardingService _service;

  OnboardingViewModel({OnboardingService? service})
      : _service = service ?? OnboardingService();

  // Current page index (0-based)
  int _currentPage = 0;
  int get currentPage => _currentPage;

  // Total number of onboarding pages
  static const int totalPages = 5;

  // Page 1 — Welcome (name input)
  String _name = '';
  String get name => _name;
  void setName(String value) {
    _name = value;
    notifyListeners();
  }

  // Page 2 — Age range
  String _ageRange = '';
  String get ageRange => _ageRange;
  void setAgeRange(String value) {
    _ageRange = value;
    notifyListeners();
  }

  // Page 3 — Education level
  String _educationLevel = '';
  String get educationLevel => _educationLevel;
  void setEducationLevel(String value) {
    _educationLevel = value;
    notifyListeners();
  }

  // Page 4 — Programming experience
  String _programmingExperience = '';
  String get programmingExperience => _programmingExperience;
  void setProgrammingExperience(String value) {
    _programmingExperience = value;
    notifyListeners();
  }

  // Page 5 — Ready to go (no input needed)

  // Navigation
  bool get canProceed {
    switch (_currentPage) {
      case 0:
        return _name.trim().isNotEmpty;
      case 1:
        return _ageRange.isNotEmpty;
      case 2:
        return _educationLevel.isNotEmpty;
      case 3:
        return _programmingExperience.isNotEmpty;
      case 4:
        return true; // final page — always can proceed
      default:
        return false;
    }
  }

  bool get isLastPage => _currentPage >= totalPages - 1;

  void nextPage() {
    if (_currentPage < totalPages - 1) {
      _currentPage++;
      notifyListeners();
    }
  }

  void previousPage() {
    if (_currentPage > 0) {
      _currentPage--;
      notifyListeners();
    }
  }

  void goToPage(int page) {
    if (page >= 0 && page < totalPages) {
      _currentPage = page;
      notifyListeners();
    }
  }

  // Complete onboarding
  Future<void> completeOnboarding() async {
    await _service.completeOnboarding(
      name: _name.trim(),
      ageRange: _ageRange,
      educationLevel: _educationLevel,
      programmingExperience: _programmingExperience,
    );
  }
}
