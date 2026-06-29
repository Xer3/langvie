import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthApi {
  final FirebaseAuth _auth;
  FirebaseAuthApi({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> register({
    required String email,
    required String password,
    required String nickname,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = cred.user;
    if (user != null) {
      await user.updateDisplayName(nickname.trim());
      await user.reload();
    }

    return cred;
  }

  Future<void> updateNickname(String nickname) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.updateDisplayName(nickname.trim());
    await user.reload();
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> logout() => _auth.signOut();
}