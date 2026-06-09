/// Constructs and exposes the single Dio HTTP client for all API communication.
/// Owns the 18-second timeout guillotine — no request survives beyond this window.
library;

import 'package:dio/dio.dart';
import '../env/env.dart';

class ApiClient {
  ApiClient._();

  static Dio? _instance;

  /// Returns the singleton Dio instance, constructing it on first access.
  static Dio get instance {
    _instance ??= _build();
    return _instance!;
  }

  static Dio _build() {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.openai.com/v1/',
        connectTimeout: const Duration(seconds: 25),
        receiveTimeout: const Duration(seconds: 25),
        sendTimeout: const Duration(seconds: 25),
        headers: {
          'Authorization': 'Bearer ${Env.openAiKey}',
          'Content-Type': 'application/json',
        },
      ),
    );

    // Log requests and responses in debug mode only.
    assert(() {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (log) => print(log), // ignore: avoid_print
        ),
      );
      return true;
    }());

    return dio;
  }
}
