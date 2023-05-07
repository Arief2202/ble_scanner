import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:ble_scanner/src/ble/ble_scanner.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import '../ble/ble_logger.dart';
import '../widgets.dart';
import 'device_detail/device_detail_screen.dart';

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
  late TextEditingController rssi1M;
  late TextEditingController calibrate;
  var f = NumberFormat("###0.00000#", "en_US");
  @override
  void initState() {
    super.initState();
    _uuidController = TextEditingController()
      ..addListener(() => setState(() {}));
    rssi1M = TextEditingController()
      ..addListener(() => setState(() {}));
    calibrate = TextEditingController()
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    widget.stopScan();
    _uuidController.dispose();
    rssi1M.dispose();
    calibrate.dispose();
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
    if(rssi1M.text.isEmpty){
      setState((){
        rssi1M.text = "-65";
      });
    }
    if(calibrate.text.isEmpty){
      setState((){
        calibrate.text = "2.4";
      });
    }
    widget.startScan(text.isEmpty ? [] : [Uuid.parse(_uuidController.text)]);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Scan for devices'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // const SizedBox(height: 16),
                  // const Text('Service UUID (2, 4, 16 bytes):'),
                  // TextField(
                  //   controller: _uuidController,
                  //   enabled: !widget.scannerState.scanIsInProgress,
                  //   decoration: InputDecoration(
                  //       errorText:
                  //           _uuidController.text.isEmpty || _isValidUuidInput()
                  //               ? null
                  //               : 'Invalid UUID format'),
                  //   autocorrect: false,
                  // ),
                  const SizedBox(height: 16),
                  const Text('RSSI At 1M :'),
                  TextField(
                    controller: rssi1M,
                    enabled: true,
                    decoration: InputDecoration(
                        errorText:
                            _uuidController.text.isEmpty || _isValidUuidInput()
                                ? null
                                : 'Invalid UUID format'),
                    autocorrect: false,
                  ),
                  const SizedBox(height: 16),
                  const Text('Calibration (allows value from 2 to 4) :'),
                  TextField(
                    controller: calibrate,
                    enabled: true,
                    decoration: InputDecoration(
                        errorText:
                            _uuidController.text.isEmpty || _isValidUuidInput()
                                ? null
                                : 'Invalid UUID format'),
                    autocorrect: false,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        child: const Text('Scan'),
                        onPressed: !widget.scannerState.scanIsInProgress &&
                                _isValidUuidInput()
                            ? _startScanning
                            : null,
                      ),
                      ElevatedButton(
                        child: const Text('Stop'),
                        onPressed: widget.scannerState.scanIsInProgress
                            ? widget.stopScan
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                children: [
                  SwitchListTile(
                    title: const Text("Verbose logging"),
                    value: widget.verboseLogging,
                    onChanged: (_) => setState(widget.toggleVerboseLogging),
                  ),
                  ListTile(
                    title: Text(
                      !widget.scannerState.scanIsInProgress
                          ? ''
                          : 'Tap a device to connect to it',
                    ),
                    trailing: (widget.scannerState.scanIsInProgress ||
                            widget.scannerState.discoveredDevices.isNotEmpty)
                        ? Text(
                            'count: ${widget.scannerState.discoveredDevices.length}',
                          )
                        : null,
                  ),
                  ...widget.scannerState.discoveredDevices
                      .map(
                        (device) => device.name == "ESP32" ? ListTile(
                          title: Text(device.name.isEmpty ? "(null)" : device.name),
                          subtitle: device.manufacturerData.length < 25 ? 
                          Text("${device.id}\nRSSI: ${device.rssi} dBm\nMajor : null\nMinor : null\nTX Power : null\nDistance: ${f.format(pow(10, ((double.parse(rssi1M.text))-(device.rssi))/10*double.parse(calibrate.text)))} Meters") :
                          Text("${device.id}\nRSSI: ${device.rssi} dBm\nMajor :${(device.manufacturerData[20]<<8) + device.manufacturerData[21]}\nMinor :${(device.manufacturerData[22]<<8) + device.manufacturerData[23]}\nTX Power : ${device.manufacturerData[24] > 127 ? device.manufacturerData[24].toInt()-255 : device.manufacturerData[24]} dBm\nDistance: ${f.format(pow(10, ((double.parse(rssi1M.text))-(device.rssi))/10*double.parse(calibrate.text)))} Meters"),
                          leading: const BluetoothIcon(),
                          onTap: () async {
                            widget.stopScan();
                            await Navigator.push<void>(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        DeviceDetailScreen(device: device)));
                          },
                        ) : ListTile(),
                      )
                      .toList(),
                ],
              ),
            ),
          ],
        ),
      );
}
