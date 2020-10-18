import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class TimeSeriesChart extends StatelessWidget {
  final List<TimeSeriesData> data;
  final String legendaY;

  TimeSeriesChart(this.data, {this.legendaY});

  List<charts.Series<TimeSeriesData, DateTime>> createSeries(List<TimeSeriesData> data) {
    return [
      new charts.Series<TimeSeriesData, DateTime>(
        id: 'Data',
        colorFn: (_, value) {
          if (data[value].data < 270) return charts.MaterialPalette.green.shadeDefault;
          if (data[value].data < 400) return charts.MaterialPalette.blue.shadeDefault;
          else return charts.MaterialPalette.red.shadeDefault;
          },
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