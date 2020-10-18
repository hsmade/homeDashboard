import 'package:flutter/material.dart';
import 'mqtt.dart';
import 'package:logging/logging.dart';
import 'TimeSeriesChart.dart';
import 'tile.dart';


class PowerUsageTile extends StatefulWidget {
  final MqttClient myMqtt;
  const PowerUsageTile (this.myMqtt): super();
  @override
  _PowerUsageTileState createState() => _PowerUsageTileState();
}

class _PowerUsageTileState extends State<PowerUsageTile> {
  var log = Logger('myapp.powerUsage_tile.dart');
  List<TimeSeriesData> data;

  List<TimeSeriesData> _emptyData(int count) {
    List<TimeSeriesData> newList = new List<TimeSeriesData>();
    for (var i=0;i<count; i++) {
      newList.add(new TimeSeriesData(DateTime.now(), 0));
    }
    return newList;
  }

  _newUsage(String message) {
    TimeSeriesData current = new TimeSeriesData(new DateTime.now(), double.parse(message));
    List<TimeSeriesData> newList = new List<TimeSeriesData>.from(data);
    newList.insert(0, current);
    newList.removeLast();
    setState(() {
     this.data = newList;
    });
  }

  @override
  void initState() {
    data = _emptyData(10);
    widget.myMqtt.subscribe("/power/current", (String message){
      log.info("parsing message: $message");
      _newUsage(message);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10.0),
      color: Colors.grey[900],
      child: _content(),
    );
  }

  Widget _content() {
    return Tile("Stroom", new TimeSeriesChart(data, legendaY: "Watt"));
  }
}
