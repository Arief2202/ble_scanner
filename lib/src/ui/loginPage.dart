import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' show jsonDecode;
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:ble_scanner/src/globals.dart' as globals;

class LoginPage extends StatefulWidget {
  LoginPage({Key? key}) : super(key: key);
  @override
  LoginPageState createState() {
    return new LoginPageState();
  }
}

class LoginPageState extends State<LoginPage> {
  List<TextEditingController> _data = [TextEditingController(), TextEditingController()];
  List<bool> _error = [false, false, false, false];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          scrollDirection: Axis.vertical,
          children: <Widget>[
                        
            SizedBox(height: MediaQuery.of(context).size.height / 2 - 300),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 100),
              width: double.infinity,
              // height: MediaQuery.of(context).size.width / 10,
              child: Text("LOGIN", textAlign: TextAlign.center, style: TextStyle(color: globals.themeColor, fontSize: 35, fontWeight: FontWeight.bold))
            ),     
            SizedBox(height: 50),
            Container(
              //img1
              margin: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width / 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Username',
                      labelStyle: TextStyle(fontSize: 20),
                      errorText: _error[0] ? 'Value Can\'t Be Empty' : null,
                    ),
                    controller: _data[0],
                  )
                ],
              ),
            ),
            SizedBox(height: 50),
            Container(
              //img1
              margin: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width / 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Password',
                      labelStyle: TextStyle(fontSize: 20),
                      errorText: _error[1] ? 'Value Can\'t Be Empty' : null,
                    ),
                    controller: _data[1],
                  )
                ],
              ),
            ),
            SizedBox(height: 50),
            Container(
              margin: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width / 15),
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  _doLogin(context);
                },
                child: Text(
                  "Log in",
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ),            
          ],
        ),
      ),
    );
  }

  Future _doLogin(context) async {
    bool status = true;
    setState(() {
      for (int a = 0; a < 2; a++) {
        if (_data[a].text.isEmpty) {
          _error[a] = true;
          status = false;
        } else
          _error[a] = false;
      }
    });
    if (status) {
      String _username = _data[0].text;
      String _password = _data[1].text;
      var url = Uri.parse(globals.endpoint_karyawan_get);
      final response = await http.post(url, body: {'username': _username});
      // context.loaderOverlay.hide();

      if (response.statusCode == 200) {
        Map<String, dynamic> parsed = jsonDecode(response.body);
        if(parsed['password'] != _password){
          Alert(
            context: context,
            type: AlertType.info,
            title: "Login Failed!",
            desc: "Incorrect Username or Password!",
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
          Alert(
            context: context,
            type: AlertType.info,
            desc: "Login Success!",
            buttons: [
              DialogButton(
                  child: Text(
                    "OK",
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Phoenix.rebirth(context);
                  })
            ],
          ).show();
        }
      }      
      else{
        Alert(
            context: context,
            type: AlertType.info,
            title: "Login Failed!",
            desc: "Incorrect Username or Password!",
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
    }
  }
}