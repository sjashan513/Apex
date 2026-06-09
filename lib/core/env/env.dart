/// Responsible for loading and exposing environment variables from the .env asset.
/// This is the single access point for all secrets in the app.
/// Call [Env.load] once in main() before runApp — never after.
library;

import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  Env._(); // non-instantiable

  /// Must be called once at app startup, before runApp().
  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
  }

  /// The OpenAI API key. Throws [StateError] if not found in .env.
  static String get openAiKey {
    final key = dotenv.env['OPENAI_API_KEY'];
    if (key == null || key.isEmpty) {
      throw StateError(
        'OPENAI_API_KEY is missing from .env. '
        'Add it to the project root .env file before running.',
      );
    }
    return key;
  }

  /// The OpenAI model string. Throws [StateError] if not found in .env.
  /// Swap the value in .env to change models without touching Dart code.
  /// Example: OPENAI_MODEL=gpt-4.1-nano
  static String get openAiModel {
    final model = dotenv.env['OPENAI_MODEL'];
    if (model == null || model.isEmpty) {
      throw StateError(
        'OPENAI_MODEL is missing from .env. '
        'Add it to the project root .env file before running.',
      );
    }
    return model;
  }
}
