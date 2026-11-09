import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/nav_destination.dart';
import '../../app/routes.dart';
import '../../data/domain_error.dart';
import '../../data/format.dart';
import '../../data/labels.dart';
import '../../data/models/models.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/widgets.dart';
import 'case_detail_page.dart';

/// Case detail host: reads the case from the store, owns the label form
/// and takes, labels and navigates for [CaseDetailPage].
class CaseDetailScreen extends StatefulWidget {
  const CaseDetailScreen({super.key, required this.caseId});

  final String caseId;

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> {
  final TextEditingController _notes = TextEditingController();
  CaseLabel? _selectedLabel;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final view = AppScope.read(context).caseById(widget.caseId);
    if (view != null && view.status == CaseStatus.RESOLVED) {
      _selectedLabel = view.label;
      _notes.text = view.fraudCase.notes ?? '';
    }
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  void _back() => Navigator.of(context).pushReplacementNamed(AppRoutes.cases);

  void _take(String id) => AppScope.read(context).takeCase(id);

  void _save(CaseView view) {
    final store = AppScope.read(context);
    final label = _selectedLabel!;
    final notes = _notes.text.trim();
    try {
      if (view.status == CaseStatus.OPEN) store.takeCase(view.id);
      store.resolveCase(view.id, label, notes: notes.isEmpty ? null : notes);
    } on DomainError {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar la etiqueta')),
      );
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pushReplacementNamed(AppRoutes.cases);
    messenger.showSnackBar(
      SnackBar(
        content: Text('Caso ${view.shortId} etiquetado como ${label.label}'),
      ),
    );
  }

  String _assignment(CaseView view, String? currentUserId) {
    return switch (view.status) {
      CaseStatus.OPEN => 'sin asignar',
      CaseStatus.IN_REVIEW when view.assignedTo?.id == currentUserId =>
        'asignado a ti',
      CaseStatus.IN_REVIEW => 'asignado a ${view.assignedTo?.fullName ?? ''}',
      CaseStatus.RESOLVED => 'resuelto · ${view.label?.label ?? ''}',
    };
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final view = store.caseById(widget.caseId);
    if (view == null) {
      return AppShell(
        active: NavDestination.cases,
        title: 'Caso',
        subtitle: '',
        child: Column(
          spacing: AppSpacing.lg,
          children: [
            const EmptyState(
              icon: AppIcons.inbox,
              title: 'No encontramos este caso',
              hint: 'Puede que ya no exista.',
            ),
            AppButton(
              label: 'Volver a la cola',
              icon: AppIcons.back,
              variant: AppButtonVariant.ghost,
              onPressed: _back,
            ),
          ],
        ),
      );
    }

    final now = store.now;
    final currentUserId = store.currentUser?.id;
    final canResolve = store.can(PermissionCode.CASE_RESOLVE);
    final rules = <String, RuleView>{
      for (final hit in view.decision.ruleHits)
        hit.ruleId: ?store.ruleById(hit.ruleId),
    };

    return AppShell(
      active: NavDestination.cases,
      title: 'Caso ${view.shortId}',
      subtitle:
          'Abierto ${formatAgo(view.openedAt, now)} · '
          '${_assignment(view, currentUserId)}',
      child: CaseDetailPage(
        view: view,
        rules: rules,
        now: now,
        currentUserId: currentUserId,
        canResolve: canResolve,
        selectedLabel: _selectedLabel,
        notes: _notes,
        onBack: _back,
        onTake: view.status == CaseStatus.OPEN && canResolve
            ? () => _take(view.id)
            : null,
        onSelectLabel: (label) => setState(() => _selectedLabel = label),
        onSave: _selectedLabel == null ? null : () => _save(view),
      ),
    );
  }
}
