import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class TimeSeriesChart extends StatelessWidget {
  final List<TimeSeriesData> data;
  final String legendaY;
  final charts.Color Function(TimeSeriesData, int) colorFn;

  TimeSeriesChart(this.data, {this.legendaY, this.colorFn});

  List<charts.Series<TimeSeriesData, DateTime>> createSeries(List<TimeSeriesData> data) {
    return [
      new charts.Series<TimeSeriesData, DateTime>(
        id: 'Data',
        colorFn: (colorFn==null)?(_, __) => charts.MaterialPalette.blue.shadeDefault:colorFn,
        domainFn: (TimeSeriesData point, _) => point.time,
        measureFn: (TimeSeriesData point, _) => point.data,
        data: data,
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    return new charts.TimeSeriesChart(
      createSeries(data),
      animate: false,
      defaultRenderer: new charts.LineRendererConfig<DateTime>(includeArea: true),
      defaultInteractions: false,
      behaviors: [
        new charts.ChartTitle(legendaY,
            behaviorPosition: charts.BehaviorPosition.start,
            titleOutsideJustification: charts.OutsideJustification.middleDrawArea),
      ],
        primaryMeasureAxis: new charts.NumericAxisSpec(
            renderSpec: charts.GridlineRendererSpec(
                lineStyle: charts.LineStyleSpec(
                  dashPattern: [4, 4],
                ))),
        domainAxis: new charts.DateTimeAxisSpec(
            tickFormatterSpec: new charts.AutoDateTimeTickFormatterSpec(
                day: new charts.TimeFormatterSpec(
                    format: 'd', transitionFormat: 'HH:mm:ss')))
    );
  }
}

/// Sample time series data type.
class TimeSeriesData {
  final DateTime time;
  final double data;

  TimeSeriesData(this.time, this.data);
}