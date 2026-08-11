import '../models/user_profile.dart';
import '../services/auth_service.dart';

class LoginController {
  LoginController({AuthService? authService})
      : _service = authService ?? AuthService();

  final AuthService _service;

  /// Melempar [ApiException] bila login gagal, sehingga UI dapat
  /// menampilkan pesan yang spesifik untuk tiap jenis kegagalan.
  Future<UserProfile> login({
    required String username,
    required String password,
  }) {
    return _service.login(
      username: username,
      password: password,
    );
  }

  Future<void> logout() => _service.logout();
}
