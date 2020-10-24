import 'package:flutter/cupertino.dart';
import 'package:logging/logging.dart';
import 'package:flutter/material.dart';
import 'mqtt.dart';
import 'package:numberpicker/numberpicker.dart';
import 'tile.dart';

class TemperatureTile extends StatefulWidget {
  final MqttClient myMqtt;
  const TemperatureTile (this.myMqtt): super();
  @override
  _TemperatureTileState createState() => _TemperatureTileState();

}

class _TemperatureTileState extends State<TemperatureTile> {
  var log = Logger('myapp.temperature_tile.dart');
  double temperature = -255;
  double setPoint = -255;
  bool heaterOn = false;
  List<double> setPoints = [for(var i=18.0; i<28.0; i+=0.5) i];

  _updateTemperature(String message) {
    log.info("Got temperature: $message");
    setState(() {
      this.temperature = double.parse(message);
    });
  }

  _updateHeater(String message) {
    log.info("Got heater: $message");
    setState(() {
      this.heaterOn = message == "ON";
    });
  }

  _updateSetpoint(String message) {
    log.info("Got setpoint: $message");
    setState(() {
      this.setPoint = double.parse(message);
    });
  }

  _setSetpoint(double value) {
    log.info("Set setpoint $value");
    if (setPoint > 0) {
      widget.myMqtt.publish("/env/cv/setpoint", value.toString(), true);
    }
  }

  @override
  void initState() {
    widget.myMqtt.subscribe("/env/woonkamer_sensor/temperature", (String message){
      log.info("parsing message: $message");
      _updateTemperature(message);
    });
    widget.myMqtt.subscribe("/env/cv/setpoint", (String message){
      log.info("parsing message: $message");
      _updateSetpoint(message);
    });
    widget.myMqtt.subscribe("/env/cv/heater", (String message){
      log.info("parsing message: $message");
      _updateHeater(message);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return
    Tile("Thermostaat",
      Column(
        children: [
          Expanded(
            flex: 3,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Center(
                  child: Text(
                    temperature==-255?"- -":temperature.toStringAsFixed(1) + '°C',
                    style: TextStyle(color: Colors.white),
                  )
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: new NumberPicker.integer(
              initialValue: setPoints.indexOf(setPoint), minValue: 0, maxValue: setPoints.length-1, onChanged: (index) => _setSetpoint(setPoints[index]),
              textMapper: (index) => setPoints[int.parse(index)].toString(),
            )
          ),
        ],
      )
    );
      Container(
        margin: const EdgeInsets.all(10.0),
        color: heaterOn?Colors.red[900]:Colors.grey[900],
        width: 100.0,
        height: 100.0,
        child: _content(),
      );
  }

  Widget _content() {
    return Column(
      children: [
        Expanded(
          child:
          FittedBox(
          fit: BoxFit.contain,
          child: Center(
              child: Text(
                "Thermostaat",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
        Expanded(
          child: FittedBox(
            fit: BoxFit.contain,
            child: Center(
                child: Text(
                  temperature==-255?"- -":temperature.toStringAsFixed(1) + '°C',
                  style: TextStyle(color: Colors.white),
                )
            ),
          ),
        ),

        new NumberPicker.integer(initialValue: setPoints.indexOf(setPoint), minValue: 0, maxValue: setPoints.length, onChanged: (index) => _setSetpoint(setPoints[index]),
        textMapper: (index) => setPoints[int.parse(index)].toString(),
        ),
      ],
    );
  }
}