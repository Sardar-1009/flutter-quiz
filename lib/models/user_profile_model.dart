/// Model to store the user's onboarding profile data.
class UserProfileModel {
  final String name;
  final String ageRange;
  final String educationLevel;
  final String programmingExperience;

  const UserProfileModel({
    required this.name,
    required this.ageRange,
    required this.educationLevel,
    required this.programmingExperience,
  });

  Map<String, String> toMap() => {
        'name': name,
        'ageRange': ageRange,
        'educationLevel': educationLevel,
        'programmingExperience': programmingExperience,
      };

  factory UserProfileModel.fromMap(Map<String, String> map) {
    return UserProfileModel(
      name: map['name'] ?? '',
      ageRange: map['ageRange'] ?? '',
      educationLevel: map['educationLevel'] ?? '',
      programmingExperience: map['programmingExperience'] ?? '',
    );
  }
}
