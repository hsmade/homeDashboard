// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

//import 'dart:html';

import 'package:flutter/material.dart';
import 'package:myapp/PowerUsageTile.dart';
import 'package:myapp/tile.dart';
import 'package:myapp/buienradar_rain_tile.dart';
import 'package:myapp/buienradar_weather_tile.dart';
import 'package:myapp/mincraft_tile.dart';
import 'package:myapp/wtw_tile.dart';
import 'package:sentry/sentry.dart';
import 'mqtt.dart';
import 'package:logging/logging.dart';
import 'package:logging_appenders/logging_appenders.dart';
import 'temperature_tile.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import 'sentry.dart';


final _logger = Logger('myapp.main.dart');

void main() async {
  Logger.root.level = Level.ALL;
  final _lokiAppender = new LokiApiAppender(
    server: "loki.kiezelsteen18.nl",
    labels: {"app": "homeDashboard"},
    username: "", password: ""
  );
  PrintAppender().attachToLogger(Logger.root);
  _lokiAppender.attachToLogger(Logger.root);
  _logger.info("Starting main");

  FlutterError.onError = (details, {bool forceReport = false}) {logException(details);};
  await logEvent("starting app", SeverityLevel.info, {});
  runZonedGuarded(
        () => runApp(MyApp()),
        (error, stackTrace) {
          FlutterErrorDetails details = new FlutterErrorDetails(exception: error, stack: stackTrace);
          logException(details);
        },
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "--",
      theme: ThemeData(
        primaryColor: Colors.yellow,
        canvasColor: Colors.black45,
      ),
      home: MainWidget(),
    );
  }
}

class MainWidget extends StatefulWidget {
  @override
  _MainWidgetState createState() => _MainWidgetState();
}

class _MainWidgetState extends State<MainWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return SafeArea(
      child: Scaffold(
      body: _buildTiles(),
    ));
  }

  Widget _buildTiles() {
    return GridView.count(
      crossAxisCount: 3,
      padding: const EdgeInsets.all(4),
      mainAxisSpacing: 0,
      crossAxisSpacing: 0,
      children: [
        new TemperatureTile(new MqttClient("mqtt.kiezelsteen18.nl", Uuid().v4())),
        new WtWTile("https://prometheus.kiezelsteen18.nl"),
        new BuienRadarWeatherTile(6260),
        new BuienRadarRainTile(52.02, 5.18),
        new MinecraftTile("https://prometheus.kiezelsteen18.nl"),
        new PowerUsageTile(new MqttClient("mqtt.kiezelsteen18.nl", Uuid().v4())),
        new Tile("leeg", Text("", style: TextStyle(color: Colors.white))),
        new Tile("leeg", Text("", style: TextStyle(color: Colors.white))),
      ],
    );
  }
}
