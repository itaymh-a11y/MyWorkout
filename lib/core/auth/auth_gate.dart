import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/core/navigation/app_shell.dart';
import 'package:myworkout/features/auth/application/auth_providers.dart';
import 'package:myworkout/features/auth/presentation/auth_screen.dart';
import 'package:myworkout/features/auth/utils/auth_error_messages.dart';
import 'package:myworkout/features/workout/presentation/workout_draft_gate.dart';

/// מנתב בין מסך התחברות לבין האפליקציה הראשית לפי מצב Auth.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const AuthScreen();
        }
        return const WorkoutDraftGate(child: AppShell());
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 16),
                Text(
                  authErrorMessage(error),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
