import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_api.dart';

final authApiProvider = Provider<AuthApi>((ref) => AuthApi());

final authLoadingProvider = StateProvider<bool>((ref) => false);
final authErrorProvider = StateProvider<String?>((ref) => null);

final authActionsProvider = Provider<AuthActions>((ref) {
  final api = ref.watch(authApiProvider);
  return AuthActions(ref, api);
});

class AuthActions {
  final Ref ref;
  final AuthApi api;

  AuthActions(this.ref, this.api);

  Future<void> login(String email, String password) async {
    ref.read(authLoadingProvider.notifier).state = true;
    ref.read(authErrorProvider.notifier).state = null;
    try {
      await api.login(email, password);
    } catch (e) {
      ref.read(authErrorProvider.notifier).state = e.toString();
      rethrow;
    } finally {
      ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  Future<void> register(String email, String password) async {
    ref.read(authLoadingProvider.notifier).state = true;
    ref.read(authErrorProvider.notifier).state = null;
    try {
      await api.register(email, password);
    } catch (e) {
      ref.read(authErrorProvider.notifier).state = e.toString();
      rethrow;
    } finally {
      ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  Future<void> logout() async {
    await api.logout();
  }
}
