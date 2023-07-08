// ignore_for_file: non_constant_identifier_names, unused_import, prefer_interpolation_to_compose_strings

library globals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:simple_kalman/simple_kalman.dart';
import './mqtt/state/MQTTAppState.dart';
import './mqtt/MQTTManager.dart';

bool showParkir = true;

const themeColor = Colors.deepPurple;

String endpoint = "http://absensi.ppns.eepis.tech";

String endpoint_get_all = endpoint + "/location/get_all.php";
String endpoint_karyawan_get = endpoint + "/user/get.php";
String endpoint_list_karyawan_get_all = endpoint + "/user/get_all.php";
String endpoint_monitor_karyawan_get_all = endpoint + "/monitor_karyawan/get_all.php";
String endpoint_history_presensi_get_all = endpoint + "/history_presensi/get_all.php";
String endpoint_cek_absensi = endpoint + "/location/update.php";

String nama_terdekat = "";
String mqtt_host = "eepis.tech";
String mqtt_topic_transmitt = "tx";
String mqtt_topic_receive = "rx";

String user_nuid = "";
String user_name = "";
String user_username = "";
String user_email = "";
String user_pass = "";

String user_current_ruang = "";
double user_current_x = 0;
double user_current_y = 0;


bool isLoggedIn = false;
bool loadingAutologin = true;
late MQTTManager TXmanager;
late MQTTManager manager;
late MQTTAppState currentAppState;
String msg = "";

bleDevices nowLocation = bleDevices(
  "M102",
  [0, 0, 0],
  [coordinates(0, 8.8), coordinates(3.8, 0), coordinates(7.6, 8.8)],
  [
    DiscoveredDevice(id: "0", name: "", serviceData: {}, manufacturerData: Uint8List(0), rssi: 0, serviceUuids: []),
    DiscoveredDevice(id: "0", name: "", serviceData: {}, manufacturerData: Uint8List(0), rssi: 0, serviceUuids: []),
    DiscoveredDevice(id: "0", name: "", serviceData: {}, manufacturerData: Uint8List(0), rssi: 0, serviceUuids: []),
  ]
);

bleDevices M102 = bleDevices(
  "M102",
  [0, 0, 0],
  [coordinates(0, 8.8), coordinates(3.8, 0), coordinates(7.6, 8.8)],
  [
    DiscoveredDevice(id: "0", name: "", serviceData: {}, manufacturerData: Uint8List(0), rssi: 0, serviceUuids: []),
    DiscoveredDevice(id: "0", name: "", serviceData: {}, manufacturerData: Uint8List(0), rssi: 0, serviceUuids: []),
    DiscoveredDevice(id: "0", name: "", serviceData: {}, manufacturerData: Uint8List(0), rssi: 0, serviceUuids: []),
  ]
);
bleDevices M103 = bleDevices(
  "M103",
  [0, 0, 0],
  [coordinates(0, 8.8), coordinates(4.1, 0), coordinates(8.2, 8.8)],
  [
    DiscoveredDevice(id: "0", name: "", serviceData: {}, manufacturerData: Uint8List(0), rssi: 0, serviceUuids: []),
    DiscoveredDevice(id: "0", name: "", serviceData: {}, manufacturerData: Uint8List(0), rssi: 0, serviceUuids: []),
    DiscoveredDevice(id: "0", name: "", serviceData: {}, manufacturerData: Uint8List(0), rssi: 0, serviceUuids: []),
  ]
);
bleDevices M104 = bleDevices(
  "M104",
  [0, 0, 0],
  [coordinates(0, 8.8), coordinates(3.6, 0), coordinates(7.2, 8.8)],
  [
    DiscoveredDevice(id: "0", name: "", serviceData: {}, manufacturerData: Uint8List(0), rssi: 0, serviceUuids: []),
    DiscoveredDevice(id: "0", name: "", serviceData: {}, manufacturerData: Uint8List(0), rssi: 0, serviceUuids: []),
    DiscoveredDevice(id: "0", name: "", serviceData: {}, manufacturerData: Uint8List(0), rssi: 0, serviceUuids: []),
  ]
);
bleDevices M202 = bleDevices(
  "M202",
  [0, 0, 0],
  [coordinates(0, 8.8), coordinates(38, 0), coordinates(7.6, 8.8)],
  [
    DiscoveredDevice(id: "0", name: "", serviceData: {}, manufacturerData: Uint8List(0), rssi: 0, serviceUuids: []),
    DiscoveredDevice(id: "0", name: "", serviceData: {}, manufacturerData: Uint8List(0), rssi: 0, serviceUuids: []),
    DiscoveredDevice(id: "0", name: "", serviceData: {}, manufacturerData: Uint8List(0), rssi: 0, serviceUuids: []),
  ]
);
bleDevices M203 = bleDevices(
  "M203",
  [0, 0, 0],
  [coordinates(0, 8.8), coordinates(4.1, 0), coordinates(8.2, 8.8)],
  [
    DiscoveredDevice(id: "0", name: "", serviceData: {}, manufacturerData: Uint8List(0), rssi: 0, serviceUuids: []),
    DiscoveredDevice(id: "0", name: "", serviceData: {}, manufacturerData: Uint8List(0), rssi: 0, serviceUuids: []),
    DiscoveredDevice(id: "0", name: "", serviceData: {}, manufacturerData: Uint8List(0), rssi: 0, serviceUuids: []),
  ]
);
bleDevices parkiran = bleDevices(
  "parkiran",
  [0, 0, 0],
  [coordinates(0, 10.0), coordinates(15.0, 0), coordinates(30.0, 10.0)],
  [
    DiscoveredDevice(id: "0", name: "", serviceData: {}, manufacturerData: Uint8List(0), rssi: 0, serviceUuids: []),
    DiscoveredDevice(id: "0", name: "", serviceData: {}, manufacturerData: Uint8List(0), rssi: 0, serviceUuids: []),
    DiscoveredDevice(id: "0", name: "", serviceData: {}, manufacturerData: Uint8List(0), rssi: 0, serviceUuids: []),
  ]
);

List<SimpleKalman>? kalman = [
  SimpleKalman(errorMeasure: 256, errorEstimate: 150, q: 0.9),
  SimpleKalman(errorMeasure: 256, errorEstimate: 150, q: 0.9),
  SimpleKalman(errorMeasure: 256, errorEstimate: 150, q: 0.9),
  SimpleKalman(errorMeasure: 256, errorEstimate: 150, q: 0.9),
  SimpleKalman(errorMeasure: 256, errorEstimate: 150, q: 0.9),
  SimpleKalman(errorMeasure: 256, errorEstimate: 150, q: 0.9),
  SimpleKalman(errorMeasure: 256, errorEstimate: 150, q: 0.9),
  SimpleKalman(errorMeasure: 256, errorEstimate: 150, q: 0.9),
  SimpleKalman(errorMeasure: 256, errorEstimate: 150, q: 0.9),
  SimpleKalman(errorMeasure: 256, errorEstimate: 150, q: 0.9),
  SimpleKalman(errorMeasure: 256, errorEstimate: 150, q: 0.9),
  SimpleKalman(errorMeasure: 256, errorEstimate: 150, q: 0.9),
  SimpleKalman(errorMeasure: 256, errorEstimate: 150, q: 0.9),
  SimpleKalman(errorMeasure: 256, errorEstimate: 150, q: 0.9),
  SimpleKalman(errorMeasure: 256, errorEstimate: 150, q: 0.9),
  SimpleKalman(errorMeasure: 256, errorEstimate: 150, q: 0.9),
  SimpleKalman(errorMeasure: 256, errorEstimate: 150, q: 0.9),
  SimpleKalman(errorMeasure: 256, errorEstimate: 150, q: 0.9),
];

class bleDevices {
  String name;
  List<double>jarak;
  List<coordinates>blePos;
  List<DiscoveredDevice>ble;
  bleDevices(
    this.name,
    this.jarak,
    this.blePos,
    this.ble,
  );
}
class coordinates{
  double x;
  double y;
  coordinates(
    this.x,
    this.y
  );
}