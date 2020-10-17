import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:http/http.dart' as http;

class BuienRadarWeatherTile extends StatefulWidget {
  final int station;
  const BuienRadarWeatherTile (this.station): super();
  @override
  _BuienRadarWeatherTileState createState() => _BuienRadarWeatherTileState();

}

class _BuienRadarWeatherTileState extends State<BuienRadarWeatherTile> {
  var log = Logger('myapp.buienradar_weather_tile.dart');
  double temperature;
  String icon;


  Future _get_weather(int station) async {
    final response = await http.get("https://data.buienradar.nl/2.0/feed/json").whenComplete(() => {});
    if (response.statusCode == 200) {
      Map<String, dynamic> result = jsonDecode(response.body);
      log.info("Buienradar feed returned: $result");
      final stations = result['actual']['stationmeasurements'];
      var myStation;
      for (var i=0; i<stations.length; i++) {
        if (stations[i]['stationid'] == station) {
          log.info("Found station $station");
          myStation = stations[i];
          break;
        }
      }
      if (myStation == null) {
        log.warning("Could not find stations $station");
        return;
      }

      setState(() {
        log.info("Setting T=${myStation['temperature']} and url=${myStation['iconurl']}");
        this.temperature = myStation['temperature'];
        this.icon = myStation['iconurl'];
      });
    } else {
      log.warning("Buienradar feed returned code ${response.statusCode} and body: ${response.body}");
      return;
    }
  }


  @override
  void initState() {
    _get_weather(widget.station);
    Timer.periodic(new Duration(seconds: 900), (timer) {
      log.info("Updating data");
      _get_weather(widget.station);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // _update_values();

    return
    GestureDetector(
      onTap: () { _get_weather(widget.station); },
      child: Container(
          margin: const EdgeInsets.all(10.0),
          color:Colors.grey[900],
          width: 100.0,
          height: 100.0,
          child: Column(
            children: [
              Expanded(
                child:
                FittedBox(
                  fit: BoxFit.contain,
                  child: Center(
                    child: Text(
                      "     Weer      ",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Center(
                      child: (icon != null)?Image.network(icon):Text(" - - ")
                  ),
                ),
              ),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Center(
                      child: Text("$temperature°C", style: TextStyle(color: Colors.white))
                  ),
                ),
              ),
            ],
          )
      )
    );
  }
}
