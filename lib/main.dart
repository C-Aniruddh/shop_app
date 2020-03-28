import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'firebase/auth/phone_auth/get_phone.dart';
import 'package:flutter_firebase/screens/loginPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase/screens/homePage.dart';
import 'package:google_map_location_picker/generated/i18n.dart' as location_picker;

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: FirebaseAuth.instance.currentUser(),
        builder: (BuildContext context, AsyncSnapshot snapshot){
          if(snapshot.hasData){
            return MaterialApp(
              title: 'ShopApp',
              debugShowCheckedModeBanner: false,
              home: MyHomePage(),
              theme: ThemeData(
                brightness: Brightness.dark,
                primaryColor: Colors.grey[900],
                accentColor: Colors.cyan[400],
                highlightColor: Colors.cyan[100],
                splashColor: Colors.cyan[900],
                textTheme: TextTheme(
                  headline: TextStyle(fontSize: 24.0,),
                  title: TextStyle(fontSize: 18.0,),
                  body1: TextStyle(fontSize: 14.0,),
                ),
              ),
              routes: <String, WidgetBuilder>{
                "/home": (_) => MyHomePage(),
                "/login": (_) => LoginPage(),
              },
            );
          }
          return MaterialApp(
            title: 'ShopApp',
            debugShowCheckedModeBanner: false,
            home: LoginPage(),
            theme: ThemeData(
              brightness: Brightness.dark,
              primaryColor: Colors.grey[900],
              accentColor: Colors.cyan[400],
              highlightColor: Colors.cyan[100],
              splashColor: Colors.cyan[900],
              textTheme: TextTheme(
                headline: TextStyle(fontSize: 24.0,),
                title: TextStyle(fontSize: 18.0,),
                body1: TextStyle(fontSize: 14.0,),
              ),
            ),
            routes: <String, WidgetBuilder>{
              "/home": (_) => MyHomePage(),
              "/login": (_) => LoginPage(),
            },
          );
        }
    );
  }
}

