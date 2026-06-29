import 'firebase_auth_api.dart';

class AuthApi {
  final FirebaseAuthApi _firebase;

  AuthApi({FirebaseAuthApi? firebase}) : _firebase = firebase ?? FirebaseAuthApi();

  Future<void> login(String email, String password) async {
    await _firebase.login(email: email, password: password);
  }

  Future<void> register(String email, String password) async {
    await _firebase.register(email: email, password: password);
  }

  Future<void> logout() => _firebase.logout();
}
