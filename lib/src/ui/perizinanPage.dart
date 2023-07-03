// ignore_for_file: sort_child_properties_last, prefer_const_literals_to_create_immutables, prefer_const_constructors, avoid_print, use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:ble_scanner/src/globals.dart' as globals;
import 'package:http/http.dart' as http;
import 'dart:convert' show jsonDecode;
import 'dart:async';
import 'package:intl/intl.dart';

class PerizinanPage extends StatefulWidget
{
  @override
  PerizinanPageState createState() => PerizinanPageState();
}

class PerizinanPageState extends State<PerizinanPage>
{
  Timer? timer;
  late Absensi checkin;
  late Absensi checkout;
  TextEditingController checkinController = TextEditingController();
  TextEditingController checkoutController = TextEditingController();

  @override
  void initState() {
    timer = Timer.periodic(Duration(milliseconds: 100), (Timer t) => updateValue());
    checkin = Absensi(id: "", nuid: "", timestamp: "", aksi: "", pesan: "", color: "");
    checkout = Absensi(id: "", nuid: "", timestamp: "", aksi: "", pesan: "", color: "");
  }

  void updateValue() async{
    var url = Uri.parse(globals.endpoint_cek_absensi);
    final response = await http.post(url, body: {'nuid': globals.user_nuid, 'password': globals.user_pass, 'aksi': 'check'});
    if (response.statusCode == 200) {
        final data = jsonDecode(response.body);        
        if (this.mounted) {
          setState(() {
            checkin = Absensi(id: "", nuid: "", timestamp: "", aksi: "", pesan: "", color: "");
            checkout = Absensi(id: "", nuid: "", timestamp: "", aksi: "", pesan: "", color: "");            
          });
        }
        for(var dat in data['data']){
          if(dat['aksi'] == 'checkin'){
            if (this.mounted) {
              setState(() {checkin = Absensi(id: dat['id'], nuid: dat['nuid'], timestamp: dat['timestamp'], aksi: dat['aksi'], pesan: dat['pesan'], color: dat['color']);});
            }
          }
          else if(dat['aksi'] == 'checkout'){
            if (this.mounted) {
              setState(() {checkout = Absensi(id: dat['id'], nuid: dat['nuid'], timestamp: dat['timestamp'], aksi: dat['aksi'], pesan: dat['pesan'], color: dat['color']);});
            }
          }
        }    
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
  

  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => {
                    // timer?.cancel(),
                    Navigator.pop(context),
                  }),
          title: const Text("Perizinan"),
        ),
        body: Row(
          children: [
            Flexible(
              child: ListView(
                children: [
                  checkin.timestamp == "" ? showForm("Check-In") :  showData("Check-In", checkin),
                  checkout.timestamp == "" ? showForm("Check-Out") : showData("Check-Out", checkout),
                ],
              ),
            ),
          ],
        ),
      );
  }

  Widget showForm(String aksi){
    bool error = false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children:[
        Row(
          children: [            
            Padding(
              padding: EdgeInsets.only(left: 25.0, top:25.0),
              child: Text(
                aksi,
                style : TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w700
                )
              ),
            ),
          ],
        ),
        
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 25, vertical: 16),
          child: TextField(
            controller: aksi == "Check-In" ? checkinController : checkoutController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Masukkan alasan izin '+aksi,
              errorText: error ? 'Value Can\'t Be Empty' : null,
            ),
          ),
        ),
                  
        Padding(
          padding: EdgeInsets.only(right:25.0),
          child: ElevatedButton(
            child: Text(
              "Submit".toUpperCase(),
              style: TextStyle(fontSize: 14)
            ),
            style: ButtonStyle(
              foregroundColor: MaterialStateProperty.all<Color>(const Color.fromARGB(255, 255, 255, 255)),
              backgroundColor: MaterialStateProperty.all<Color>(globals.themeColor),
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                  side: BorderSide(color: globals.themeColor)
                )
              )
            ),
            onPressed: () async {
              setState(() {
                if(aksi == "Check-In"){
                  if(checkinController.text == null || checkinController.text == "") error = true;
                  else error = false;
                }
                else{
                  if(checkoutController.text == null || checkoutController.text == "") error = true;
                  else error = false;
                }          
              });
              if(error == false){
                var url = Uri.parse(globals.endpoint_cek_absensi);
                final response = await http.post(url, body: {'nuid': globals.user_nuid, 'password': globals.user_pass, 'aksi': '${aksi == "Check-In" ? 'checkin' : 'checkout'}', 'pesan': (aksi == "Check-In" ? checkinController.text : checkoutController.text)});
              }
            }
          )
        ),
      ]
    );
  }

  Widget showData(String aksi, Absensi absensi){
    DateTime time = DateTime.parse(absensi.timestamp);
    return Center(      
      child: Card(
        margin: new EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: Icon(
                Icons.check, 
                size: 50, 
                color: absensi.color == "black" ? Colors.green : Colors.red),
              title: Padding(
                        padding: EdgeInsets.only(bottom: 7.0, top:5.0),
                        child: Text(
                          aksi,
                          style : TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700
                          )
                        )
                      ),
              subtitle: Padding(
                        padding: EdgeInsets.only(bottom: 10.0),
                        child: Text('Tanggal : ${time.day.toString().padLeft(2,'0')}-${time.month.toString().padLeft(2,'0')}-${time.year.toString()}\nJam : ${time.hour.toString().padLeft(2,'0')}:${time.minute.toString().padLeft(2,'0')}:${time.second.toString()}\nCatatan : ${absensi.pesan}'),
                      ),
            ),
          ],
        ),
      ),
    );
  }

}

class Absensi {
  String id;
  String nuid;
  String timestamp;
  String aksi;
  String pesan;
  String color;

  Absensi({
    required this.id,
    required this.nuid,
    required this.timestamp,
    required this.aksi,
    required this.pesan,
    required this.color,
  });
}