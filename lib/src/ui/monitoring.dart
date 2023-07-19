// ignore_for_file: curly_braces_in_flow_control_structures, prefer_const_constructors, sort_child_properties_last, unused_local_variable, unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:ble_scanner/src/globals.dart' as globals;
import 'package:rflutter_alert/rflutter_alert.dart';
import '../ble/ble_logger.dart';
import 'package:ble_scanner/src/ble/ble_scanner.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class MonitoringPage extends StatelessWidget {
  const MonitoringPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Consumer3<BleScanner, BleScannerState?, BleLogger>(
        builder: (_, bleScanner, bleScannerState, bleLogger, __) => MonitoringPageStateful(
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

class MonitoringPageStateful extends StatefulWidget {
  // const MonitoringPage({super.key});
  const MonitoringPageStateful({
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
  State<MonitoringPageStateful> createState() => MonitoringPageState();
}

class MonitoringPageState extends State<MonitoringPageStateful> {
  late UserLocation? userLocation;
  late TextEditingController _uuidController;
  globals.coordinates koordinat = globals.coordinates(0, 0);
  var f = NumberFormat("###0.0#", "en_US");

  @override
  void initState() {
    globals.nama_terdekat = "local";
    userLocation = UserLocation(nuid: "0", name: "", username: "", email: "", currentLocation: Location(x: "0", y: "0", ruang: " ", timestamp: " "));
    super.initState();
    _uuidController = TextEditingController()..addListener(() => setState(() {}));
    if (!widget.scannerState.scanIsInProgress && _isValidUuidInput()) _startScanning();
  }

  @override
  void dispose() {
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

  Widget build(BuildContext context) {
    double mapWidth = MediaQuery.of(context).size.width / 1.2;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => {
                  Navigator.pop(context),
                }),
        title: Text("Mapping Karyawan"),
      ),
      body: Center(
        child: ListView(
          scrollDirection: Axis.vertical,
          // mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(height: 20),
            Container(
              margin: EdgeInsets.only(left: 30, right: 30, top: 20),
              height: 90.0,
              width: 200.0,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.only(top: 15, left:15, right:15, bottom: 15),
                  child: Text("Lokasi (${globals.user_current_ruang})\nX : ${f.format(globals.user_current_x)}\nY : ${f.format(globals.user_current_y)}"),
                ),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: Stack(
                children: <Widget>[                  
                  globals.showParkir ? Image.asset(width: mapWidth, 'assets/img/mp1.png') : Image.asset(width: mapWidth, 'assets/img/m1.png'),
                    globals.nama_terdekat[1] == '1' || globals.nama_terdekat == "parkiran" ? dots(globals.user_current_ruang, mapWidth, context) : SizedBox(),
                ]
              )
            ),
            SizedBox(height: 10),
            globals.showParkir ? Container() : Center(
              child: Stack(
                children: <Widget>[
                  globals.showParkir ? Image.asset(width: mapWidth, 'assets/img/mp2.png') : Image.asset(width: mapWidth, 'assets/img/m2.png'),
                  globals.nama_terdekat[1] == '2' ? dots(globals.user_current_ruang, mapWidth, context) : SizedBox(),
                ]
              )
            ),
            SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
  
  Widget dots(String ruang, double width, BuildContext context) {
    var f = NumberFormat("###0.0#", "en_US");
    int totalWidth = 310; //map tanpa parkir
    if (globals.showParkir) totalWidth = 510; //map dengan parkir
    int plusX = 0;
    int plusY = (width / (totalWidth / 96)).toInt();
    double scaleCircle = 15;
    double scaleText = 20;
    if (ruang == "parkiran") {
      plusX = (width / (totalWidth / 310)).toInt();
      plusY = (width / (totalWidth / 84)).toInt();
    }
    if (ruang == "M103" || ruang == "M203") {
      plusX = (width / (totalWidth / 76)).toInt();
    } else if (ruang == "M104" || ruang == "M204") plusX = (width / (totalWidth / 158)).toInt();
    return Positioned(
      left: ((width / (totalWidth / (globals.user_current_x*10)) + plusX)) - ((width / scaleCircle) / 2),
      top: ((width / (totalWidth / (globals.user_current_y*10)) + plusY)) - ((width / scaleCircle) / 2),
      width: width / scaleCircle,
      height: width / scaleCircle,
      child: GestureDetector(
          onTap: () {
            Alert(
                context: context,
                desc: "NUID :\n${globals.user_nuid}\n\nName :\n${globals.user_name}\n\nUsername :\n${globals.user_username}\n\nEmail :\n${globals.user_email}\n\nLokasi (${globals.nama_terdekat})\nX : ${f.format(globals.user_current_x)}\nY : ${f.format(globals.user_current_y)}",
                buttons: [],
                style: AlertStyle(
                  descStyle: TextStyle(fontSize: 15),
                  descTextAlign: TextAlign.start,
                )).show();
          },
          child: CircleAvatar(
            backgroundColor: Color.fromARGB(200, 255, 0, 0),
            child: Text(globals.user_nuid, style: TextStyle(fontSize: width / scaleText)),
            foregroundImage: NetworkImage("enterImageUrl"),
          )),
    );
  }
}

class UserLocation {
  String nuid;
  String name;
  String username;
  String email;
  Location currentLocation;
  UserLocation({required this.nuid, required this.name, required this.username, required this.email, required this.currentLocation});
  factory UserLocation.fromJson(Map<String, dynamic> json) => UserLocation(
        nuid: json['nuid'],
        name: json['name'],
        username: json['username'],
        email: json['email'],
        currentLocation: Location.fromJson(json['currentLocation']),
      );
}

class Location {
  String x;
  String y;
  String ruang;
  String timestamp;
  Location({
    required this.x,
    required this.y,
    required this.ruang,
    required this.timestamp,
  });
  factory Location.fromJson(Map<String, dynamic> json) => Location(
        x: json['x'],
        y: json['y'],
        ruang: json['ruang'],
        timestamp: json['timestamp'],
      );
}
