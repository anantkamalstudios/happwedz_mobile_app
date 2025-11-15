
import 'package:shared_preferences/shared_preferences.dart';

class UserPrefs {
  static Future<SharedPreferences> _prefs() async {
    return await SharedPreferences.getInstance();
  }

  /// Save values
  static Future<void> saveUser({
    required int id,
    required String name,
    required String email,
    required String token,
    String? phone,
    String? photo,
  }) async {
    final prefs = await _prefs();
    await prefs.setBool('is_logged_in', true);
    await prefs.setInt('user_id', id);
    await prefs.setString('user_name', name);
    await prefs.setString('user_email', email);
    await prefs.setString('auth_token', token);
    await prefs.setString('user_phone', phone ?? "");
    await prefs.setString('user_photo', photo ?? "");
  }

  /// Check login status
  static Future<bool> isLoggedIn() async {
    final prefs = await _prefs();
    return prefs.getBool('is_logged_in') ?? false;
  }

  /// Get user values
  static Future<int?> getUserId() async {
    final prefs = await _prefs();
    return prefs.getInt('user_id');
  }

  static Future<String?> getUserName() async {
    final prefs = await _prefs();
    return prefs.getString('user_name');
  }

  static Future<String?> getUserEmail() async {
    final prefs = await _prefs();
    return prefs.getString('user_email');
  }

  static Future<String?> getUserPhoto() async {
    final prefs = await _prefs();
    return prefs.getString('user_photo');
  }

  static Future<String?> getToken() async {
    final prefs = await _prefs();
    return prefs.getString('auth_token');
  }

  /// Logout
  static Future<void> clear() async {
    final prefs = await _prefs();
    await prefs.clear();
  }
}
