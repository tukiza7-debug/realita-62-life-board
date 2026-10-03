import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (error, stack) {
    // A SharedPreferences failure (corrupted prefs file on disk, IO error,
    // etc.) must never crash-loop the app. Fall back to null; the recovery
    // screen will let the user start fresh.
    debugPrint('SharedPreferences.getInstance failed: $error\n$stack');
  }

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exception}\n${details.stack}');
  };

  final platformErrors = <FlutterErrorDetails>[];

  runZonedGuarded<Future<void>>(
    () async {
      runApp(RealitaApp(prefs: prefs, platformErrors: platformErrors));
    },
    (error, stack) {
      debugPrint('Uncaught zone error: $error\n$stack');
      final details = FlutterErrorDetails(
        exception: error,
        stack: stack,
        context: ErrorDescription('Uncaught zone error'),
      );
      platformErrors.add(details);
      FlutterError.presentError(details);
    },
    zoneSpecification: ZoneSpecification(
      handleUncaughtError: (self, parent, zone, error, stack) {
        debugPrint('Zone.handleUncaughtError: $error\n$stack');
        parent.handleUncaughtError(zone, error, stack);
      },
    ),
  );
}
