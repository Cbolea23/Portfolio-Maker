class Settings {
  bool isDarkMode = false;
  double fontSize = 16.0; // Default font size
  String themeName = 'theme1'; // Default theme

  Settings();

  Map<String, dynamic> toJson() {
    return {
      'isDarkMode': isDarkMode,
      'fontSize': fontSize,
      'themeName': themeName,
    };
  }

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings()
      ..isDarkMode = json['isDarkMode'] as bool
      ..fontSize = (json['fontSize'] as num).toDouble()
      ..themeName = json['themeName'] as String;
  }
}