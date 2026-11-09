import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/nav_destination.dart';
import '../../data/domain_error.dart';
import '../../data/models/models.dart';
import '../../widgets/widgets.dart';
import 'models_page.dart';

/// The production model, the decision thresholds, the version registry and
/// the feature importance, with retraining for users with `MODEL_TRAIN`.
class ModelsScreen extends StatefulWidget {
  const ModelsScreen({super.key});

  @override
  State<ModelsScreen> createState() => _ModelsScreenState();
}

class _ModelsScreenState extends State<ModelsScreen> {
  void _retrain() {
    final messenger = ScaffoldMessenger.of(context);
    final ModelVersion created;
    try {
      created = AppScope.read(context).retrainNow();
    } on DomainError {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('No se pudo reentrenar: no hay un modelo activo.'),
        ),
      );
      return;
    }
    final message = created.status == ModelStatus.ACTIVE
        ? '${created.version} entrenado y activado.'
        : '${created.version} quedó como candidato: no pasó el control de '
              'calidad.';
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final thresholds = store.scoreThresholds;
    return AppShell(
      active: NavDestination.models,
      title: 'Modelos',
      subtitle: 'Modelo de scoring · LightGBM',
      child: ModelsPage(
        models: store.models,
        activeModel: store.activeModel,
        reviewThreshold: thresholds.review,
        blockThreshold: thresholds.block,
        now: store.now,
        onRetrain: store.can(PermissionCode.MODEL_TRAIN) ? _retrain : null,
      ),
    );
  }
}
