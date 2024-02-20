// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/material.dart';
// import 'package:tektest_2/homepage.dart';

// class LineChartSample2 extends StatefulWidget {
//   final List<LinearFlowrate> data;
//   const LineChartSample2({super.key, required this.data});

//   @override
//   State<LineChartSample2> createState() => _LineChartSample2State();
// }

// class _LineChartSample2State extends State<LineChartSample2> {
//   List<Color> gradientColors = [Colors.blue, Colors.pink];

//   bool showAvg = false;

//   @override
//   Widget build(BuildContext context) {
//     print(widget.data);
//     return Stack(
//       children: <Widget>[
//         AspectRatio(
//           aspectRatio: 1.70,
//           child: Padding(
//             padding: const EdgeInsets.only(
//               right: 18,
//               left: 12,
//               top: 24,
//               bottom: 12,
//             ),
//             child: LineChart(
//               mainData(),
//             ),
//           ),
//         ),
//         SizedBox(
//           width: 60,
//           height: 34,
//           child: TextButton(
//             onPressed: () {
//               setState(() {
//                 showAvg = !showAvg;
//               });
//             },
//             child: Text(
//               'avg',
//               style: TextStyle(
//                 fontSize: 12,
//                 color: showAvg ? Colors.white.withOpacity(0.5) : Colors.white,
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget bottomTitleWidgets(double value) {
//     // Veri listesinden zamanı al
//     DateTime date = widget.data[value.toInt()].time;
//     String stringDate = "${date.hour}:${date.minute}:${date.second} ";
//     const style = TextStyle(
//       fontWeight: FontWeight.bold,
//       fontSize: 16,
//     );

//     return SizedBox(
//       width: 80, // Düğmenin genişliğini ayarlayabilirsiniz
//       child: RotatedBox(
//         quarterTurns:
//             0, // İsterseniz döndürme miktarını buradan ayarlayabilirsiniz
//         child: Text(
//           stringDate,
//           style: style,
//           textAlign: TextAlign.center,
//         ),
//       ),
//     );
//   }

//   Widget leftTitleWidgets(double value) {
//     const style = TextStyle(
//       fontWeight: FontWeight.bold,
//       fontSize: 15,
//     );
//     String text;
//     switch (value.toInt()) {
//       case 1:
//         text = '10K';
//         break;
//       case 3:
//         text = '30k';
//         break;
//       case 5:
//         text = '50k';
//         break;
//       default:
//         return Container();
//     }

//     return Text(text, style: style, textAlign: TextAlign.left);
//   }

//   LineChartData mainData() {
//     return LineChartData(
//       gridData: FlGridData(
//         show: true,
//         drawVerticalLine: true,
//         horizontalInterval: 1,
//         verticalInterval: 1,
//         getDrawingHorizontalLine: (value) {
//           return const FlLine(
//             color: Colors.amber,
//             strokeWidth: 1,
//           );
//         },
//         getDrawingVerticalLine: (value) {
//           return const FlLine(
//             color: Colors.cyan,
//             strokeWidth: 1,
//           );
//         },
//       ),
//       titlesData: FlGridData(
//         show: true,
//         rightTitles: const AxisTitles(
//           sideTitles: SideTitles(showTitles: false),
//         ),
//         topTitles: const AxisTitles(
//           sideTitles: SideTitles(showTitles: false),
//         ),
//         bottomTitles: AxisTitles(
//           sideTitles: SideTitles(
//             showTitles: true,
//             reservedSize: 30,
//             interval: 1,
//             getTitlesWidget: bottomTitleWidgets,
//           ),
//         ),
//         leftTitles: AxisTitles(
//           sideTitles: SideTitles(
//             showTitles: true,
//             interval: 1,
//             getTitlesWidget: leftTitleWidgets,
//             reservedSize: 42,
//           ),
//         ),
//       ),
//       borderData: FlBorderData(
//         show: true,
//         border: Border.all(color: const Color(0xff37434d)),
//       ),
//       minX: 0,
//       maxX: 6,
//       minY: 0,
//       maxY: 100,
//       lineBarsData: [
//         LineChartBarData(
//           spots: List.generate(
//               widget.data.length,
//               (index) => FlSpot(
//                   index.toDouble(), widget.data[index].flowrate.toDouble())),
//           isCurved: true,
//           gradient: LinearGradient(
//             colors: gradientColors,
//           ),
//           barWidth: 5,
//           isStrokeCapRound: true,
//           dotData: const FlDotData(
//             show: false,
//           ),
//           belowBarData: BarAreaData(
//             show: true,
//             gradient: LinearGradient(
//               colors: gradientColors
//                   .map((color) => color.withOpacity(0.3))
//                   .toList(),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// class LinearFlowrate {
//   final DateTime time;
//   final int flowrate;

//   LinearFlowrate(this.time, this.flowrate);
// }
