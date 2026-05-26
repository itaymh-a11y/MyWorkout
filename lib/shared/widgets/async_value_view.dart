import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// תצוגה אחידה לטעינה / שגיאה / תוכן לפי [AsyncValue].
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.value,
    required this.data,
    this.loading,
    this.onRetry,
    this.empty,
    this.emptyMessage = 'אין נתונים',
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget? loading;
  final VoidCallback? onRetry;
  final Widget? empty;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (d) {
        if (d is Iterable && d.isEmpty) {
          return empty ?? _defaultEmpty(context);
        }
        return data(d);
      },
      loading: () =>
          loading ??
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
      error: (e, _) => _ErrorBody(message: '$e', onRetry: onRetry),
    );
  }

  Widget _defaultEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          emptyMessage,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: onRetry,
                child: const Text('נסה שוב'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
