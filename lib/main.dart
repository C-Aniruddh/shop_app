import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_firebase/test_screen.dart';
import 'firebase/auth/phone_auth/get_phone.dart';
import 'package:flutter_firebase/screens/loginPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase/screens/homePage.dart';
import 'package:google_map_location_picker/generated/i18n.dart' as location_picker;


void main() => runApp(MyApp());


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(

      theme: ThemeData(brightness: Brightness.dark),
      home: MyHomePage(title: "ShopApp",),
      debugShowCheckedModeBanner: false,
      routes: {
        "/home": (_) => MyHomePage(title: "Home"),
        "/login": (_) => LoginPage(),
      },
    );
  }
}

enum States { Show, Hide }

StreamController loaderStream = StreamController<States>();

class StatelessStreamBuilder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        TestPage(),
        StreamBuilder<States>(
            initialData: States.Hide,
            stream: loaderStream.stream,
            builder: (BuildContext context, snapshot) {
              if (snapshot.hasData) {
                if (snapshot.data == States.Hide) {
                  return Container();
                } else {
                  return Stack(
                    overflow: Overflow.visible,
                    children: <Widget>[
                      ModalBarrier(
                        dismissible: false,
                        color: Colors.grey.withOpacity(0.4),
                      ),
                      Center(
                        child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            )),
                      )
                    ],
                  );
                }
              } else {
                return Container();
              }
            })
      ],
    );
  }
}
