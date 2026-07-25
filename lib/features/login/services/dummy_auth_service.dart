import '../models/user_model.dart';

class DummyAuthService {
  static const UserModel dummyUser = UserModel(
    nik: "123",
    password: "Sitara123",
    fullName: "Haikal Alghiffari",
  );

  Future<UserModel?> login({
    required String nik,
    required String password,
  }) async {
    // simulasi request API
    await Future.delayed(const Duration(seconds: 1));

    if (nik == dummyUser.nik &&
        password == dummyUser.password) {
      return dummyUser;
    }

    return null;
  }
}