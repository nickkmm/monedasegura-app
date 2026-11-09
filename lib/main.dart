import 'package:flutter/material.dart';

import 'app/app.dart';
import 'data/app_store.dart';

void main() {
  runApp(MonedaSeguraApp(store: AppStore.seeded()));
}
