
class PortfolioData {
  String name = 'John Doe';
  String title = 'Aspiring Developer';
  String bio = 'I am a passionate learner with a keen interest in Flutter development and UI/UX design. I enjoy building apps that solve real-world problems and exploring new technologies.';
  String email = 'john.doe@example.com';
  String phone = '+1-234-567-8900';
  String linkedin = 'linkedin.com/in/johndoe';
  List<String> skills = ['Flutter', 'Dart', 'UI/UX Design', 'Problem Solving', 'Teamwork'];
  String profileImagePath = 'assets/images/profile.jpg'; // Default image path

  PortfolioData();

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'title': title,
      'bio': bio,
      'email': email,
      'phone': phone,
      'linkedin': linkedin,
      'skills': skills,
      'profileImagePath': profileImagePath,
    };
  }

  factory PortfolioData.fromJson(Map<String, dynamic> json) {
    return PortfolioData()
      ..name = json['name'] as String
      ..title = json['title'] as String
      ..bio = json['bio'] as String
      ..email = json['email'] as String
      ..phone = json['phone'] as String
      ..linkedin = json['linkedin'] as String
      ..skills = List<String>.from(json['skills'] as List)
      ..profileImagePath = json['profileImagePath'] as String;
  }
}