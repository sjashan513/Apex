/// Entry point. Initializes the Flutter engine, loads environment variables,
/// and mounts the Riverpod ProviderScope before handing control to the app.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/env/env.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // load the .env file from assets
  await Env.load();

  // mount ProviderScope and launch the app
  runApp(
    const ProviderScope(
      child: ApexApp(),
    ),
  );
}
