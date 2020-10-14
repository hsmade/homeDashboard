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
  double temp_exhaust;
  double temp_extract;
  double temp_outdoor;
  double temp_supply;


  Future<String> _get_prometheus_value(String metric) async {
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
    final exhaust = await _get_prometheus_value('comfoconnect_pdo_value{ID="275"} / 10');
    final extract = await _get_prometheus_value('comfoconnect_pdo_value{ID="274"} / 10');
    final outdoor = await _get_prometheus_value('comfoconnect_pdo_value{ID="220"} / 10');
    final supply = await _get_prometheus_value('comfoconnect_pdo_value{ID="221"} / 10');

    setState(() {
      this.temp_exhaust = double.parse(exhaust);
      this.temp_extract = double.parse(extract);
      this.temp_outdoor = double.parse(outdoor);
      this.temp_supply = double.parse(supply);
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
                     Expanded(flex:5, child: FittedBox(fit: BoxFit.fill, child: Center(child: Text("$temp_outdoor°C", style: TextStyle(color: Colors.white))))),
                     Expanded(flex:1, child: FittedBox(fit: BoxFit.fill, child: Center(child: Text(" ", style: TextStyle(color: Colors.white))))),
                     Expanded(flex:5, child: FittedBox(fit: BoxFit.fill, child: Center(child: Text("$temp_exhaust°C", style: TextStyle(color: Colors.white))))),
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
                      Expanded(flex:5, child: FittedBox(fit: BoxFit.fill, child: Center(child: Text("$temp_supply°C", style: TextStyle(color: Colors.white))))),
                      Expanded(flex:1, child: FittedBox(fit: BoxFit.fill, child: Center(child: Text(" ", style: TextStyle(color: Colors.white))))),
                      Expanded(flex:5, child: FittedBox(fit: BoxFit.fill, child: Center(child: Text("$temp_extract°C", style: TextStyle(color: Colors.white))))),
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
