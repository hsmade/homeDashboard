import 'package:flutter/widgets.dart';
import 'package:sentry/sentry.dart';
import 'package:logging/logging.dart';
import 'package:device_info/device_info.dart';
import 'package:package_info/package_info.dart';

final log = Logger('sentry.main.dart');

Future<String> getVersion() async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  return "HomeDashboardFlutter@${packageInfo.version}";
}

Future<void> logEvent(
    String message, SeverityLevel severity, Map<String, dynamic> data) async {
  WidgetsFlutterBinding.ensureInitialized();
  final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
  final info = await deviceInfoPlugin.androidInfo;
  final version = await getVersion();
  final sentry = SentryClient(dsn: "https://d283405d0f054e5cae76fc4abc7706ff@o463949.ingest.sentry.io/5469614",
    environmentAttributes: Event(extra: {
      'model': info.model,
      'board': info.board,
      'brand': info.brand,
      'device': info.device,
    }, release: version)
  );

  final Event event = Event(
    loggerName: '',
    message: message,
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
  WidgetsFlutterBinding.ensureInitialized();
  final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
  final info = await deviceInfoPlugin.androidInfo;
  final version = await getVersion();
  final sentry = SentryClient(dsn: "https://d283405d0f054e5cae76fc4abc7706ff@o463949.ingest.sentry.io/5469614",
      environmentAttributes: Event(extra: {
        'model': info.model,
        'board': info.board,
        'brand': info.brand,
        'device': info.device,
      }, release: version)
  );

  log.info("Sending exception to sentry");
  await sentry.captureException(
    exception: details.exception,
    stackTrace: details.stack,
  );
}