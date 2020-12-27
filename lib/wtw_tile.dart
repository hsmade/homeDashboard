import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:weather_icons/weather_icons.dart';
import 'package:http/http.dart' as http;
import 'tile.dart';
import 'TimeSeriesChart.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class WtWTile extends StatefulWidget {
  final String prometheusURL;
  const WtWTile (this.prometheusURL): super();
  @override
  _WtWTileState createState() => _WtWTileState();

}

class _WtWTileState extends State<WtWTile> {
  var log = Logger('myapp.wtw_tile.dart');
  final cubicVolume = 402;
  double temperatureDifference = 0;
  double humidityDifference = 0;
  double fanExtract = 0;
  double fanDifference = 0;
  double powerConsumption = 0;
  List<TimeSeriesData> temperatureData = [];
  List<TimeSeriesData> humidityData = [];
  List<TimeSeriesData> fanData = [];


  Future<String> _getPrometheusValue(String metric) async {
    final response = await http.get("${widget.prometheusURL}/api/v1/query?query=${Uri.encodeComponent(metric)}").whenComplete(() => {});
    if (response.statusCode == 200) {
      Map<String, dynamic> result = jsonDecode(response.body);
      log.info("Prometheus returned: $result");
      return result['data']['result'][0]['value'][1];
    } else {
      log.warning("Prometheus returned code ${response.statusCode} and body: ${response.body}");
      return "";
    }
  }

  Future<List<TimeSeriesData>> _getPrometheusRange(String metric, Duration duration) async {
    List<TimeSeriesData> data = new List<TimeSeriesData>();
    DateTime end = new DateTime.now();
    DateTime start = end.subtract(duration);
    String url = "${widget.prometheusURL}/api/v1/query_range?query=${Uri.encodeComponent(metric)}&step=14&start=${start.millisecondsSinceEpoch/1000}&end=${end.millisecondsSinceEpoch/1000}";
    final response = await http.get(url).whenComplete(() => {});
    if (response.statusCode == 200) {
      Map<String, dynamic> result = jsonDecode(response.body);
      log.info("Prometheus range returned: $result");
      List<dynamic> items = result['data']['result'][0]['values'];
      items.forEach((element) {
        data.add(new TimeSeriesData(new DateTime.fromMicrosecondsSinceEpoch((element[0] * 1000).round()), double.parse(element[1])));
      });
      return data;
    } else {
      log.warning("Prometheus returned code ${response.statusCode} and body: ${response.body}");
      return [];
    }
  }

  _updateValues() async {
    Duration duration = new Duration(hours: 1);
    final extractTemp = double.parse(await _getPrometheusValue('temperature_c{domain="sensor",entity="sensor.comfoairq_inside_temperature"}'));
    final supplyTemp = double.parse(await _getPrometheusValue('temperature_c{domain="sensor",entity="sensor.comfoairq_supply_temperature"}'));
    final extractHum = double.parse(await _getPrometheusValue('humidity_percent{domain="sensor",entity="sensor.comfoairq_inside_humidity"}'));
    final supplyHum = double.parse(await _getPrometheusValue('humidity_percent{domain="sensor",entity="sensor.comfoairq_supply_humidity"}'));
    final exhaustFan = double.parse(await _getPrometheusValue('sensor_unit_rpm{domain="sensor",entity="sensor.comfoairq_exhaust_fan_speed"}'));
    final supplyFan = double.parse(await _getPrometheusValue('sensor_unit_rpm{domain="sensor",entity="sensor.comfoairq_supply_fan_speed"}'));
    final powerConsumption = double.parse(await _getPrometheusValue('power_w{domain="sensor",entity="sensor.comfoairq_power_usage"}'));
    this.temperatureData = await _getPrometheusRange('(sum(temperature_c{domain="sensor",entity="sensor.comfoairq_supply_temperature"}) - sum(temperature_c{domain="sensor",entity="sensor.comfoairq_inside_temperature"}))', duration);
    this.humidityData = await _getPrometheusRange('(sum(humidity_percent{domain="sensor",entity="sensor.comfoairq_supply_humidity"}) - sum(humidity_percent{domain="sensor",entity="sensor.comfoairq_inside_humidity"}))', duration);
    this.fanData = await _getPrometheusRange('sensor_unit_rpm{domain="sensor",entity="sensor.comfoairq_exhaust_fan_speed"}', duration);

    setState(() {
      this.temperatureDifference = supplyTemp - extractTemp;
      this.humidityDifference = supplyHum - extractHum;
      this.fanExtract = exhaustFan;
      this.fanDifference = supplyFan - exhaustFan;
      this.powerConsumption = powerConsumption;
    });
  }

  @override
  void initState() {
    _updateValues();
    Timer.periodic(new Duration(seconds: 30), (timer) {
      log.info("Updating data");
      _updateValues();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return
    Tile("Ventilatie",
        Column(
        children: [
          Expanded(
            child: Card(
              color: Colors.grey[850],
              child: FittedBox(
                fit: BoxFit.fill,
                child: Row(
                  children: [
                    Column(children: [
                      SizedBox(height: 150, width: 50, child: Column(children: [
                        Expanded(child: FittedBox(fit: BoxFit.contain, child: Icon(WeatherIcons.thermometer, color: Colors.white))),
                        Expanded(child: FittedBox(fit: BoxFit.contain, child: Text("${temperatureDifference.toStringAsFixed(1)} °C", style: TextStyle(color: Colors.white)))),
                      ])),
                    ]),
                    // Expanded(child:
                    SizedBox(width: 400, height: 150, child:
                        TimeSeriesChart(temperatureData,
                            colorFn: (_, value) {
                              if (temperatureData[value].data < 0) return charts.MaterialPalette.blue.shadeDefault;
                              else return charts.MaterialPalette.red.shadeDefault;
                            },
                            areaColorFn: (_, __) => charts.MaterialPalette.transparent,
                        )
                    ),
                  ],
                )
              )
            ),
          ),
          Expanded(
          child: Card(
            color: Colors.grey[850],
            child: FittedBox(
              fit: BoxFit.contain,
                child: Row(
                  children: [
                   SizedBox(height: 150, width: 50, child: Column(children: [
                      Expanded(child: FittedBox(fit: BoxFit.contain, child: Icon(WeatherIcons.humidity, color: Colors.white))),
                      Expanded(child: FittedBox(fit: BoxFit.contain, child: Text("${humidityDifference.round()} %", style: TextStyle(color: Colors.white)))),
                    ])),
                    SizedBox(width: 400, height: 150, child:
                      TimeSeriesChart(humidityData,
                          colorFn: (_, value) {
                            if (humidityData[value].data < 0) return charts.MaterialPalette.blue.shadeDefault;
                            else return charts.MaterialPalette.red.shadeDefault;
                          },
                          areaColorFn: (_, __) => charts.MaterialPalette.transparent,
                      )
                    ),
                  ],
                ),
              )
            ),
          ),
          Expanded(
            child: Card(
              color: Colors.grey[850],
              child: FittedBox(
              fit: BoxFit.contain,
                child: Row(
                  children: [
                    Column(children: [
                      SizedBox(height: 150, width: 50, child: Column(children: [
                        Expanded(child: FittedBox(fit: BoxFit.contain, child: Icon(Icons.wifi_protected_setup, color: Colors.white))),
                        Expanded(child: FittedBox(fit: BoxFit.contain, child: Text("${(cubicVolume/fanExtract).toStringAsPrecision(2)} uur", style: TextStyle(color: Colors.white)))),
                        Expanded(child: FittedBox(fit: BoxFit.contain, child: Text("$powerConsumption W", style: TextStyle(color: Colors.white)))),
                      ])),
                    ]),
                    SizedBox(width: 400, height: 150, child:
                      TimeSeriesChart(fanData,
                          colorFn: (_, value) {
                            if (fanData[value].data > 200) return charts.MaterialPalette.red.shadeDefault;
                            else return charts.MaterialPalette.blue.shadeDefault;
                          },
                          areaColorFn: (_, __) => charts.MaterialPalette.transparent,
                      )
                    ),
                  ],
                ),
              )
            ),
          ),
        ],
      )
    );
  }
}
