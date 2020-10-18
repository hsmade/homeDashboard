import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:http/http.dart' as http;
import 'TimeSeriesChart.dart';
import 'tile.dart';

class BuienRadarRainTile extends StatefulWidget {
  final double lat, lon;
  const BuienRadarRainTile (this.lat, this.lon): super();
  @override
  _BuienRadarRainTileState createState() => _BuienRadarRainTileState();

}

class _BuienRadarRainTileState extends State<BuienRadarRainTile> {
  var log = Logger('myapp.buienradar_rain_tile.dart');
  List<TimeSeriesData> data;
  bool hasRain = false;


  List<TimeSeriesData> _parseRainData(String data) {
    hasRain = false;
    var result = new List<TimeSeriesData>();
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
        result.add(TimeSeriesData(date, rainValue));
      }
    });

    return result;

  }

  Future _getRain() async {
    final response = await http.get("https://gpsgadget.buienradar.nl/data/raintext/?lat=${widget.lat}&lon=${widget.lon}").whenComplete(() => {});
    if (response.statusCode == 200) {
      List<TimeSeriesData> result = _parseRainData(response.body);
      // List<TimeSeriesData> result = _parseRainData(_fakeData);
      log.info("Buienradar feed returned: ${response.body}");

      setState(() {
        this.data = result;
      });
    } else {
      log.warning("Buienradar feed returned code ${response.statusCode} and body: ${response.body}");
      return;
    }
  }

  @override
  void initState() {
    super.initState();
    _getRain();
    Timer.periodic(new Duration(seconds: 900), (timer) {
      log.info("Updating data");
      _getRain();
    });
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
      content = new TimeSeriesChart(data, legendaY: "mm");

    }

    return
    GestureDetector(
      onTap: () { _getRain(); },
      child:
          Tile("Regen",
            FittedBox(
              fit: BoxFit.contain,
              child: Center(
                child: Text(
                  " ",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            )
          )
        );
  }
}

// String _fakeData = '''057|22:50
// 057|22:55
// 077|23:00
// 087|23:05
// 087|23:10
// 097|23:15
// 105|23:20
// 117|23:25
// 125|23:30
// 105|23:35
// 095|23:40
// 085|23:45
// 075|23:50
// 067|23:55
// 057|00:00
// 035|00:05
// 035|00:10
// 035|00:15
// 035|00:20
// 000|00:25
// 000|00:30
// 000|00:35
// 000|00:40
// 000|00:45''';