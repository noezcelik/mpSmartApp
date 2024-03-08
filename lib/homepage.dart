import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:charts_flutter/flutter.dart' as charts;
//import 'package:flutter_libserialport/flutter_libserialport.dart';
//import 'package:cr_flutter_libserialport/cr_flutter_libserialport.dart';
//import 'package:crlibserialport/crlibserialport.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:libserialport/libserialport.dart';
import 'package:tektest_2/layout/widgets.dart';

import 'constants/color.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  List<LinearFlowrate> chartValues = [];
  late List<String> availablePorts;
  String selectedPort = 'NONE';
  bool isPortConnected = false;
  bool isPumpOn = false;
  late ElevatedButton pumpButton;
  SerialPort serialPort = SerialPort('');

  static const maxDataPoints = 7;

  final TextEditingController _sensorFlowRateController =
      TextEditingController();

  final TextEditingController _targetController = TextEditingController();

  late SimpleLineChart lineChart;

  @override
  void initState() {
    super.initState();
    _initializePorts();
    setState(() {
      lineChart = SimpleLineChart.withSampleData(chartValues);
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.inactive) {
      _disconnect();
    }
  }

  Future<void> _initializePorts() async {
    availablePorts = SerialPort.availablePorts;
    setState(() {
      if (!availablePorts.contains(selectedPort) || selectedPort == 'NONE') {
        _disconnect();
        selectedPort = 'NONE';
        isPortConnected = false;
        isPumpOn = false;
        chartValues.clear();
        lineChart = SimpleLineChart.withSampleData(chartValues);
      } else if (!isPortConnected) {
        _connect();
      }
    });
  }

  Future<void> _connect() async {
    if (selectedPort != 'NONE' && !isPortConnected) {
      try {
        SerialPortConfig config = SerialPortConfig();

        print("Baud Rate Before Opening: ${config.baudRate}");

        serialPort = SerialPort(selectedPort);
        serialPort.openReadWrite();
        config.baudRate = 9600;
        config.bits = 8;
        config.parity = SerialPortParity.none;
        config.stopBits = 1;
        //config.setFlowControl(SerialPortFlowControl.none);

        serialPort.config = config;

        print("Default BautRat ${config.baudRate}");
        // print("Default Bits ${config.bits}");
        // print("Default stopBits ${config.stopBits}");

        isPortConnected = true;
        print(selectedPort);
      } catch (error) {
        print("Fehler beim Verbinden mit dem Port: $error");
        _disconnect();
        isPortConnected = false;
        isPumpOn = false;
      }
    }
  }

  void _onButtonPressed() {
    _sendCommand(!isPumpOn ? "r" : "p");
    setState(() {
      isPumpOn = !isPumpOn;
    });
  }

  void _startTimer() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isPortConnected) {
        timer.cancel();
      } else {
        List<int> buffer = [];
        var readData = serialPort.read(1024);
        buffer.addAll(readData);

        if (buffer.isNotEmpty) {
          String receivedData = utf8.decode(buffer);
          String cleanData = receivedData.trim();
          cleanData = cleanData.replaceAll(RegExp(r'[^0-9\.]'), '');
          int dotIndex = cleanData.indexOf('.');
          if (dotIndex != -1) {
            cleanData = cleanData.substring(0, dotIndex + 3);
          }
          double flowrateValue;
          try {
            flowrateValue = double.parse(cleanData);
          } catch (e) {
            print(" $e");
            flowrateValue = 0.0;
          }
          int roundedFlowrateValue = flowrateValue.round();
          LinearFlowrate dataPoint =
              LinearFlowrate(timer.tick, roundedFlowrateValue, DateTime.now());
          setState(() {
            chartValues.add(dataPoint);
            if (chartValues.length > maxDataPoints) {
              chartValues.removeAt(0);
            }
            for (var i = 0; i < chartValues.length; i++) {
              chartValues[i].index = i;
            }
            lineChart = SimpleLineChart.withSampleData(chartValues);
            _sensorFlowRateController.text = flowrateValue.toString();
          });
        }
      }
    });
  }

  void _sendCommand(String command) {
    if (isPortConnected) {
      try {
        List<int> data = utf8.encode(command);
        Uint8List byteData = Uint8List.fromList(data);
        print("Command $byteData gesendet");
        serialPort.write(byteData);
      } catch (error) {
        print("Fehler beim Senden des Befehls: $error");
      }
    } else {
      print("Kein Port verbunden");
    }
  }

  bool isPrimeOn = false;
  _primen() {
    _sendCommand(!isPumpOn && !isPrimeOn ? "a" : 'p');
  }

  Future<void> setFlowRate() async {
    if (!isPumpOn && !isPrimeOn) {
      return;
    }

    try {
      print(_targetController.text);

      final int flowRate = int.parse(_targetController.text);
      print('fl$flowRate');

      final Uint16List command = Uint16List.fromList([115, flowRate]);
      final Uint8List byteData =
          Uint8List.fromList(command.buffer.asUint8List());
      serialPort.write(byteData);

      print("Command sent: $command");

      print("Before Update: TargetController.text = ${_targetController.text}");

      // Update on the main thread
      setState(() {
        _targetController.text = flowRate.toString();
      });

      print("After Update TargetController.text = ${_targetController.text}");
    } catch (e) {
      print("Error sending command: $e");
    }
  }

  void _disconnect() {
    if (isPortConnected) {
      if (isPumpOn) {
        _onButtonPressed();
      }
      if (isPrimeOn) {
        _primen();
      }
      serialPort.close();
      setState(() {
        isPortConnected = false;
        isPumpOn = false;
        isPrimeOn = false;
        selectedPort = 'NONE';
      });
      print('disconnect');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: HexColor(bartelsblau),
        title: Row(
          children: [
            Image.asset(
              "assets/images/Bartels.png",
              height: 35,
              width: 35,
            ),
            const SizedBox(width: 15),
            Text(
              'mpSmart App',
              style: butonTextStyle(fontSize: 13),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.bottomRight,
                child: Image.asset(
                  "assets/images/signet_bartels.bmp",
                  height: 45,
                  width: 200,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Container(
              color: HexColor(bartelsblau),
              child: Row(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 15),
                    child: Column(
                      children: <Widget>[
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            GestureDetector(
                              onTap: () {
                                if (!isPortConnected) {
                                  _connect();
                                } else {
                                  _disconnect();
                                }
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(30.0),
                                child: Container(
                                  width: 109,
                                  height: 29,
                                  color: isPortConnected
                                      ? HexColor(hellgruen)
                                      : Colors.white,
                                  child: DropdownButton<String>(
                                    value: selectedPort,
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        selectedPort = newValue!;
                                        _initializePorts();
                                        _startTimer();
                                      });
                                    },
                                    style: const TextStyle(
                                      color: Colors.black,
                                    ),
                                    isExpanded: true,
                                    items: ['NONE', ...availablePorts]
                                        .map<DropdownMenuItem<String>>(
                                      (String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Center(
                                            child: Text(value),
                                          ),
                                        );
                                      },
                                    ).toList(),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed:
                                  (isPortConnected && selectedPort != 'NONE')
                                      ? _onButtonPressed
                                      : null,
                              style: ElevatedButton.styleFrom(
                                disabledBackgroundColor: Colors.white,
                                backgroundColor: isPumpOn
                                    ? HexColor(hellgruen)
                                    : Colors.white,
                                minimumSize: const Size(120, 40),
                              ),
                              child: Text(
                                isPumpOn ? "Pumpe an  " : "Pumpe aus",
                                style: butonTextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: <Widget>[
                      ElevatedButton(
                        onPressed: !isPumpOn && isPortConnected
                            ? () {
                                _primen();
                                setState(() {
                                  isPrimeOn = !isPrimeOn;
                                });
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          disabledBackgroundColor: Colors.white,
                          backgroundColor:
                              isPrimeOn ? HexColor(hellgruen) : Colors.white,
                          minimumSize: const Size(120, 40),
                        ),
                        child: Text(
                          'Prime',
                          style: butonTextStyle(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            disabledBackgroundColor: Colors.white,
                            backgroundColor: Colors.white,
                            minimumSize: const Size(100, 40),
                          ),
                          onPressed: isPortConnected
                              ? () async {
                                  await setFlowRate();
                                }
                              : null,
                          child: Text('Set Flowrate', style: butonTextStyle()),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Text(
                            'Target Flowrate',
                            style: butonTextStyle(),
                          ),
                        ),
                        Row(
                          children: [
                            SizedBox(
                              width: 90,
                              height: 29,
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20.0),
                                  border: Border.all(color: Colors.transparent),
                                  color: Colors.white,
                                ),
                                child: TextField(
                                  controller: _targetController,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 15,
                                      horizontal: 17,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 5),
                              child: Text('µl/min',
                                  style: butonTextStyle(fontSize: 10)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 16, 0, 3),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Text(
                            'Sensor Flowrate',
                            style: butonTextStyle(),
                            textAlign: TextAlign.start,
                          ),
                        ),
                        Row(
                          children: [
                            SizedBox(
                              width: 90,
                              height: 30,
                              child: TextField(
                                controller: _sensorFlowRateController,
                                enabled: false,
                                style: const TextStyle(color: Colors.black),
                                decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 7, horizontal: 25)),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 5),
                              child: Text('µl/min',
                                  style: butonTextStyle(fontSize: 10)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 15),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Center(
                    child: lineChart,
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

class SimpleLineChart extends StatelessWidget {
  final List<charts.Series<LinearFlowrate, int>> seriesList;
  final bool animate;

  const SimpleLineChart(this.seriesList, {required this.animate});

  factory SimpleLineChart.withSampleData(List<LinearFlowrate> data) {
    return SimpleLineChart(
      _createSampleData(data),
      animate: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return charts.LineChart(
      seriesList,
      animate: animate,
      animationDuration: const Duration(milliseconds: 900),
      behaviors: [
        charts.SeriesLegend(),
      ],
      domainAxis: const charts.NumericAxisSpec(
        showAxisLine: false,
        tickProviderSpec:
            charts.BasicNumericTickProviderSpec(desiredTickCount: 7),
        renderSpec: charts.SmallTickRendererSpec(
          labelStyle: charts.TextStyleSpec(fontSize: 13),
          labelRotation: 45,
          labelJustification: charts.TickLabelJustification.inside,
          minimumPaddingBetweenLabelsPx: 7,
          tickLengthPx: 0,
          lineStyle: charts.LineStyleSpec(thickness: 0),
          axisLineStyle: charts.LineStyleSpec(thickness: 0),
        ),
      ),
      primaryMeasureAxis: const charts.NumericAxisSpec(
        tickProviderSpec:
            charts.BasicNumericTickProviderSpec(desiredTickCount: 7),
      ),
    );
  }

  static List<charts.Series<LinearFlowrate, int>> _createSampleData(
      List<LinearFlowrate> data) {
    return [
      charts.Series<LinearFlowrate, int>(
        id: 'Flowrate',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (LinearFlowrate flowrate, _) => flowrate.index,
        measureFn: (LinearFlowrate flowrate, _) => flowrate.eorflowrate,
        data: data,
      )
    ];
  }
}

class LinearFlowrate {
  int index;
  final int eorflowrate;
  final DateTime dateTime;

  LinearFlowrate(this.index, this.eorflowrate, this.dateTime);

  static String formatTimeStamp(int seconds) {
    final int hours = seconds ~/ 3600;
    final int minutes = (seconds % 3600) ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${_formatTwoDigit(hours)}:${_formatTwoDigit(minutes)}:${_formatTwoDigit(remainingSeconds)}';
  }

  static String _formatTwoDigit(int number) {
    return number.toString().padLeft(2, '0');
  }
}
