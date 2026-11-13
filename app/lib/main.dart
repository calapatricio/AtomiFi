import 'package:atomifi_data/atomifi_data.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'dependencies.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final database = AtomiFiDatabase(driftDatabase(name: 'atomifi'));
  runApp(AtomiFiApp(dependencies: Dependencies.onDatabase(database)));
}
