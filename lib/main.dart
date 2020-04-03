import 'package:flutter/material.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

import 'package:sms/sms.dart';
import 'package:toast/toast.dart';

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String result = "";
  Map data;
  List userData;

  void enviarSMS() {
    for (var i = 0; i < userData.length; i++) {
      if (userData[i]["ok"]) {

        SmsSender sender = new SmsSender();
        String msg = "${userData[i]["link"]}";

        if (msg.isNotEmpty && !msg[msg.length -1].contains('/') ) {
          msg = msg + '/';
        }
        
        SmsMessage message = new SmsMessage("+55" + userData[i]["telefone"], msg);
        message.onStateChanged.listen((state) {
          if (state == SmsMessageState.Sent) {
            print("SMS is sent!");
          } else if (state == SmsMessageState.Delivered) {
            print("SMS is delivered!");
            setState(() {
              userData[i]["send"] = true;
            });
          }
        });
        sender.sendSms(message);
      }
    }
    Toast.show("Mensagens enviada com sucesso!", context,
        duration: Toast.LENGTH_SHORT, gravity: Toast.BOTTOM);
  }

  Future _scanQR() async {
    try {
      String qrResult = await BarcodeScanner.scan();
      setState(() {
        result = qrResult;
        Toast.show(qrResult, context,
            duration: Toast.LENGTH_SHORT, gravity: Toast.BOTTOM);
        getData(qrResult);
      });
    } on PlatformException catch (ex) {
      if (ex.code == BarcodeScanner.CameraAccessDenied) {
        setState(() {
          result = "Desculpe, não tenho permissão para usar sua câmera. :/";
        });
      } else {
        setState(() {
          result = "Erro desconhecido :/ $ex";
        });
      }
    } on FormatException {
      setState(() {
        result = "Você voltou antes de terminar de scanear. /:";
      });
    } catch (ex) {
      setState(() {
        result = "Erro desconhecido :/ $ex";
      });
    }
  }

  Future getData(url) async {
    http.Response response = await http.get(url);
    data = json.decode(response.body);
    List itens = new List();

    for(int i=0 ; i < data['contatos'].length; i++) {
      data['contatos'][i]['ok'] = true;
      data['contatos'][i]['send'] = false;
    }
    setState(() {
      userData = data["contatos"];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Elysium SMS '),
        backgroundColor: Colors.blue,
        actions: <Widget>[ 
          IconButton(icon: Icon(Icons.send), onPressed: () {
            if (userData != null) {
              enviarSMS();
            }else {
              Toast.show("Não tem lista de contato!", context,
                    duration: Toast.LENGTH_SHORT, gravity: Toast.BOTTOM);
            }
          },)
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: RefreshIndicator(
              child: ListView.builder(
                padding: EdgeInsets.only(top: 10.0),
                itemCount: userData == null? 0 : userData.length,
                itemBuilder: buildItem
              ), 
              onRefresh: () async{
                await Future.delayed(Duration(seconds: 1));
                setState(() {
                  userData = null;
                });
                return null;
              }
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scanQR,
        tooltip: 'Increment',
        child: Icon(Icons.camera_alt),
      ),
    );
  }

  Widget buildItem(BuildContext context, int index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(userData[index]['nome']),
        value: userData[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(userData[index]["send"] ? Icons.check : Icons.send),
        ),
        onChanged: (c) {
          setState(() {
            userData[index]["ok"] = c;
            //_saveData();
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          /*_lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedPos = index;
          _toDoList.removeAt(index);
*/
          //_saveData();

          final snack = SnackBar(
            content: Text("Tarefa  removida!"),
            action: SnackBarAction(
                label: "Desfazer",
                onPressed: () {
                  setState(() {});
                }),
            duration: Duration(seconds: 2),
          );

          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }
}
