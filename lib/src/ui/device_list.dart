import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:ble_scanner/src/ble/ble_scanner.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../globals.dart' as globals;
import '../ble/ble_logger.dart';
import '../widgets.dart';
// import 'device_detail/device_detail_screen.dart';

class DeviceListScreen extends StatelessWidget {
  const DeviceListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      Consumer3<BleScanner, BleScannerState?, BleLogger>(
        builder: (_, bleScanner, bleScannerState, bleLogger, __) => _DeviceList(
          scannerState: bleScannerState ??
              const BleScannerState(
                discoveredDevices: [],
                scanIsInProgress: false,
              ),
          startScan: bleScanner.startScan,
          stopScan: bleScanner.stopScan,
          toggleVerboseLogging: bleLogger.toggleVerboseLogging,
          verboseLogging: bleLogger.verboseLogging,
        ),
      );
}

class _DeviceList extends StatefulWidget {
  const _DeviceList({
    required this.scannerState,
    required this.startScan,
    required this.stopScan,
    required this.toggleVerboseLogging,
    required this.verboseLogging,
  });

  final BleScannerState scannerState;
  final void Function(List<Uuid>) startScan;
  final VoidCallback stopScan;
  final VoidCallback toggleVerboseLogging;
  final bool verboseLogging;

  @override
  _DeviceListState createState() => _DeviceListState();
}

class _DeviceListState extends State<_DeviceList> {

  late TextEditingController _uuidController;
  var f = NumberFormat("###0.0#", "en_US");
  @override
  void initState() {
    super.initState();
    _uuidController = TextEditingController()
      ..addListener(() => setState(() {}));
    if(!widget.scannerState.scanIsInProgress && _isValidUuidInput()) _startScanning();
  }

  @override
  void dispose() {
    widget.stopScan();
    _uuidController.dispose();
    super.dispose();
  }

  bool _isValidUuidInput() {
    final uuidText = _uuidController.text;
    if (uuidText.isEmpty) {
      return true;
    } else {
      try {
        Uuid.parse(uuidText);
        return true;
      } on Exception {
        return false;
      }
    }
  }

  void _startScanning() {
    final text = _uuidController.text;
    widget.startScan(text.isEmpty ? [] : [Uuid.parse(_uuidController.text)]);
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => {
                    // timer?.cancel(),
                    Navigator.pop(context),
                  }),
          title: const Text("Raw Scanned Data"),
        ),
        body: Column(
          children: [
            Flexible(
              child: ListView(
                children: [
                  Text(globals.nama_terdekat),
                  trilateration(globals.M102),
                  trilateration(globals.M103),
                  trilateration(globals.M104),
                  trilateration(globals.M202),
                  trilateration(globals.M203),
                  trilateration(globals.parkiran),
                  ...globals.M102.ble.asMap().entries.map((device) => list(device.value)).toList(),
                  ...globals.M103.ble.asMap().entries.map((device) => list(device.value)).toList(),
                  ...globals.M104.ble.asMap().entries.map((device) => list(device.value)).toList(),
                  ...globals.M202.ble.asMap().entries.map((device) => list(device.value)).toList(),
                  ...globals.M203.ble.asMap().entries.map((device) => list(device.value)).toList(),
                  ...globals.parkiran.ble.asMap().entries.map((device) => list(device.value)).toList(),
                ],
              ),
            ),
          ],
        ),
      );
  } 
  Widget trilateration(globals.bleDevices d){
    var count = 0;
    var title = "";
    var subtitle = "";
    var x = 0.00;
    var y = 0.00;
    for(var data in d.ble){
      if(data.manufacturerData.length > 15){
        title = data.name;
        count++;
      }
    }
    var index = 0;
    for(var device in d.ble){  
      if(device.manufacturerData.length > 15){
        var major = (device.manufacturerData[20]<<8) + device.manufacturerData[21];
        var minor = (device.manufacturerData[22]<<8) + device.manufacturerData[23];
        var txPower = device.manufacturerData[24] > 127 ? device.manufacturerData[24].toInt()-255 : device.manufacturerData[24];
        var rssi = globals.kalman![((major-1)*3)+(minor-1)].filtered(device.rssi.toDouble());
        var title = device.name + " (${minor})";
        var jarak = rssiToDistance(rssi);
        d.jarak[index] = jarak;
        subtitle += "Jarak ${minor.toString()} : ${f.format(jarak)}\n";
      }
      else subtitle += "Jarak ${index+1} : null\n";
      index++;   
    }

    // subtitle += "\n";
    var rbd1 = d.blePos[0];
    var rbd2 = d.blePos[1];
    var rbd3 = d.blePos[2];
    var distance1 = d.jarak[0];
    var distance2 = d.jarak[1];
    var distance3 = d.jarak[2];
    if(count == 3){
      double a = ((2 * rbd2.x) - (2 * rbd1.x)).toDouble();
      double b = ((2 * rbd2.y) - (2 * rbd1.y)).toDouble();
      double c = (pow(distance1, 2) -
                  pow(distance2, 2) -
                  pow(rbd1.x, 2) +
                  pow(rbd2.x, 2) -
                  pow(rbd1.y, 2) +
                  pow(rbd2.y, 2)).toDouble();
      double d = ((2 * rbd3.x) - (2 * rbd2.x)).toDouble();
      double e = ((2 * rbd3.y) - (2 * rbd2.y)).toDouble();
      double f = (pow(distance2, 2) -
                  pow(distance3, 2) -
                  pow(rbd2.x, 2) +
                  pow(rbd3.x, 2) -
                  pow(rbd2.y, 2) +
                  pow(rbd3.y, 2)).toDouble();

      x = (((e * c - b * f) / (a * e - b * d))*10).toDouble();
      y = (((a * f - d * c) / (a * e - b * d))*10).toDouble();

      print(a);

      // var coordinates = {'x': x, 'y': y};

    }
    count == 3 ? subtitle += "Trilateration : (X: ${f.format(x)}, Y: ${f.format(y)})" : subtitle += "Trilateration : Invalid";

    if(count > 0){
      return ListTile(
          title: Text(title),
          subtitle: Text(subtitle),
          leading: const trilaterationIcon(),
      );
    }
    else{
      return Container();
    }
  }

  Widget list(DiscoveredDevice device){
    if(device.manufacturerData.length < 15) return Container();

    var major = (device.manufacturerData[20]<<8) + device.manufacturerData[21];
    var minor = (device.manufacturerData[22]<<8) + device.manufacturerData[23];
    var txPower = device.manufacturerData[24] > 127 ? device.manufacturerData[24].toInt()-255 : device.manufacturerData[24];
    var rssi = globals.kalman![((major-1)*3)+(minor-1)].filtered(device.rssi.toDouble());
    var title = device.name + " (${minor})";
    var jarak = rssiToDistance(rssi);

    var subtitle = "${device.id}\nRSSI: ${f.format(rssi)} dBm\nMajor :${major}\nMinor :${minor}\nDistance: ${f.format(jarak)} Meters";

    return ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        leading: const BluetoothIcon(),
    );
  }

  double rssiToDistance(double rssi) {
    double distance;
    double referenceRssi = -50;
    double referenceDistance = 0.944;
    double pathLossExponent = 0.3;
    double flatFadingMitigation = 0;
    double rssiDiff = rssi - referenceRssi - flatFadingMitigation;

    double i =  pow(10, -(rssiDiff/ 10 * pathLossExponent)).toDouble();

    distance = referenceDistance * i;

    return distance;
  }

}
