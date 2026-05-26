import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/core/providers/repository_providers.dart';

/// מאשר ומוחק אימון מ-Firestore (סטים + מסמך session).
Future<bool> confirmAndDeleteSession(
  BuildContext context,
  WidgetRef ref, {
  required String sessionId,
  required String planName,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('מחיקת אימון'),
      content: Text('למחוק את האימון "$planName"?\nהפעולה לא ניתנת לביטול.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('ביטול'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
          ),
          child: const Text('מחק'),
        ),
      ],
    ),
  );

  if (ok != true || !context.mounted) return false;

  try {
    final uid = ref.read(currentUidProvider);
    await ref.read(sessionRepositoryProvider).deleteSession(uid, sessionId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('האימון נמחק')),
      );
    }
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('שגיאה במחיקה: $e')),
      );
    }
    return false;
  }
}
