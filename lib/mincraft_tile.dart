import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:http/http.dart' as http;

class MinecraftTile extends StatefulWidget {
  final String prometheusURL;
  const MinecraftTile (this.prometheusURL): super();
  @override
  _MinecraftTileState createState() => _MinecraftTileState();

}

class _MinecraftTileState extends State<MinecraftTile> {
  var log = Logger('myapp.minecraft_tile.dart');
  List<String> users;


  Future<List<String>> _get_prometheus_value(String metric) async {
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
    final users = await _get_prometheus_value('sum(mc_player_online) by (name) > 0');
    if (users.length == 0) {
      users.add("- -");
    }

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

    return
      Container(
          margin: const EdgeInsets.all(10.0),
          color:Colors.grey[900],
          width: 100.0,
          height: 100.0,
          child:
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
                            "Minecraft",
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
                          child: Text(users.join("\n"), style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

      );
  }
}
