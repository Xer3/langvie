// lib/features/auth/auth_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/app_state.dart';
import '../../app/ui/app_colors.dart';
import 'firebase_auth_api.dart';

final firebaseAuthApiProvider =
    Provider<FirebaseAuthApi>((ref) => FirebaseAuthApi());

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();
  final _nickCtrl = TextEditingController();

  bool _isLogin = true;
  bool _loading = false;
  String? _err;

  bool _hidePass = true;
  bool _hidePass2 = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    _nickCtrl.dispose();
    super.dispose();
  }

  void _dismissKeyboard() => FocusScope.of(context).unfocus();

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Nieprawidłowy format email.';
      case 'wrong-password':
        return 'Nieprawidłowe hasło.';
      case 'user-not-found':
      case 'invalid-credential':
        return 'Nieprawidłowy email lub hasło (konto może nie istnieć).';
      case 'email-already-in-use':
        return 'Ten email jest już zajęty.';
      case 'weak-password':
        return 'Hasło jest za słabe (min. 6 znaków).';
      case 'too-many-requests':
        return 'Zbyt wiele prób. Spróbuj ponownie później.';
      case 'network-request-failed':
        return 'Brak połączenia z internetem.';
      default:
        return 'Nieprawidłowy email lub hasło (konto może nie istnieć).';
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailCtrl.text.trim();

    if (email.isEmpty) {
      setState(() => _err = 'Wpisz email, aby zresetować hasło.');
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _err = 'Nieprawidłowy format email.');
      return;
    }

    setState(() {
      _loading = true;
      _err = null;
    });

    try {
      await FirebaseAuth.instance.setLanguageCode('pl');
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Wysłano link do resetu hasła na: $email'),
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _err = _mapFirebaseError(e));
    } catch (_) {
      setState(() => _err = 'Nie udało się wysłać linku resetującego hasło.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final pass2 = _pass2Ctrl.text;
    final nick = _nickCtrl.text.trim();

    if (email.isEmpty) {
      setState(() => _err = 'Podaj email.');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _err = 'Nieprawidłowy format email.');
      return;
    }
    if (pass.isEmpty) {
      setState(() => _err = 'Podaj hasło.');
      return;
    }

    if (!_isLogin) {
      if (nick.isEmpty) {
        setState(() => _err = 'Podaj nick.');
        return;
      }
      if (nick.length < 3) {
        setState(() => _err = 'Nick musi mieć min. 3 znaki.');
        return;
      }
      if (pass.length < 6) {
        setState(() => _err = 'Hasło musi mieć min. 6 znaków.');
        return;
      }
      if (pass2.isEmpty) {
        setState(() => _err = 'Powtórz hasło.');
        return;
      }
      if (pass != pass2) {
        setState(() => _err = 'Hasła nie są takie same.');
        return;
      }
    }

    setState(() {
      _loading = true;
      _err = null;
    });

    try {
      final api = ref.read(firebaseAuthApiProvider);

      if (_isLogin) {
        await api.login(email: email, password: pass);

        await ref.read(appStateProvider.notifier).markLoggedInFromLogin(
              FirebaseAuth.instance.currentUser,
            );
      } else {
        await api.register(email: email, password: pass, nickname: nick);

        await ref.read(appStateProvider.notifier).startOnboardingAfterRegister(
              FirebaseAuth.instance.currentUser,
            );

        if (mounted) context.go('/onboarding/test');
        return;
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _err = _mapFirebaseError(e));
    } catch (_) {
      setState(
        () => _err = 'Nieprawidłowy email lub hasło (konto może nie istnieć).',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _dismissKeyboard,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          color: AppColors.bg,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, c) {
                final topSpace = (c.maxHeight * 0.06).clamp(14.0, 56.0);

                return Center(
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: topSpace),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: Image.asset(
                              'assets/logo.png',
                              width: 187,
                              height: 187,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Langvie',
                            style: GoogleFonts.atma(
                              fontSize: 35,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF111111),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _AuthPanel(
                            isLogin: _isLogin,
                            loading: _loading,
                            err: _err,
                            onCloseErr: () => setState(() => _err = null),
                            onToggleMode: _loading
                                ? null
                                : () {
                                    setState(() {
                                      _isLogin = !_isLogin;
                                      _err = null;
                                      _passCtrl.clear();
                                      _pass2Ctrl.clear();
                                    });
                                  },
                            onSubmit: _loading ? null : _submit,
                            onForgotPassword:
                                _loading ? null : () => _resetPassword(),
                            hidePass: _hidePass,
                            hidePass2: _hidePass2,
                            onToggleHidePass: () =>
                                setState(() => _hidePass = !_hidePass),
                            onToggleHidePass2: () =>
                                setState(() => _hidePass2 = !_hidePass2),
                            emailCtrl: _emailCtrl,
                            passCtrl: _passCtrl,
                            pass2Ctrl: _pass2Ctrl,
                            nickCtrl: _nickCtrl,
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthPanel extends StatelessWidget {
  final bool isLogin;
  final bool loading;
  final String? err;

  final VoidCallback onCloseErr;
  final VoidCallback? onToggleMode;
  final VoidCallback? onSubmit;
  final VoidCallback? onForgotPassword;

  final bool hidePass;
  final bool hidePass2;
  final VoidCallback onToggleHidePass;
  final VoidCallback onToggleHidePass2;

  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final TextEditingController pass2Ctrl;
  final TextEditingController nickCtrl;

  const _AuthPanel({
    required this.isLogin,
    required this.loading,
    required this.err,
    required this.onCloseErr,
    required this.onToggleMode,
    required this.onSubmit,
    required this.onForgotPassword,
    required this.hidePass,
    required this.hidePass2,
    required this.onToggleHidePass,
    required this.onToggleHidePass2,
    required this.emailCtrl,
    required this.passCtrl,
    required this.pass2Ctrl,
    required this.nickCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.blue,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Center(
            child: Text(
              isLogin ? 'Zaloguj się' : 'Załóż konto',
              textAlign: TextAlign.center,
              style: GoogleFonts.atma(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                if (err != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            err!,
                            style: GoogleFonts.atma(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: onCloseErr,
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (!isLogin) ...[
                  _NiceField(
                    controller: nickCtrl,
                    label: 'Nick',
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                ],
                _NiceField(
                  controller: emailCtrl,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                _NiceField(
                  controller: passCtrl,
                  label: 'Hasło',
                  obscureText: hidePass,
                  textInputAction:
                      isLogin ? TextInputAction.done : TextInputAction.next,
                  suffixIcon: IconButton(
                    onPressed: onToggleHidePass,
                    icon: Icon(
                      hidePass ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                ),
                if (isLogin) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: onForgotPassword,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.blue,
                        textStyle: GoogleFonts.atma(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                      child: const Text('Nie pamiętasz hasła?'),
                    ),
                  ),
                ],
                if (!isLogin) ...[
                  const SizedBox(height: 12),
                  _NiceField(
                    controller: pass2Ctrl,
                    label: 'Powtórz hasło',
                    obscureText: hidePass2,
                    textInputAction: TextInputAction.done,
                    suffixIcon: IconButton(
                      onPressed: onToggleHidePass2,
                      icon: Icon(
                        hidePass2 ? Icons.visibility_off : Icons.visibility,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: GoogleFonts.atma(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              onPressed: onSubmit,
              child: Text(
                loading ? '...' : (isLogin ? 'Zaloguj' : 'Zarejestruj'),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onToggleMode,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              textStyle: GoogleFonts.atma(
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
            child: Text(
              isLogin ? 'Nie masz konta? Rejestracja' : 'Masz konto? Logowanie',
            ),
          ),
        ],
      ),
    );
  }
}

class _NiceField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputAction? textInputAction;

  const _NiceField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: suffixIcon,
      ),
    );
  }
}