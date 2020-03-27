import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_firebase/data_models/countries.dart';
import 'package:flutter_firebase/firebase/auth/phone_auth/code.dart';
import 'package:flutter_firebase/utils/constants.dart';
import 'package:flutter_firebase/firebase/auth/phone_auth/code.dart' show FirebasePhoneAuth, phoneAuthState;
import 'package:flutter_firebase/utils/widgets.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:flutter_firebase/firebase/auth/phone_auth/get_phone.dart';
import 'package:flutter_firebase/firebase/auth/phone_auth/signUpShopkeeper.dart';
import 'package:flutter_firebase/firebase/auth/phone_auth/signUpUser.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_firebase/screens/homePage.dart';

/*
 *  PhoneAuthUI - this file contains whole ui and controllers of ui
 *  Background code will be in other class
 *  This code can be easily re-usable with any other service type, as UI part and background handling are completely from different sources
 *  code.dart - Class to control background processes in phone auth verification using Firebase
 */

// ignore: must_be_immutable
class LoginPage extends StatefulWidget {
  /*
   *  cardBackgroundColor & logo values will be passed to the constructor
   *  here we access these params in the _PhoneAuthState using "widget"
   */
  Color cardBackgroundColor = Color(0xFF6874C2);
  String logo = Assets.firebase;
  String appName = "ShopApp";

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  double _height, _width, _fixedPadding;


  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    //  Fetching height & width parameters from the MediaQuery
    //  _logoPadding will be a constant, scaling it according to device's size
    _height = MediaQuery.of(context).size.height;
    _width = MediaQuery.of(context).size.width;
    _fixedPadding = _height * 0.025;

    /*  Scaffold: Using a Scaffold widget as parent
     *  SafeArea: As a precaution - wrapping all child descendants in SafeArea, so that even notched phones won't loose data
     *  Center: As we are just having Card widget - making it to stay in Center would really look good
     *  SingleChildScrollView: There can be chances arising where
     */
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: _getBody(),
          ),
        ),
      ),
    );
  }

  /*
   *  Widget hierarchy ->
   *    Scaffold -> SafeArea -> Center -> SingleChildScrollView -> Card()
   *    Card -> FutureBuilder -> Column()
   */
  Widget _getBody() => Container(
    child: SizedBox(
      height: _height * 0.8,
      width: _width,

      /*
           * Fetching countries data from JSON file and storing them in a List of Country model:
           * ref:- List<Country> countries
           * Until the data is fetched, there will be CircularProgressIndicator showing, describing something is on it's way
           * (Previously there was a FutureBuilder rather that the below thing, which created unexpected exceptions and had to be removed)
           */
      child: _getColumnBody(),
    ),
  );

  Widget _getColumnBody() => Column(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      //  Logo: scaling to occupy 2 parts of 10 in the whole height of device
      Padding(
        padding: EdgeInsets.all(_fixedPadding),
        child: PhoneAuthWidgets.getLogo(
            logoPath: widget.logo, height: _height * 0.2),
      ),

      // AppName:
      Text("Shop App",
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.white,
              fontSize: 24.0,
              fontWeight: FontWeight.w700)),

      Divider(),
      SignInButtonBuilder(
        text: 'Sign in to existing account',
        icon: Icons.account_circle,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => PhoneAuthGetPhone()));
        },
        backgroundColor: Colors.blueGrey[700],
      ),
      SignInButtonBuilder(
        text: 'Sign up as shop owner',
        icon: Icons.shopping_cart,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpShopkeeper()));
        },
        backgroundColor: Colors.blueGrey[700],
      ),
      SignInButtonBuilder(
        text: 'Sign up as shopper',
        icon: Icons.account_circle,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpUser()));
        },
        backgroundColor: Colors.blueGrey[700],
      ),
      Divider(),

    ],
  );

}
