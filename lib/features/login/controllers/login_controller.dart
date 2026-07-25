import '../models/user_model.dart';
import '../services/dummy_auth_service.dart';

class LoginController {
  final DummyAuthService _service = DummyAuthService();

  Future<UserModel?> login({
    required String nik,
    required String password,
  }) {
    return _service.login(
      nik: nik,
      password: password,
    );
  }
}