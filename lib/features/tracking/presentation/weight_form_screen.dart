import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/core/providers/repository_providers.dart';
import 'package:myworkout/core/utils/session_format.dart';
import 'package:myworkout/features/tracking/application/tracking_providers.dart';
import 'package:myworkout/features/tracking/domain/tracking_summary.dart';

class WeightFormScreen extends ConsumerStatefulWidget {
  const WeightFormScreen({super.key, required this.dayKey});

  final String dayKey;

  static void open(BuildContext context, {required String dayKey}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WeightFormScreen(dayKey: dayKey),
      ),
    );
  }

  @override
  ConsumerState<WeightFormScreen> createState() => _WeightFormScreenState();
}

class _WeightFormScreenState extends ConsumerState<WeightFormScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  var _saving = false;
  var _ready = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    try {
      final logs = await ref.read(weightLogsProvider.future);
      final existing = weightOnDay(logs, widget.dayKey);
      if (!mounted) return;
      if (existing != null) {
        _controller.text = formatGrams(existing.kg);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('לא נטען משקל: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _ready = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final kg = parseDecimal(_controller.text);
    if (kg == null) return;
    final day = parseDayKey(widget.dayKey);
    if (day == null) return;
    setState(() => _saving = true);
    try {
      final uid = ref.read(currentUidProvider);
      await ref.read(weightRepositoryProvider).upsertForDay(
            uid: uid,
            dayKey: widget.dayKey,
            weighedAt: day,
            kg: kg,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('לא נשמר: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final day = parseDayKey(widget.dayKey);
    return Scaffold(
      appBar: AppBar(title: const Text('שקילה')),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (day != null)
                    Text(
                      formatSessionDate(day),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _controller,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'משקל',
                      border: OutlineInputBorder(),
                      suffixText: 'ק״ג',
                    ),
                    validator: (value) {
                      final kg = parseDecimal(value ?? '');
                      if (kg == null || kg <= 0 || kg >= 500) {
                        return 'הכנס משקל בין 1 ל-499';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: const Text('שמור שקילה'),
                  ),
                ],
              ),
            ),
    );
  }
}
