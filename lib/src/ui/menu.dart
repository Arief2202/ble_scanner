// ignore_for_file: curly_braces_in_flow_control_structures, prefer_const_constructors, sort_child_properties_last, unused_local_variable, unused_import

import 'package:ble_scanner/src/ui/perizinanPage.dart';
import 'package:flutter/material.dart';
// import 'package:monitoring_karyawan_ppns/monitoring.dart';
// import 'package:monitoring_karyawan_ppns/absensi.dart';
// import 'package:monitoring_karyawan_ppns/history_presensi.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ble_scanner/src/globals.dart' as globals;
import 'package:ble_scanner/src/ui/monitoring.dart';
import 'package:ble_scanner/src/ui/device_list.dart';
import '../ble/ble_logger.dart';
import '../widgets.dart';
import 'package:ble_scanner/src/ble/ble_scanner.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';



class Menu extends StatelessWidget {
  const Menu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      Consumer3<BleScanner, BleScannerState?, BleLogger>(
        builder: (_, bleScanner, bleScannerState, bleLogger, __) => MenuStateful(
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

class MenuStateful extends StatefulWidget {
  const MenuStateful({
    super.key,
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
  State<MenuStateful> createState() => MenuState();
}

class MenuState extends State<MenuStateful> {
  late TextEditingController _uuidController;

  @override
  void initState() {
    super.initState();
    _uuidController = TextEditingController()
      ..addListener(() => setState(() {}));
    if(!widget.scannerState.scanIsInProgress && _isValidUuidInput()) _startScanning();
  }

  @override
  void dispose() {
    super.dispose();
    _uuidController.dispose();
    widget.stopScan();
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
  
  Widget build(BuildContext context) {
    double mapWidth = MediaQuery.of(context).size.width / 1.2;
    return Scaffold(
      appBar: AppBar(
        // leading: IconButton(
        //   icon: Icon(Icons.arrow_back),
        //   onPressed: () => Navigator.pop(context),
        // ),
        title: Text("Monitoring Karyawan"),
        actions: <Widget>[
          IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                Alert(
                  context: context,
                  type: AlertType.info,
                  desc: "Do you want to Logout ?",
                  buttons: [
                    DialogButton(
                        child: Text(
                          "No",
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        }),
                    DialogButton(
                        child: Text(
                          "Yes",
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.remove('user_username');
                          await prefs.remove('user_password');
                          globals.isLoggedIn = false;
                          // Navigator.pop(context);
                          Navigator.pop(context);
                          Phoenix.rebirth(context);
                        }),
                  ],
                ).show();
              })
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            height: 50.0,
            width: 300.0,
            child: ElevatedButton(
              child: Text("Raw Data"),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return DeviceListScreen();
                }));
              },
            ),
          ),

          Container(height: 20.0), //SizedBox(height: 20.0),

          Container(
            height: 50.0,
            width: 300.0,
            child: ElevatedButton(
              child: Text("Map Karyawan"),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return MonitoringPage();
                }));
              },
            ),
          ),
          Container(height: 20.0), //SizedBox(height: 20.0),

          Container(
            height: 50.0,
            width: 300.0,
            child: ElevatedButton(
              child: Text("Perizinan"),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return PerizinanPage();
                }));
              },
            ),
          ),

        ],
      ),
    );
  }
}
