import 'package:flutter/widgets.dart';
import 'package:sentry/sentry.dart';
import 'package:logging/logging.dart';

final sentry = SentryClient(dsn: "https://d283405d0f054e5cae76fc4abc7706ff@o463949.ingest.sentry.io/5469614");
final log = Logger('sentry.main.dart');

Future<void> logEvent(
    String message, SeverityLevel severity, Map<String, dynamic> data) async {
  final Event event = Event(
    loggerName: '',
    message: message,
    extra: data,
    level: severity,
  );

  try {
    log.fine('Sending event to sentry');
    final SentryResponse response = await sentry.capture(event: event);
    if (response.isSuccessful) {
      log.info('Success! Event ID: ${response.eventId}');
    } else {
      log.severe('Failed to report to Sentry.io: ${response.error}');
    }
  } catch (e, stackTrace) {
    log.severe(
        'Exception whilst reporting to Sentry.io\n' + stackTrace.toString());
  }
}

void logException(FlutterErrorDetails details) async {
  log.info("Sending exception to sentry");
  await sentry.captureException(
    exception: details.exception,
    stackTrace: details.stack,
  );
}