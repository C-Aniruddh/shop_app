import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../data_models/countries.dart';
import '../../../utils/constants.dart';
import '../../../utils/widgets.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class PhoneAuthGetPhone  extends StatefulWidget {
  final Color cardBackgroundColor = Color(0xFF6874C2);
  final String logo = Assets.firebase;

  @override
  State<StatefulWidget> createState() => PhoneAuthGetPhoneState();
}

class PhoneAuthGetPhoneState extends State<PhoneAuthGetPhone> {
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _smsController = TextEditingController();
  bool otpSent = false;

  bool phoneFlag = true;
  String _verificationId;

  FocusNode focusNode1 = FocusNode();
  FocusNode focusNode2 = FocusNode();
  FocusNode focusNode3 = FocusNode();
  FocusNode focusNode4 = FocusNode();
  FocusNode focusNode5 = FocusNode();
  FocusNode focusNode6 = FocusNode();
  String code = "";

  double _height, _width, _fixedPadding;

  List<Country> countries = [];
  StreamController<List<Country>> _countriesStreamController;
  Sink<List<Country>> _countriesSink;

  TextEditingController _searchCountryController = TextEditingController();

  int _selectedCountryIndex = 0;

  bool _isCountriesDataFormed = false;

  @override
  void initState() {
    _countryController.text = "+";
    super.initState();
  }

  @override
  void dispose() {
    _smsController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  void _verifyPhoneNumber() async {
    final PhoneVerificationCompleted verificationCompleted =
        (AuthCredential phoneAuthCredential) async {
      //_auth.signInWithCredential(phoneAuthCredential);

      final FirebaseUser user =
          (await _auth.signInWithCredential(phoneAuthCredential)).user;
      final FirebaseUser currentUser = await _auth.currentUser();
      assert(user.uid == currentUser.uid);

      setState(() {
        if (user != null) {
          // sign in success
          print("_verifyPhoneNumber SUCCESS");
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
        } else {
          // sign in failed
          print("_verifyPhoneNumber FAILURE");
        }
      });
    };

    final PhoneVerificationFailed verificationFailed =
        (AuthException authException) {
      print('Phone number verification failed. Code: ${authException.code}. Message: ${authException.message}');
      setState(() {
        otpSent = false;
      });
      showDialog(
          context: context,
          builder: (context) {
            return
            AlertDialog(
              title: Text('We could not send an SMS to that number.'),
              content: Text('Are you sure you entered a valid mobile number? Please check the number again.'),
              actions: <Widget>[
                FlatButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('Ok', style: TextStyle(color: Color(0xFFF37256)),)
                ),
              ],
            );
          });
    };

    final PhoneCodeSent codeSent =
        (String verificationId, [int forceResendingToken]) async {
      print('Please check your phone for the verification code.');
      _verificationId = verificationId;
    };

    final PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout =
        (String verificationId) {
      _verificationId = verificationId;
    };

    await _auth.verifyPhoneNumber(
        phoneNumber: "+91" + _phoneNumberController.text,
        timeout: const Duration(seconds: 5),
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout);

    //await _signInWithPhoneNumber();
  }

  // Example code of how to sign in with phone.
  void _signInWithPhoneNumber() async {
    //pr.show();
    final AuthCredential credential = PhoneAuthProvider.getCredential(
      verificationId: _verificationId,
      smsCode: code,
    );
    final FirebaseUser user =
        (await _auth.signInWithCredential(credential)).user;
    final FirebaseUser currentUser = await _auth.currentUser();
    assert(user.uid == currentUser.uid);

    setState(() {
      if (user != null) {
        // sign in success
        print("_signInWithPhoneNumber SUCCESS");
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
      } else {
        // sign in failed
        print("_signInWithPhoneNumber FAILURE");
      }
    });
  }


  void selectThisCountry(Country country) {
    print(country);
    _searchCountryController.clear();
    Navigator.of(context).pop();
    Future.delayed(Duration(milliseconds: 10)).whenComplete(() {
      _countriesStreamController.close();
      _countriesSink.close();

      setState(() {
        _selectedCountryIndex = countries.indexOf(country);
      });
    });
  }

  Future<List<Country>> loadCountriesJson() async {
    //  Cleaning up the countries list before we put our data in it
    countries.clear();

    //  Fetching the json file, decoding it and storing each object as Country in countries(list)
    var value = await DefaultAssetBundle.of(context)
        .loadString("data/country_phone_codes.json");
    var countriesJson = json.decode(value);
    for (var country in countriesJson) {
      countries.add(Country.fromJson(country));
    }

    //Finally adding the initial data to the _countriesSink
    // _countriesSink.add(countries);
    return countries;
  }

  sendOTP() async {
    _verifyPhoneNumber();
    setState(() {
      otpSent = true;
    });
  }

  verifyOTP() async {
    _signInWithPhoneNumber();
    setState(() {
      otpSent = true;
    });
  }

  Widget getPinField({String key, FocusNode focusNode}) => SizedBox(
    height: 40.0,
    width: 35.0,
    child: TextField(
      key: Key(key),
      expands: false,
      autofocus: key.contains("1") ? true : false,
      focusNode: focusNode,
      onChanged: (String value) {
        if (value.length == 1) {
          code += value;
          switch (code.length) {
            case 1:
              FocusScope.of(context).requestFocus(focusNode2);
              break;
            case 2:
              FocusScope.of(context).requestFocus(focusNode3);
              break;
            case 3:
              FocusScope.of(context).requestFocus(focusNode4);
              break;
            case 4:
              FocusScope.of(context).requestFocus(focusNode5);
              break;
            case 5:
              FocusScope.of(context).requestFocus(focusNode6);
              break;
            default:
              FocusScope.of(context).requestFocus(FocusNode());
              break;
          }
        }
      },
      maxLengthEnforced: false,
      textAlign: TextAlign.center,
      cursorColor: Colors.white,
      keyboardType: TextInputType.number,
      style: TextStyle(
          fontSize: 20.0, fontWeight: FontWeight.w600, color: Colors.white),
    ),
  );

  @override
  Widget build(BuildContext context) {
    _height = MediaQuery.of(context).size.height;
    _width = MediaQuery.of(context).size.width;
    _fixedPadding = _height * 0.025;

    WidgetsBinding.instance.addPostFrameCallback((Duration d) {
      if (countries.length < 240) {
        loadCountriesJson().whenComplete(() {
          setState(() => _isCountriesDataFormed = true);
        });
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                //  Logo: scaling to occupy 2 parts of 10 in the whole height of device
                Padding(
                  padding: EdgeInsets.all(_fixedPadding),
                  child: PhoneAuthWidgets.getLogo(
                      logoPath: widget.logo, height: _height * 0.2),
                ),

                Text("Shop App",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24.0,
                        fontWeight: FontWeight.w700)),

                Visibility(
                  visible: !otpSent,
                  child: Column (
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(top: 10.0, left: _fixedPadding),
                        child: PhoneAuthWidgets.subTitle('Enter your phone'),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                            left: _fixedPadding,
                            right: _fixedPadding,
                            bottom: _fixedPadding),
                        child: PhoneAuthWidgets.phoneNumberField(_phoneNumberController,
                            countries[_selectedCountryIndex].dialCode),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          SizedBox(width: _fixedPadding),
                          Icon(Icons.info, color: Colors.white, size: 20.0),
                          SizedBox(width: 10.0),
                          Expanded(
                            child: RichText(
                                text: TextSpan(children: [
                                  TextSpan(
                                      text: 'We will send ',
                                      style: TextStyle(
                                          color: Colors.white, fontWeight: FontWeight.w400)),
                                  TextSpan(
                                      text: 'One Time Password',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.w700)),
                                  TextSpan(
                                      text: ' to this mobile number',
                                      style: TextStyle(
                                          color: Colors.white, fontWeight: FontWeight.w400)),
                                ])),
                          ),
                          SizedBox(width: _fixedPadding),
                        ],
                      ),

                      SizedBox(height: _fixedPadding * 1.5),
                      RaisedButton(
                        elevation: 16.0,
                        onPressed: sendOTP,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'SEND OTP',
                            style: TextStyle(
                                color: widget.cardBackgroundColor, fontSize: 18.0),
                          ),
                        ),
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0)),
                      ),
                    ],

                  ),
                ),

                Visibility(
                  visible: otpSent,
                  child: Column (
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          SizedBox(width: 16.0),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                      text: 'Please enter the ',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w400)),
                                  TextSpan(
                                      text: 'One Time Password',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.w700)),
                                  TextSpan(
                                    text: ' sent to your mobile',
                                    style: TextStyle(
                                        color: Colors.white, fontWeight: FontWeight.w400),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 16.0),
                        ],
                      ),

                      SizedBox(height: 16.0),

                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          getPinField(key: "1", focusNode: focusNode1),
                          SizedBox(width: 5.0),
                          getPinField(key: "2", focusNode: focusNode2),
                          SizedBox(width: 5.0),
                          getPinField(key: "3", focusNode: focusNode3),
                          SizedBox(width: 5.0),
                          getPinField(key: "4", focusNode: focusNode4),
                          SizedBox(width: 5.0),
                          getPinField(key: "5", focusNode: focusNode5),
                          SizedBox(width: 5.0),
                          getPinField(key: "6", focusNode: focusNode6),
                          SizedBox(width: 5.0),
                        ],
                      ),

                      SizedBox(height: 32.0),

                      RaisedButton(
                        elevation: 16.0,
                        onPressed: verifyOTP,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'VERIFY',
                            style: TextStyle(
                                color: Colors.blueGrey, fontSize: 18.0),
                          ),
                        ),
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0)),
                      ),
                    ],

                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
