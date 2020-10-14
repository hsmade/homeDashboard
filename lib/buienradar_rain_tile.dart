import 'dart:async';
import 'dart:math';

import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:http/http.dart' as http;

class BuienRadarRainTile extends StatefulWidget {
  final double lat, lon;
  const BuienRadarRainTile (this.lat, this.lon): super();
  @override
  _BuienRadarRainTileState createState() => _BuienRadarRainTileState();

}

class _BuienRadarRainTileState extends State<BuienRadarRainTile> {
  var log = Logger('myapp.buienradar_rain_tile.dart');
  List<charts.Series<RainData, DateTime>> rain;
  bool hasRain = false;


  List<charts.Series<RainData, DateTime>> _parseRainData(String data) {
    hasRain = false;
    var result = new List<RainData>();
    data.split('\n').forEach((element) {
      // log.info("Handling rain data line: $element");
      if (element.length > 7) {
        List<String> rowItems = element.split('|');
        double rainRaw = double.parse(rowItems[0]);
        if (rainRaw > 0) {
          hasRain = true;
        }
        double rainValue = pow(10.0,((rainRaw-109)/32.0));
        List<String> timeItems = rowItems[1].split(':');
        int hour = int.parse(timeItems[0]);
        int minute = int.parse(timeItems[1]);
        // log.info("Adding rain point for ${timeItems[1]} -> $rainValue from $rainRaw");
        DateTime now = DateTime.now();
        if (hour < now.hour) {
          now = now.add(new Duration(days: 1));
        }
        DateTime date = new DateTime(now.year, now.month, now.day, hour, minute);
        result.add(RainData(date, rainValue));
      }
    });

    return [
      new charts.Series<RainData, DateTime>(
        id: 'Rain',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (RainData rain, _) => rain.date,
        measureFn: (RainData rain, _) => rain.rain,
        data: result,
      )
    ];

  }

  Future _get_rain() async {
    final response = await http.get("https://gpsgadget.buienradar.nl/data/raintext/?lat=${widget.lat}&lon=${widget.lon}").whenComplete(() => {});
    if (response.statusCode == 200) {
      List<charts.Series<RainData, DateTime>> result = _parseRainData(response.body);
      log.info("Buienradar feed returned: ${response.body}");

      setState(() {
        this.rain = result;
      });
    } else {
      log.warning("Buienradar feed returned code ${response.statusCode} and body: ${response.body}");
      return;
    }
  }


  static List<charts.Series<RainData, DateTime>> _createChart(List<RainData> data) {
    return [
      new charts.Series<RainData, DateTime>(
        id: 'Rain',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (RainData rain, _) => rain.date,
        measureFn: (RainData rain, _) => rain.rain,
        data: data,
      )
    ];
  }

  @override
  void initState() {
    super.initState();
    _get_rain();
    Timer.periodic(new Duration(seconds: 900), (timer) {
      log.info("Updating data");
      _get_rain();
    });
  }

  Widget _createGraph() {
    return new charts.TimeSeriesChart(
      rain,
      animate: false,
      defaultRenderer: new charts.LineRendererConfig<DateTime>(),
      defaultInteractions: false,
      // behaviors: [new charts.SelectNearest(), new charts.DomainHighlighter()],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (!hasRain) {
      content =
      Center(
          child: Column (
            children: [
              Expanded(flex: 3, child: Text("")),
              Expanded(flex: 1, child: Text("Geen regen voorspeld", style: TextStyle(color: Colors.white))),
              Expanded(flex: 3, child: Text("")),
            ],
          )
      );
    } else {
      content = _createGraph();
    }

    return
    GestureDetector(
      onTap: () { _get_rain(); },
      child:
        Container(
          margin: const EdgeInsets.all(10.0),
          color:Colors.grey[900],
          width: 100.0,
          height: 100.0,
          child:
              Stack (
                children: [
                  content,
                  Center(
                    child:
                      Column(
                        children: [
                          Expanded(
                            flex: 1,
                            child:
                            FittedBox(
                              fit: BoxFit.contain,
                              child: Center(
                                child: Text(
                                  "Regen",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 5,
                            child:
                            FittedBox(
                              fit: BoxFit.contain,
                              child: Center(
                                child: Text(
                                  " ",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ),

                ],
              )
        )
    );
  }
}

class RainData {
  final DateTime date;
  final double rain;

  RainData(this.date, this.rain);
}