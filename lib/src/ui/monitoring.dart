// ignore_for_file: curly_braces_in_flow_control_structures, prefer_const_constructors, sort_child_properties_last, unused_local_variable, unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:ble_scanner/src/globals.dart' as globals;
import 'package:rflutter_alert/rflutter_alert.dart';
import '../ble/ble_logger.dart';
import 'package:ble_scanner/src/ble/ble_scanner.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'dart:math';

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
  double x = 0, y = 0;
  @override
  void initState() {
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
                  child: 
                  (() {                    
                    if(globals.nama_terdekat == "M102") globals.nowLocation = globals.M102;
                    else if(globals.nama_terdekat == "M103") globals.nowLocation = globals.M103;
                    else if(globals.nama_terdekat == "M104") globals.nowLocation = globals.M104;
                    else if(globals.nama_terdekat == "M202") globals.nowLocation = globals.M202;
                    else if(globals.nama_terdekat == "M203") globals.nowLocation = globals.M203;
                    else if(globals.nama_terdekat == "parkiran") globals.nowLocation = globals.parkiran;
                    // else globals.nowLocation = 
                    //   globals.bleDevices(
                    //     "null",
                    //     [0, 0, 0],
                    //     [globals.coordinates(0, 0), globals.coordinates(3.8, 8.8), globals.coordinates(7.6, 0)],
                    //     [
                    //       DiscoveredDevice(id: "0", name: "", serviceData: {}, manufacturerData: Uint8List(0), rssi: 0, serviceUuids: []),
                    //       DiscoveredDevice(id: "0", name: "", serviceData: {}, manufacturerData: Uint8List(0), rssi: 0, serviceUuids: []),
                    //       DiscoveredDevice(id: "0", name: "", serviceData: {}, manufacturerData: Uint8List(0), rssi: 0, serviceUuids: []),
                    //     ]
                    //   );
                    // for(var data in globals.nowLocation.ble){
                    //   if(data.manufacturerData.length > 15){
                    //     count++;
                    //   }
                    // }
                    var index = 0;
                    for(var device in globals.nowLocation.ble){  
                      if(device.manufacturerData.length > 15){
                        var major = (device.manufacturerData[20]<<8) + device.manufacturerData[21];
                        var minor = (device.manufacturerData[22]<<8) + device.manufacturerData[23];
                        var rssi = globals.kalman![((major-1)*3)+(minor-1)].filtered(device.rssi.toDouble());
                        var jarak = globals.rssiToDistance(rssi);
                        globals.nowLocation.jarak[index] = jarak;
                      }
                      index++;   
                    }
                    
                    var rbd1 = globals.nowLocation.blePos[0];
                    var rbd2 = globals.nowLocation.blePos[1];
                    var rbd3 = globals.nowLocation.blePos[2];
                    var distance1 = globals.nowLocation.jarak[0];
                    var distance2 = globals.nowLocation.jarak[1];
                    var distance3 = globals.nowLocation.jarak[2];
                    // if(count == 3){
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
                    double g = (pow(distance2, 2) -
                                pow(distance3, 2) -
                                pow(rbd2.x, 2) +
                                pow(rbd3.x, 2) -
                                pow(rbd2.y, 2) +
                                pow(rbd3.y, 2)).toDouble();

                    x = (((e * c - b * g) / (a * e - b * d))*10).toDouble();
                    y = (((a * g - d * c) / (a * e - b * d))*10).toDouble();
                    
                    
                    return Text("Lokasi (${globals.nowLocation.name})\nX : ${f.format(x/10)}\nY : ${f.format(y/10)}");
              
                  }())
                ),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: Stack(
                children: <Widget>[                  
                  globals.showParkir ? Image.asset(width: mapWidth, 'assets/img/mp1.png') : Image.asset(width: mapWidth, 'assets/img/m1.png'),
                    globals.nama_terdekat[1] == '1' || globals.nama_terdekat == "parkiran" ? dots(globals.nowLocation.name, mapWidth, context) : SizedBox(),
                ]
              )
            ),
            SizedBox(height: 10),
            globals.showParkir ? Container() : Center(
              child: Stack(
                children: <Widget>[
                  globals.showParkir ? Image.asset(width: mapWidth, 'assets/img/mp2.png') : Image.asset(width: mapWidth, 'assets/img/m2.png'),
                  globals.nama_terdekat[1] == '2' ? dots(globals.nowLocation.name, mapWidth, context) : SizedBox(),
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
    print(globals.nowLocation.name);
    return Positioned(
      left: ((width / (totalWidth / x) + plusX)) - ((width / scaleCircle) / 2),
      top: ((width / (totalWidth / y) + plusY)) - ((width / scaleCircle) / 2),
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
