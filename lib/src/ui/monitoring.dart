// ignore_for_file: curly_braces_in_flow_control_structures, prefer_const_constructors, sort_child_properties_last, unused_local_variable, unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:ble_scanner/src/globals.dart' as globals;
import 'package:http/http.dart' as http;
import 'package:rflutter_alert/rflutter_alert.dart';
import 'dart:convert' show jsonDecode;
import 'dart:async';
import '../ble/ble_logger.dart';
import 'package:ble_scanner/src/ble/ble_scanner.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';


class MonitoringPage extends StatelessWidget {
  const MonitoringPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      Consumer3<BleScanner, BleScannerState?, BleLogger>(
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
  Timer? timer;
  late List<UserLocation>? userLocation;
  late TextEditingController _uuidController;
  var f = NumberFormat("###0.0#", "en_US");

  @override
  void initState() {
    timer = Timer.periodic(Duration(milliseconds: 100), (Timer t) => updateValue());
    userLocation = [
      UserLocation(nuid: "0", name: "", username: "", email: "", currentLocation: Location(x: "0", y: "0", ruang: "M103", timestamp: "")),
    ];
    super.initState();
    _uuidController = TextEditingController()
      ..addListener(() => setState(() {}));
    if(!widget.scannerState.scanIsInProgress && _isValidUuidInput()) _startScanning();
  }

  @override
  void dispose() {
    timer?.cancel();
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

  void updateValue() async {
    var url = Uri.parse(globals.endpoint_get_all);
    var response = await http.get(url);
    if (response.statusCode == 200) {
      debugPrint(jsonDecode(response.body).toString());
      if (this.mounted) {
        setState(() {
          userLocation = List<UserLocation>.from((jsonDecode(response.body) as List).map((x) => UserLocation.fromJson(x)).where((content) => content.nuid != null));
        });
      }
    }
  }

  Widget build(BuildContext context) {
    double mapWidth = MediaQuery.of(context).size.width / 1.2;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => {
                  timer?.cancel(),
                  Navigator.pop(context),
                }),
        title: Text("Mapping Karyawan"),
      ),
      body: Center(
        child: ListView(
          scrollDirection: Axis.vertical,
          // mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(height: 50),
            Center(
              child: Stack(
                children: <Widget>[                  
                  globals.showParkir ? Image.asset(width: mapWidth, 'assets/img/mp1.png') : Image.asset(width: mapWidth, 'assets/img/m1.png'),
                  for (UserLocation user in userLocation!) user.currentLocation.ruang[1] == '1' || user.currentLocation.ruang == "parkiran" ? dots(user, user.currentLocation.x, user.currentLocation.y, user.currentLocation.ruang, mapWidth, context) : SizedBox(),
                ]
              )
            ),
            SizedBox(height: 10),
            Center(
              child: Stack(
                children: <Widget>[
                  globals.showParkir ? Image.asset(width: mapWidth, 'assets/img/mp2.png') : Image.asset(width: mapWidth, 'assets/img/m2.png'),
                  for (UserLocation user in userLocation!) user.currentLocation.ruang[1] == '2' ? dots(user, user.currentLocation.x, user.currentLocation.y, user.currentLocation.ruang, mapWidth, context) : SizedBox(),
                ]
              )
            ),
            SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}

// Widget printDots(List<UserLocation> data, int lantai, double width){
//   List<Widget> list = <Widget>[];
//   for(var i = 0; i < data.length; i++){
//     list.add(dots(data[0].nuid, data[0].currentLocation.x, data[0].currentLocation.y, data[0].currentLocation.ruang, width));
//   }
//   return Stack(
//                 // fit: StackFit.expand,
//                 children: <Widget>[
//                 ];
// }

Widget dots(UserLocation user, String xStr, String yStr, String ruang, double width, BuildContext context) {
  var f = NumberFormat("###0.0#", "en_US");
  double x = double.parse(xStr);
  double y = double.parse(yStr);
  int totalWidth = 310; //map tanpa parkir
  if(globals.showParkir) totalWidth = 610; //map dengan parkir
  int plusX = 0;
  int plusY = (width / (totalWidth / 96)).toInt();
  double scaleCircle = 25;
  double scaleText = 30;
  if (ruang == "parkiran") {
    plusX = (width / (totalWidth / 310)).toInt();
    plusY = (width / (totalWidth / 84)).toInt();
  }
  if (ruang == "M103" || ruang == "M203") {
    plusX = (width / (totalWidth / 76)).toInt();
  } else if (ruang == "M104" || ruang == "M204") plusX = (width / (totalWidth / 158)).toInt();
  return Positioned(
    left: ((width / (totalWidth / x) + plusX)) - ((width / scaleCircle) / 2),
    top: ((width / (totalWidth / y) + plusY)) - ((width / scaleCircle) / 2),
    width: width / scaleCircle,
    height: width / scaleCircle,
    child: GestureDetector(
      onTap: () {
        Alert(
          context: context,
          desc: "NUID :\n${user.nuid}\n\nName :\n${user.name}\n\nUsername :\n${user.username}\n\nEmail :\n${user.email}\n\nLokasi (${user.currentLocation.ruang})\nX : ${f.format(double.parse(user.currentLocation.x))}\nY : ${f.format(double.parse(user.currentLocation.y))}",
          buttons: [],
          style: AlertStyle(
            descStyle: TextStyle(fontSize: 15),
            descTextAlign: TextAlign.start,
          )
        ).show();
      },
      child:  CircleAvatar(
        backgroundColor: Color.fromARGB(200, 255, 0, 0),
        child: Text(user.nuid, style: TextStyle(fontSize: width / scaleText)),
        foregroundImage: NetworkImage("enterImageUrl"),
      )
    ),
  );
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
