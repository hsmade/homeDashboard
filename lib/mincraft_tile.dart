import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:http/http.dart' as http;
import 'tile.dart';

class MinecraftTile extends StatefulWidget {
  final String prometheusURL;
  const MinecraftTile (this.prometheusURL): super();
  @override
  _MinecraftTileState createState() => _MinecraftTileState();

}

class _MinecraftTileState extends State<MinecraftTile> {
  var log = Logger('myapp.minecraft_tile.dart');
  List<String> users;


  Future<List<String>> _getPrometheusValue(String metric) async {
    final response = await http.get("${widget.prometheusURL}/api/v1/query?query=${Uri.encodeComponent(metric)}").whenComplete(() => {});
    if (response.statusCode == 200) {
      Map<String, dynamic> result = jsonDecode(response.body);
      log.info("Prometheus returned: $result");

      List<String> users = new List<String>();
      result['data']['result'].forEach((item) => {
        users.add(item['metric']['name'])
      });

      return users;
    } else {
      log.warning("Prometheus returned code ${response.statusCode} and body: ${response.body}");
      return null;
    }
  }

  _updateValues() async {
    final users = await _getPrometheusValue('sum(mc_player_online) by (name) > 0');

    setState(() {
      this.users = users;
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

    return Tile("Minecraft",
      FittedBox(
        fit: BoxFit.contain,
        child: Center(
          child: Text((users!=null && users.length>0)?users.join("\n"):"  ", style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
