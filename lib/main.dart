// ignore_for_file: use_build_context_synchronously

import 'package:ble_scanner/src/ui/loginPage.dart';
import 'package:ble_scanner/src/ui/menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:ble_scanner/src/ble/ble_device_connector.dart';
import 'package:ble_scanner/src/ble/ble_device_interactor.dart';
import 'package:ble_scanner/src/ble/ble_scanner.dart';
import 'package:ble_scanner/src/ble/ble_status_monitor.dart';
import 'package:ble_scanner/src/ui/ble_status_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import './src/mqtt/MQTTManager.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' show jsonDecode;
import 'package:rflutter_alert/rflutter_alert.dart';

import 'src/globals.dart' as globals;
import 'src/ble/ble_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeColor = globals.themeColor;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final _ble = FlutterReactiveBle();
  final _bleLogger = BleLogger(ble: _ble);
  final _scanner = BleScanner(ble: _ble, logMessage: _bleLogger.addToLog);
  final _monitor = BleStatusMonitor(_ble);
  final _connector = BleDeviceConnector(
    ble: _ble,
    logMessage: _bleLogger.addToLog,
  );
  final _serviceDiscoverer = BleDeviceInteractor(
    bleDiscoverServices: _ble.discoverServices,
    readCharacteristic: _ble.readCharacteristic,
    writeWithResponse: _ble.writeCharacteristicWithResponse,
    writeWithOutResponse: _ble.writeCharacteristicWithoutResponse,
    subscribeToCharacteristic: _ble.subscribeToCharacteristic,
    logMessage: _bleLogger.addToLog,
  );
  
  globals.TXmanager = MQTTManager(
        host: globals.mqtt_host,
        topic: "tx",
        identifier: "Android",);
        // state: currentAppState);
  globals.TXmanager.initializeMQTTClient();
  globals.TXmanager.connect();
  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: _scanner),
        Provider.value(value: _monitor),
        Provider.value(value: _connector),
        Provider.value(value: _serviceDiscoverer),
        Provider.value(value: _bleLogger),
        StreamProvider<BleScannerState?>(
          create: (_) => _scanner.state,
          initialData: const BleScannerState(
            discoveredDevices: [],
            scanIsInProgress: false,
          ),
        ),
        StreamProvider<BleStatus?>(
          create: (_) => _monitor.state,
          initialData: BleStatus.unknown,
        ),
        StreamProvider<ConnectionStateUpdate>(
          create: (_) => _connector.state,
          initialData: const ConnectionStateUpdate(
            deviceId: 'Unknown device',
            connectionState: DeviceConnectionState.disconnected,
            failure: null,
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Reactive BLE example',
        color: _themeColor,
        theme: ThemeData(primarySwatch: _themeColor),
        home: Phoenix(
          child: const HomeScreen(),
        ),
      ),
    )
  );
}



// class HomeScreen extends StatelessWidget {
//   const HomeScreen({
//     Key? key,
//   }) : super(key: key);
  
//   @override
//   Widget build(BuildContext context) => Consumer<BleStatus?>(
//     builder: (_, status, __) {
//       return status == BleStatus.ready ? (globals.isLoggedIn ? Menu() : LoginPage()) : BleStatusScreen(status: status ?? BleStatus.unknown);
//     },
//   );
// }


class HomeScreen extends StatefulWidget {
  const HomeScreen({
    Key? key,
  }) : super(key: key);
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<HomeScreen> {
  TextEditingController nameController = TextEditingController();
  @override
  void initState() {
    super.initState();
    autoLogIn();
  }

  void autoLogIn() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? username = prefs.getString('user_username');
    final String? password = prefs.getString('user_password');

    if (username != null && password != null) {
      setState(() {
        globals.loadingAutologin = true;
      });

      var url = Uri.parse(globals.endpoint_karyawan_get);
      final response = await http.post(url, body: {'username': username});
      // context.loaderOverlay.hide();

      if (response.statusCode == 200) {
        Map<String, dynamic> parsed = jsonDecode(response.body);
        if(parsed['password'] != password){          
          await prefs.remove('user_username');
          await prefs.remove('user_password');
          setState(() {
            globals.isLoggedIn = false;
          });
          Alert(
            context: context,
            type: AlertType.info,
            title: "Login Failed!",
            desc: "Please relogin",
            buttons: [
              DialogButton(
                child: Text(
                  "OK",
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Phoenix.rebirth(context);
                }
              )
            ],
          ).show();
        }
        else{
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_nuid', (parsed['nuid']).toString());
          await prefs.setString('user_username', parsed['username']);
          await prefs.setString('user_password', parsed['password']);
          setState(() {
            globals.isLoggedIn = true;
            globals.user_nuid = parsed['nuid'];
            globals.user_name = parsed['name'];
            globals.user_email = parsed['email'];
            globals.user_username = parsed['username'];
            globals.user_pass = parsed['password'];
            if(parsed['currentLocation'] != null){
              globals.user_current_ruang = parsed['currentLocation']['ruang'];
              globals.user_current_x = double.parse(parsed['currentLocation']['x']);
              globals.user_current_y = double.parse(parsed['currentLocation']['y']);
            }
          });
        }
      }      
      else{
        await prefs.remove('user_username');
        await prefs.remove('user_password');
        setState(() {
          globals.isLoggedIn = false;
        });
        Alert(
          context: context,
          type: AlertType.info,
          title: "Login Failed!",
          desc: "Please relogin",
          buttons: [
            DialogButton(
              child: Text(
                "OK",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              onPressed: () => Navigator.pop(context),
            )
          ],
        ).show();
      }
      return;
    }
  }

  @override  
  Widget build(BuildContext context) => Consumer<BleStatus?>(
    builder: (_, status, __) {
      return status == BleStatus.ready ? (globals.isLoggedIn ? Menu() : LoginPage()) : BleStatusScreen(status: status ?? BleStatus.unknown);
    },
  );
}


