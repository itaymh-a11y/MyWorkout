import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/core/providers/repository_providers.dart';
import 'package:myworkout/features/plans/data/plan_repository.dart';
import 'package:myworkout/features/plans/presentation/plan_detail_screen.dart';
import 'package:myworkout/shared/models/workout_plan.dart';

/// יצירה / עריכת תוכנית אימון (שם, מנוחה, כוכב).
class PlanFormScreen extends ConsumerStatefulWidget {
  const PlanFormScreen({super.key, this.plan});

  final WorkoutPlan? plan;

  @override
  ConsumerState<PlanFormScreen> createState() => _PlanFormScreenState();
}

class _PlanFormScreenState extends ConsumerState<PlanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _restController;
  late bool _isStarred;
  bool _isSaving = false;

  bool get _isEditing => widget.plan != null;

  @override
  void initState() {
    super.initState();
    final p = widget.plan;
    _nameController = TextEditingController(text: p?.name ?? '');
    _restController = TextEditingController(
      text: '${p?.defaultRestSec ?? 90}',
    );
    _isStarred = p?.isStarred ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _restController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final uid = ref.read(currentUidProvider);
    final repo = ref.read(planRepositoryProvider);

    final plan = WorkoutPlan(
      id: widget.plan?.id ?? '',
      name: _nameController.text.trim(),
      isStarred: _isStarred,
      defaultRestSec: int.parse(_restController.text.trim()),
      createdAt: widget.plan?.createdAt,
    );

    try {
      if (_isEditing) {
        if (_isStarred && !widget.plan!.isStarred) {
          await repo.setStarred(uid, plan.id, starred: true);
        } else if (!_isStarred && widget.plan!.isStarred) {
          await repo.setStarred(uid, plan.id, starred: false);
        }
        await repo.updatePlan(
          uid,
          plan.copyWith(isStarred: _isStarred),
        );
        if (mounted) Navigator.of(context).pop(plan);
      } else {
        if (_isStarred) {
          final count = await repo.countStarredPlans(uid);
          if (count >= PlanRepository.maxStarredPlans) {
            throw PlanRepositoryException(
              'ניתן לסמן עד ${PlanRepository.maxStarredPlans} תוכניות פעילות.',
            );
          }
        }
        final id = await repo.createPlan(uid, plan.copyWith(isStarred: _isStarred));
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => PlanDetailScreen(planId: id, planName: plan.name),
            ),
          );
        }
      }
    } on PlanRepositoryException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'עריכת תוכנית' : 'תוכנית חדשה'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'שם התוכנית',
                border: OutlineInputBorder(),
                hintText: 'למשל: Push A',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'נא להזין שם' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _restController,
              decoration: const InputDecoration(
                labelText: 'מנוחה ברירת מחדל (שניות)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 0) return 'ערך לא תקין';
                return null;
              },
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('תוכנית פעילה (כוכב)'),
              subtitle: const Text('מוצגת במסך הבית — עד 3 במקביל'),
              value: _isStarred,
              onChanged: (v) => setState(() => _isStarred = v),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _isSaving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_isEditing ? 'שמור' : 'צור והמשך לתרגילים'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
