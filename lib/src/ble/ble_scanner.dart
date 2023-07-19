// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:ble_scanner/src/ble/reactive_state.dart';
import 'package:meta/meta.dart';
import 'dart:math';
import '../mqtt/state/MQTTAppState.dart';
import '../mqtt/MQTTManager.dart';
import '../globals.dart' as globals;


class BleScanner implements ReactiveState<BleScannerState> {
  
  BleScanner({
    required FlutterReactiveBle ble,
    required Function(String message) logMessage,
  })  : _ble = ble,
        _logMessage = logMessage;
        
  Timer? timer;

  final FlutterReactiveBle _ble;
  final void Function(String message) _logMessage;
  final StreamController<BleScannerState> _stateStreamController =
      StreamController();

  final _devices = <DiscoveredDevice>[];

  @override
  Stream<BleScannerState> get state => _stateStreamController.stream;

  void startScan(List<Uuid> serviceIds) async {
    timer = Timer.periodic(Duration(milliseconds: 1000), (Timer t) => updateValue());
    _logMessage('Start ble discovery');
    _devices.clear();
    _pushState();
    _subscription =
      _ble.scanForDevices(withServices: serviceIds, scanMode: ScanMode.lowLatency).distinct().listen((device) {
            // print("Hello World\n\n");
        // print(device);
        // print("\n");
        // print("\n");
        final knownDeviceIndex = _devices.indexWhere((d) => d.id == device.id);
        if (knownDeviceIndex >= 0) {
          _devices[knownDeviceIndex] = device;
        } else {
          _devices.add(device);
        }
        _pushState();
      }, onError: (Object e) => _logMessage('Device scan fails with error: $e'));
    _pushState();
  }

  void updateValue(){
    List<bool> M102f = [false, false, false];
    List<bool> M103f = [false, false, false];
    List<bool> M104f = [false, false, false];
    List<bool> M202f = [false, false, false];
    List<bool> M203f = [false, false, false];
    List<bool> parkiranf = [false, false, false];
    globals.bleCount = 0;
    for(var device in _devices){
      var title = device.name;
      if((title == "M102" || title == "M103" || title == "M104" || title == "M202" || title == "M203" || title == "parkiran") && device.manufacturerData.length > 15){
        globals.bleCount++;
        // var major = (device.manufacturerData[20]<<8) + device.manufacturerData[21];
        var minor = (device.manufacturerData[22]<<8) + device.manufacturerData[23];
        // var txPower = device.manufacturerData[24] > 127 ? device.manufacturerData[24].toInt()-255 : device.manufacturerData[24];
        // var rssi = globals.kalman![((major-1)*3)+(minor-1)].filtered(device.rssi.toDouble());
        // var title = device.name + " (${minor})";
        // var jarak = rssiToDistance(rssi);

        if(title == "M102"){
          globals.M102.ble[minor-1] = device;
          // globals.M102.jarak[minor-1] = jarak;
          M102f[minor-1] = true;
        } 
        if(title == "M103"){
          globals.M103.ble[minor-1] = device; 
          // globals.M103.jarak[minor-1] = jarak;
          M103f[minor-1] = true;
        } 
        if(title == "M104"){
          globals.M104.ble[minor-1] = device; 
          // globals.M104.jarak[minor-1] = jarak;
          M104f[minor-1] = true;
        } 
        if(title == "M202"){
          globals.M202.ble[minor-1] = device;
          // globals.M202.jarak[minor-1] = jarak; 
          M202f[minor-1] = true;
        } 
        if(title == "M203"){
          globals.M203.ble[minor-1] = device; 
          // globals.M203.jarak[minor-1] = jarak;        
          M203f[minor-1] = true;
        } 
        if(title == "parkiran"){
          globals.parkiran.ble[minor-1] = device; 
          // globals.parkiran.jarak[minor-1] = jarak;
          parkiranf[minor-1] = true;
        } 
      }
    }
    for(var a=0; a<3; a++){
      if(M102f[a] == false) globals.M102.ble[a] = DiscoveredDevice(id: "0", name: "", serviceData: {}, manufacturerData: Uint8List(0), rssi: 0, serviceUuids: []);
      if(M103f[a] == false) globals.M103.ble[a] = DiscoveredDevice(id: "0", name: "", serviceData: {}, manufacturerData: Uint8List(0), rssi: 0, serviceUuids: []);
      if(M104f[a] == false) globals.M104.ble[a] = DiscoveredDevice(id: "0", name: "", serviceData: {}, manufacturerData: Uint8List(0), rssi: 0, serviceUuids: []);
      if(M202f[a] == false) globals.M202.ble[a] = DiscoveredDevice(id: "0", name: "", serviceData: {}, manufacturerData: Uint8List(0), rssi: 0, serviceUuids: []);
      if(M203f[a] == false) globals.M203.ble[a] = DiscoveredDevice(id: "0", name: "", serviceData: {}, manufacturerData: Uint8List(0), rssi: 0, serviceUuids: []);
      if(parkiranf[a] == false) globals.parkiran.ble[a] = DiscoveredDevice(id: "0", name: "", serviceData: {}, manufacturerData: Uint8List(0), rssi: 0, serviceUuids: []);
    }
    if(globals.bleCount == 0){
      globals.iteration++;
      if(globals.iteration >= 30){
        String msg = "nuid=${globals.user_nuid}";
        msg += "&password=${globals.user_pass}";
        msg += "&aksi=checkout";
        globals.TXmanager.publish(msg);
        globals.iteration = 0;
        _devices.clear();
        _pushState();
      }
      return;
    }
    else globals.iteration = 0;
    
    if(globals.bleCount > 0){      
      String msg = "nuid=${globals.user_nuid}";
      msg += "&password=${globals.user_pass}";
      msg += "&aksi=checkin";
      globals.TXmanager.publish(msg);
    }
    else{
      String msg = "nuid=${globals.user_nuid}";
      msg += "&password=${globals.user_pass}";
      msg += "&aksi=checkout";
      globals.TXmanager.publish(msg);
    }
    
    double terdekat = -100;
    globals.nama_terdekat = "null";      
    if(jarak_terdekat(globals.M102.ble) > terdekat){
      terdekat = jarak_terdekat(globals.M102.ble);
      globals.nama_terdekat = "M102";      
    }
    if(jarak_terdekat(globals.M103.ble) > terdekat){
      terdekat = jarak_terdekat(globals.M103.ble);
      globals.nama_terdekat = "M103";      
    }
    if(jarak_terdekat(globals.M104.ble) > terdekat){
      terdekat = jarak_terdekat(globals.M104.ble);
      globals.nama_terdekat = "M104";      
    }
    if(jarak_terdekat(globals.M202.ble) > terdekat){
      terdekat = jarak_terdekat(globals.M202.ble);
      globals.nama_terdekat = "M202";      
    }
    if(jarak_terdekat(globals.M203.ble) > terdekat){
      terdekat = jarak_terdekat(globals.M203.ble);
      globals.nama_terdekat = "M203";      
    }
    if(jarak_terdekat(globals.parkiran.ble) > terdekat){
      terdekat = jarak_terdekat(globals.parkiran.ble);
      globals.nama_terdekat = "parkiran";      
    }

    if(globals.nama_terdekat == "M102" || globals.nama_terdekat == "M103" || globals.nama_terdekat == "M104" || globals.nama_terdekat == "M202" || globals.nama_terdekat == "M203" || globals.nama_terdekat == "parkiran"){
      globals.coordinates koordinat = globals.coordinates(0, 0);
      if(globals.nama_terdekat == "M102") koordinat = trilateration(globals.M102);
      if(globals.nama_terdekat == "M103") koordinat = trilateration(globals.M103);
      if(globals.nama_terdekat == "M104") koordinat = trilateration(globals.M104);
      if(globals.nama_terdekat == "M202") koordinat = trilateration(globals.M202);
      if(globals.nama_terdekat == "M203") koordinat = trilateration(globals.M203);
      if(globals.nama_terdekat == "parkiran") koordinat = trilateration(globals.parkiran);
      String msg = "nuid=${globals.user_nuid}";
      msg += "&password=${globals.user_pass}";
      msg += "&ruang=${globals.nama_terdekat}";
      msg += "&x=${koordinat.x*10}";
      msg += "&y=${koordinat.y*10}";
      if(globals.nama_terdekat != "null"){
        globals.user_current_ruang = globals.nama_terdekat;
        globals.user_current_x = koordinat.x;
        globals.user_current_y = koordinat.y;
      }
      if(koordinat.x != 0 && koordinat.y != 0) globals.TXmanager.publish(msg);
    }
    _devices.clear();
    _pushState();
  }

  double jarak_terdekat(List<DiscoveredDevice> d){
    if(d.indexWhere((d) => d.rssi == 0) > 0) return -100;
    var terdekat = -100.00;
    for(var device in d){
      if(device.manufacturerData.length > 15){
        var major = (device.manufacturerData[20]<<8) + device.manufacturerData[21];
        var minor = (device.manufacturerData[22]<<8) + device.manufacturerData[23];
        var rssi = globals.kalman![((major-1)*3)+(minor-1)].filtered(device.rssi.toDouble());
        if(rssi > terdekat) terdekat = rssi;
      }
    }
    return terdekat;
  }

  globals.coordinates trilateration(globals.bleDevices d){
    globals.coordinates result;
    var count = 0;
    var x = 0.00;
    var y = 0.00;
    for(var data in d.ble){
      if(data.manufacturerData.length > 15){
        count++;
      }
    }
    var index = 0;
    for(var device in d.ble){  
      if(device.manufacturerData.length > 15){
        var major = (device.manufacturerData[20]<<8) + device.manufacturerData[21];
        var minor = (device.manufacturerData[22]<<8) + device.manufacturerData[23];
        var rssi = globals.kalman![((major-1)*3)+(minor-1)].filtered(device.rssi.toDouble());
        var jarak = globals.rssiToDistance(rssi);
        d.jarak[index] = jarak;
      }
      index++;   
    }

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

      x = ((e * c - b * f) / (a * e - b * d)).toDouble();
      y = ((a * f - d * c) / (a * e - b * d)).toDouble();
      result = globals.coordinates(x, y);
      
    }
    else result = globals.coordinates(0, 0);
    return result;
  }

  void _pushState() {
    _stateStreamController.add(
      BleScannerState(
        discoveredDevices: _devices,
        scanIsInProgress: _subscription != null,
      ),
    );
  }

  Future<void> stopScan() async {
    _logMessage('Stop ble discovery');

    await _subscription?.cancel();
    _subscription = null;
    _pushState();
  }

  Future<void> dispose() async {
    await _stateStreamController.close();
  }

  StreamSubscription? _subscription;
}

@immutable
class BleScannerState {
  const BleScannerState({
    required this.discoveredDevices,
    required this.scanIsInProgress,
  });

  final List<DiscoveredDevice> discoveredDevices;
  final bool scanIsInProgress;
}
