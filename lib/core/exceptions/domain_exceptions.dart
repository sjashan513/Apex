import 'package:apex/features/ranking/domain/models/ranking_model.dart';

/// Sealed error hierarchy for all domain-level failures in Apex.
/// No raw exceptions escape beyond the repository layer — only these types.
sealed class DomainException implements Exception {
  const DomainException({required this.message});
  final String message;
}

/// The OpenAI API socket did not respond within the 18-second guillotine window.
final class TimeoutException extends DomainException {
  const TimeoutException()
      : super(
            message:
                'Connection lost. The ranking engine is currently unreachable.');
}

/// The API responded but the JSON structure failed schema validation.
final class ValidationException extends DomainException {
  const ValidationException(
      {super.message =
          'The engine returned unstructured data. Let\'s try restructuring.'});
}

/// The OpenAI API key is invalid, missing, or the quota is exhausted.
final class QuotaException extends DomainException {
  const QuotaException()
      : super(
            message:
                'The engine is out of gas. Please verify your API configurations.');
}

/// The user submitted a nonsense or off-topic query — not a technical failure.
final class NonsenseException extends DomainException {
  const NonsenseException({required super.message, required this.suggestions});
  final List<SuggestedQuery> suggestions;
}
