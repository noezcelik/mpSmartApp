import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:tektest_2/layout/textfiled.dart';
import 'package:tektest_2/layout/widgets.dart';

import 'constants/color.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<LinearFlowrate> chartValues = [];
  late List<String> availablePorts;
  String selectedPort = 'NONE';
  bool isPortConnected = false;
  bool isPumpOn = false;
  late ElevatedButton pumpButton;
  SerialPort serialPort = SerialPort('');

  //final SerialPort _serialPort = SerialPort("/dev/ttyUSB0");
  final TextEditingController _sensorFlowRateController =
      TextEditingController();

  late SimpleLineChart lineChart;
  final port = SerialPort('COM5');

  @override
  void initState() {
    super.initState();
    _initializePorts();

    lineChart = SimpleLineChart.withSampleData(chartValues);
  }

  Future<void> _initializePorts() async {
    availablePorts = SerialPort.availablePorts;
    setState(() {
      if (!availablePorts.contains(selectedPort) || selectedPort == 'NONE') {
        selectedPort = 'NONE';
        isPortConnected = false;
        isPumpOn = false;
        //_updatePumpButton();
      } else if (!isPortConnected) {
        _connect();
      }
    });
  }

  Future<void> _connect() async {
    if (selectedPort != 'NONE' && !isPortConnected) {
      try {
        SerialPortConfig config = SerialPortConfig();
        config.baudRate = 9600;
        config.bits = 8;
        config.parity = SerialPortParity.none;
        config.stopBits = 1;
        config.setFlowControl(SerialPortFlowControl.none);

        // Kontrol etmek için bu noktada config.baudRate değerini yazdırın
        print("Baud Rate Before Opening: ${config.baudRate}");

        serialPort = SerialPort(selectedPort);
        serialPort.openReadWrite();

        print("Default BAutRat ${config.baudRate}");
        print("Default Bits ${config.bits}");
        print("Default stopBits ${config.stopBits}");
        print("Default BaudRate ${config.baudRate}");

        isPortConnected = true;
        //_updatePumpButton();
        print(selectedPort);
        _startTimer();
      } catch (error) {
        print("Fehler beim Verbinden mit dem Port: $error");
        _disconnect();
        isPortConnected = false;
        //_updatePumpButton();
      }
    }
  }

  void _onButtonPressed() {
    _sendCommand(!isPumpOn ? "r" : "p");

    isPumpOn = !isPumpOn;
  }

  void _startTimer() {
    if (isPortConnected) {
      Timer.periodic(const Duration(seconds: 1), (timer) {
        var read = serialPort.read(1);

        print(read);
        if (read.isNotEmpty) {
          int flowrateValue = read.first;
          LinearFlowrate dataPoint = LinearFlowrate(timer.tick, flowrateValue);
          lineChart.addDataPoint(dataPoint);

          // Update the sensor flow rate text field
          setState(() {
            _sensorFlowRateController.text = flowrateValue.toString();
          });

          setState(() {
            lineChart = SimpleLineChart.withSampleData(chartValues);
          });
        }
      });
    }
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

    _startTimer();
  }

  Future<void> setFlowRate() async {
    try {
      if (_sensorFlowRateController.text.isNotEmpty) {
        final int flowRate = int.parse(_sensorFlowRateController.text);
        final Uint8List command = Uint8List.fromList([115, flowRate]);
        serialPort.write(command);
        print("Command sent: $command");

        print(
            "Before Update: _sensorFlowRateController.text = ${_sensorFlowRateController.text}");

        // Update on the main thread
        setState(() {
          _sensorFlowRateController.text = flowRate.toString();
        });

        print(
            "After Update: _sensorFlowRateController.text = ${_sensorFlowRateController.text}");
      }
    } catch (e) {
      print("Error sending command: $e");
    }
  }

  void _disconnect() {
    if (isPortConnected) {
      serialPort.close();
      isPortConnected = false;
      isPumpOn = false;
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
                                      : HexColor(bcon),
                                  child: DropdownButton<String>(
                                    value: selectedPort,
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        selectedPort = newValue!;
                                        _initializePorts();
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
                                  isPortConnected && selectedPort != 'NONE'
                                      ? () {
                                          setState(() {
                                            _onButtonPressed();
                                          });
                                        }
                                      : null,
                              style: ElevatedButton.styleFrom(
                                disabledBackgroundColor: HexColor(bcon),
                                backgroundColor: isPumpOn
                                    ? HexColor(hellgruen)
                                    : HexColor(bcon),
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
                          disabledBackgroundColor: HexColor(bcon),
                          backgroundColor:
                              isPrimeOn ? HexColor(hellgruen) : HexColor(bcon),
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
                            disabledBackgroundColor: HexColor(bcon),
                            backgroundColor: HexColor(bcon),
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
                            const ObscuredTextFieldSample(),
                            Text('µl/min', style: butonTextStyle(fontSize: 10)),
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
                              width: 75,
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
                                    fillColor: HexColor(bcon),
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
  final String Function(int)? getTitle;

  void addDataPoint(LinearFlowrate dataPoint) {
    seriesList[0].data.add(dataPoint);
  }

  SimpleLineChart(this.seriesList, {required this.animate, this.getTitle});

  factory SimpleLineChart.withSampleData(List<LinearFlowrate> data,
      {String Function(int)? getTitle}) {
    return SimpleLineChart(
      _createSampleData(data),
      animate: true,
      getTitle: getTitle,
    );
  }

  @override
  Widget build(BuildContext context) {
    return charts.LineChart(
      seriesList,
      animate: animate,
      behaviors: [
        charts.SeriesLegend(),
      ],
      domainAxis: charts.NumericAxisSpec(
        // Eğer getTitle fonksiyonu varsa, kullan
        tickProviderSpec: getTitle != null
            ? const charts.BasicNumericTickProviderSpec(
                desiredTickCount: 5, dataIsInWholeNumbers: true)
            : null,
      ),
      primaryMeasureAxis: const charts.NumericAxisSpec(
        tickProviderSpec:
            charts.BasicNumericTickProviderSpec(desiredTickCount: 5),
      ),
    );
  }

  static List<charts.Series<LinearFlowrate, int>> _createSampleData(
      List<LinearFlowrate> data) {
    return [
      charts.Series<LinearFlowrate, int>(
        id: 'Flowrate',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (LinearFlowrate flowrate, _) => flowrate.second,
        measureFn: (LinearFlowrate flowrate, _) => flowrate.eorflowrate,
        data: data,
      )
    ];
  }
}

class LinearFlowrate {
  final int second;
  final int eorflowrate;
  final String time;

  LinearFlowrate(this.second, this.eorflowrate) : time = _formatTime(second);

  static String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    seconds %= 60;
    int hours = minutes ~/ 60;
    minutes %= 60;
    return '${_formatTwoDigit(hours)}:${_formatTwoDigit(minutes)}:${_formatTwoDigit(seconds)}';
  }

  static String _formatTwoDigit(int number) {
    return number.toString().padLeft(2, '0');
  }
}
