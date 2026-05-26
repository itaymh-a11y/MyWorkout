import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/features/auth/application/auth_providers.dart';
import 'package:myworkout/core/theme/app_colors.dart';
import 'package:myworkout/core/widgets/app_logo.dart';
import 'package:myworkout/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:myworkout/features/auth/utils/auth_error_messages.dart';

/// מסך התחברות / הרשמה באימייל וסיסמה.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isRegisterMode = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final repo = ref.read(authRepositoryProvider);
    final email = _emailController.text;
    final password = _passwordController.text;

    try {
      if (_isRegisterMode) {
        await repo.signUpWithEmail(email: email, password: password);
      } else {
        await repo.signInWithEmail(email: email, password: password);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authErrorMessage(error)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleMode() {
    setState(() {
      _isRegisterMode = !_isRegisterMode;
      _confirmPasswordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: AppLogo.large()),
                    const SizedBox(height: 16),
                    Text(
                      _isRegisterMode
                          ? 'צור חשבון חדש כדי להתחיל לעקוב אחרי האימונים שלך'
                          : 'התחבר כדי להמשיך',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 32),
                    AuthTextField(
                      controller: _emailController,
                      label: 'אימייל',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        final trimmed = value?.trim() ?? '';
                        if (trimmed.isEmpty) return 'נא להזין אימייל';
                        if (!trimmed.contains('@')) {
                          return 'כתובת אימייל לא תקינה';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _passwordController,
                      label: 'סיסמה',
                      obscureText: _obscurePassword,
                      textInputAction: _isRegisterMode
                          ? TextInputAction.next
                          : TextInputAction.done,
                      onFieldSubmitted: _isRegisterMode ? null : (_) => _submit(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'נא להזין סיסמה';
                        }
                        if (value.length < 6) {
                          return 'הסיסמה חייבת להכיל לפחות 6 תווים';
                        }
                        return null;
                      },
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 18,
                        ),
                        label: Text(_obscurePassword ? 'הצג סיסמה' : 'הסתר סיסמה'),
                      ),
                    ),
                    if (_isRegisterMode) ...[
                      const SizedBox(height: 8),
                      AuthTextField(
                        controller: _confirmPasswordController,
                        label: 'אימות סיסמה',
                        obscureText: _obscureConfirm,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        validator: (value) {
                          if (value != _passwordController.text) {
                            return 'הסיסמות אינן תואמות';
                          }
                          return null;
                        },
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() => _obscureConfirm = !_obscureConfirm);
                          },
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 18,
                          ),
                          label: Text(
                            _obscureConfirm ? 'הצג סיסמה' : 'הסתר סיסמה',
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(_isRegisterMode ? 'הרשמה' : 'התחברות'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _isLoading ? null : _toggleMode,
                      child: Text(
                        _isRegisterMode
                            ? 'כבר יש לך חשבון? התחבר'
                            : 'אין לך חשבון? הירשם',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
