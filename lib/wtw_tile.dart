import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:http/http.dart' as http;

class WtWTile extends StatefulWidget {
  final String prometheusURL;
  const WtWTile (this.prometheusURL): super();
  @override
  _WtWTileState createState() => _WtWTileState();

}

class _WtWTileState extends State<WtWTile> {
  var log = Logger('myapp.wtw_tile.dart');
  double tempExhaust;
  double tempExtract;
  double tempOutdoor;
  double tempSupply;
  double powerConsumption = 0;


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

  _updateValues() async {
    final exhaust = await _getPrometheusValue('comfoconnect_pdo_value{ID="275"} / 10');
    final extract = await _getPrometheusValue('comfoconnect_pdo_value{ID="274"} / 10');
    final outdoor = await _getPrometheusValue('comfoconnect_pdo_value{ID="220"} / 10');
    final supply = await _getPrometheusValue('comfoconnect_pdo_value{ID="221"} / 10');
    final powerConsumption = await _getPrometheusValue('comfoconnect_pdo_value{ID="128"}');

    setState(() {
      this.tempExhaust = double.parse(exhaust);
      this.tempExtract = double.parse(extract);
      this.tempOutdoor = double.parse(outdoor);
      this.tempSupply = double.parse(supply);
      this.powerConsumption = double.parse(powerConsumption);
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
    // _update_values();

    return
      Container(
        margin: const EdgeInsets.all(10.0),
        color:Colors.grey[900],
        width: 100.0,
        height: 100.0,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset('assets/wtw.png'),
            ),

            Column(
              children: [
                Expanded(
                  flex: 1,
                  child: Row(
                    children: [
                     Expanded(flex:5, child: FittedBox(fit: BoxFit.fill, child: Center(child: Text("$tempOutdoor°C", style: TextStyle(color: Colors.white))))),
                     Expanded(flex:1, child: FittedBox(fit: BoxFit.fill, child: Center(child: Text(" ", style: TextStyle(color: Colors.white))))),
                     Expanded(flex:5, child: FittedBox(fit: BoxFit.fill, child: Center(child: Text("$tempExhaust°C", style: TextStyle(color: Colors.white))))),
                    ],
                  ),
                ),

                Expanded(
                  flex: 4,
                    child: Text("")
                ),

                Expanded(
                  flex: 1,
                  child: Row(
                    children: [
                      Expanded(flex:5, child: FittedBox(fit: BoxFit.fill, child: Center(child: Text("$tempSupply°C", style: TextStyle(color: Colors.white))))),
                      Expanded(flex:5, child: FittedBox(fit: BoxFit.fill, child: Center(child: Text(" ${powerConsumption.round()}W ", style: TextStyle(color: Colors.white))))),
                      // Expanded(flex:1, child: FittedBox(fit: BoxFit.fill, child: Center(child: Text(" ", style: TextStyle(color: Colors.white))))),
                      Expanded(flex:5, child: FittedBox(fit: BoxFit.fill, child: Center(child: Text("$tempExtract°C", style: TextStyle(color: Colors.white))))),
                    ],
                  ),
                ),
              ],
            )
          ]
        )
      );
  }
}
