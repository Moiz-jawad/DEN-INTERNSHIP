import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static SharedPreferences? _prefs;
  static final SharedPreferencesService _instance = SharedPreferencesService._internal();

  factory SharedPreferencesService() => _instance;
  SharedPreferencesService._internal();

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Keys
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserId = 'user_id';
  static const String _keyUserName = 'user_name';
  static const String _keyUserEmail = 'user_email';
  static const String _keyLastLoginTime = 'last_login_time';
  static const String _keyRememberMe = 'remember_me';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyLanguage = 'language';

  // User Session Methods
  bool isUserLoggedIn() => _prefs?.getBool(_keyIsLoggedIn) ?? false;
  
  Future<bool> setUserLoggedIn(bool value) async {
    return await _prefs?.setBool(_keyIsLoggedIn, value) ?? false;
  }

  String? getUserId() => _prefs?.getString(_keyUserId);
  
  Future<bool> setUserId(String userId) async {
    return await _prefs?.setString(_keyUserId, userId) ?? false;
  }

  String? getUserName() => _prefs?.getString(_keyUserName);
  
  Future<bool> setUserName(String name) async {
    return await _prefs?.setString(_keyUserName, name) ?? false;
  }

  String? getUserEmail() => _prefs?.getString(_keyUserEmail);
  
  Future<bool> setUserEmail(String email) async {
    return await _prefs?.setString(_keyUserEmail, email) ?? false;
  }

  DateTime? getLastLoginTime() {
    final timestamp = _prefs?.getInt(_keyLastLoginTime);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }
  
  Future<bool> setLastLoginTime(DateTime dateTime) async {
    return await _prefs?.setInt(_keyLastLoginTime, dateTime.millisecondsSinceEpoch) ?? false;
  }

  bool getRememberMe() => _prefs?.getBool(_keyRememberMe) ?? false;
  
  Future<bool> setRememberMe(bool value) async {
    return await _prefs?.setBool(_keyRememberMe, value) ?? false;
  }

  // App Settings
  String getThemeMode() => _prefs?.getString(_keyThemeMode) ?? 'system';
  
  Future<bool> setThemeMode(String mode) async {
    return await _prefs?.setString(_keyThemeMode, mode) ?? false;
  }

  String getLanguage() => _prefs?.getString(_keyLanguage) ?? 'en';
  
  Future<bool> setLanguage(String language) async {
    return await _prefs?.setString(_keyLanguage, language) ?? false;
  }

  // Clear user session
  Future<bool> clearUserSession() async {
    final results = await Future.wait([
      _prefs?.setBool(_keyIsLoggedIn, false) ?? Future.value(false),
      _prefs?.remove(_keyUserId) ?? Future.value(false),
      _prefs?.remove(_keyUserName) ?? Future.value(false),
      _prefs?.remove(_keyUserEmail) ?? Future.value(false),
      _prefs?.remove(_keyLastLoginTime) ?? Future.value(false),
    ]);
    return results.every((result) => result == true);
  }

  // Clear all preferences
  Future<bool> clearAll() async {
    return await _prefs?.clear() ?? false;
  }

  // Check if this is the first app launch
  bool isFirstLaunch() => _prefs?.getBool('first_launch') ?? true;
  
  Future<bool> setFirstLaunch(bool value) async {
    return await _prefs?.setBool('first_launch', value) ?? false;
  }
}