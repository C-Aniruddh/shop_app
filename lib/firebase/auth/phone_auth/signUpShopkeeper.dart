import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:local_dukaan/data_models/countries.dart';
import 'package:local_dukaan/utils/constants.dart';
import '../../../data_models/ShopkeeperModel.dart';
import '../../../screens/homePage.dart';
import '../../../utils/widgets.dart';
import 'package:google_map_location_picker/google_map_location_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:local_dukaan/data_models/ShopkeeperModel.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class SignUpShopkeeper extends StatefulWidget {
  final Color cardBackgroundColor = Color(0xFF6874C2);
  final String logo = Assets.localdukaan;

  @override
  SignUpShopkeeperState createState() => SignUpShopkeeperState();
}

class SignUpShopkeeperState extends State<SignUpShopkeeper> {
  double _height, _width, _fixedPadding;

  List<Country> countries = [];
  StreamController<List<Country>> _countriesStreamController;
  Stream<List<Country>> _countriesStream;
  Sink<List<Country>> _countriesSink;

  TextEditingController _searchCountryController = TextEditingController();
  TextEditingController _phoneNumberController = TextEditingController();
  TextEditingController _shopNameController = TextEditingController();
  TextEditingController _shopAddressController = TextEditingController();
  TextEditingController _shopContactNameController = TextEditingController();
  TextEditingController _shopGSTController = TextEditingController();

  int _selectedCountryIndex = 0;
  bool _isCountriesDataFormed = false;
  String apiKey = "AIzaSyC8mQe0t6T0yJz1DJNW9w0nKgUzKx-aCHM";

  String shopAddress = "";
  LatLng shopCoordinates;

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


  @override
  void initState() {
    super.initState();
    _shopAddressController.text = "Select location on map";
  }

  @override
  void dispose() {
    _searchCountryController.dispose();
    super.dispose();
  }

  Future<List<Country>> loadCountriesJson() async {
    countries.clear();
    var value = await DefaultAssetBundle.of(context)
        .loadString("data/country_phone_codes.json");
    var countriesJson = json.decode(value);
    for (var country in countriesJson) {
      countries.add(Country.fromJson(country));
    }
    return countries;
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
          GeoHasher geoHasher = GeoHasher();
          String geohash = geoHasher.encode(shopCoordinates.longitude, shopCoordinates.latitude, precision: 8);

          ShopkeeperModel shopkeeperModel = ShopkeeperModel(_shopNameController.text,
              _shopContactNameController.text,
              _shopGSTController.text,
              shopAddress,
              shopCoordinates,
              geohash,
              _phoneNumberController.text);

          DocumentReference _docRef =  Firestore.instance.collection('shops').document(user.uid);

          _docRef.setData({
            'phone_number': shopkeeperModel.phoneNumber,
            'limit': 10,
            'shop_name': shopkeeperModel.shopName,
            'shop_contact_name': shopkeeperModel.contactName,
            'shop_address': shopkeeperModel.address,
            'shop_lat': shopkeeperModel.coordinates.latitude,
            'shop_lon': shopkeeperModel.coordinates.longitude,
            'shop_geohash': shopkeeperModel.geohash,
            'shop_GST': shopkeeperModel.gst,
            'uid': user.uid,
            'token': 'none'
          });

          DocumentReference _docRef2 =  Firestore.instance.collection('uid_type').document(user.uid);
          _docRef2.setData({
            'type': 'shop',
          });

          Navigator.pushAndRemoveUntil(context,
              new MaterialPageRoute(builder: (context) => new MyHomePage(shopkeeperModel: shopkeeperModel, type: 'user')),
              ModalRoute.withName("/home"));
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
      print("PhoneCodeSent verificationID: " + _verificationId.toString());
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

    setState(() {
      otpSent = true;
    });
    //await _signInWithPhoneNumber();
  }

  // Example code of how to sign in with phone.
  void _signInWithPhoneNumber() async {
    print("_signInWithPhoneNumber verificationID: " + _verificationId.toString());
    print("_signInWithPhoneNumber code: " + code.toString());
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
        GeoHasher geoHasher = GeoHasher();
        String geohash = geoHasher.encode(shopCoordinates.longitude, shopCoordinates.latitude, precision: 8);

        ShopkeeperModel shopkeeperModel = ShopkeeperModel(_shopNameController.text,
            _shopContactNameController.text,
            _shopGSTController.text,
            shopAddress,
            shopCoordinates,
            geohash,
            _phoneNumberController.text);

        DocumentReference _docRef =  Firestore.instance.collection('shops').document(user.uid);

        _docRef.setData({
          'phone_number': shopkeeperModel.phoneNumber,
          'limit': 10,
          'shop_name': shopkeeperModel.shopName,
          'shop_contact_name': shopkeeperModel.contactName,
          'shop_address': shopkeeperModel.address,
          'shop_lat': shopkeeperModel.coordinates.latitude,
          'shop_lon': shopkeeperModel.coordinates.longitude,
          'shop_geohash': shopkeeperModel.geohash,
          'shop_GST': shopkeeperModel.gst,
          'uid': user.uid,
          'token': 'none'
        });

        DocumentReference _docRef2 =  Firestore.instance.collection('uid_type').document(user.uid);
        _docRef2.setData({
          'type': 'shop',
        });

        Navigator.pushAndRemoveUntil(context,
            new MaterialPageRoute(builder: (context) => new MyHomePage(shopkeeperModel: shopkeeperModel, type: 'user')),
            ModalRoute.withName("/home"));
      } else {
        // sign in failed
        print("_signInWithPhoneNumber FAILURE");
      }
    });
  }



  showCountries() {
    _countriesStreamController = StreamController();
    _countriesStream = _countriesStreamController.stream;
    _countriesSink = _countriesStreamController.sink;
    _countriesSink.add(countries);

    _searchCountryController.addListener(searchCountries);

    showDialog(
        context: context,
        builder: (BuildContext context) => searchAndPickYourCountryHere(),
        barrierDismissible: false);
  }

  searchCountries() {
    String query = _searchCountryController.text;
    if (query.length == 0 || query.length == 1) {
      if(!_countriesStreamController.isClosed)
        _countriesSink.add(countries);
//      print('added all countries again');
    } else if (query.length >= 2 && query.length <= 5) {
      List<Country> searchResults = [];
      searchResults.clear();
      countries.forEach((Country c) {
        if (c.toString().toLowerCase().contains(query.toLowerCase()))
          searchResults.add(c);
      });
      _countriesSink.add(searchResults);
    } else {
      List<Country> searchResults = [];
      _countriesSink.add(searchResults);
    }
  }

  Widget searchAndPickYourCountryHere() => WillPopScope(
    onWillPop: () => Future.value(false),
    child: Dialog(
      key: Key('SearchCountryDialog'),
      elevation: 8.0,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Container(
        margin: const EdgeInsets.all(5.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            PhoneAuthWidgets.searchCountry(_searchCountryController),

            SizedBox(
              height: 300.0,
              child: StreamBuilder<List<Country>>(
                //key: Key('Countries-StreamBuilder'),
                  stream: _countriesStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      // print(snapshot.data.length);
                      return snapshot.data.length == 0
                          ? Center(
                        child: Text('Your search found no results',
                            style: TextStyle(fontSize: 16.0)),
                      )
                          : ListView.builder(
                        itemCount: snapshot.data.length,
                        itemBuilder: (BuildContext context, int i) =>
                            PhoneAuthWidgets.selectableWidget(
                                snapshot.data[i],
                                    (Country c) => selectThisCountry(c)),
                      );
                    } else if (snapshot.hasError)
                      return Center(
                        child: Text('Seems, there is an error',
                            style: TextStyle(fontSize: 16.0)),
                      );
                    return Center(child: CircularProgressIndicator());
                  }),
            )
          ],
        ),
      ),
    ),
  );

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
            child: Container(
              child: SizedBox(
                width: _width,
                child: _isCountriesDataFormed
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    //  Logo: scaling to occupy 2 parts of 10 in the whole height of device
                    Padding(
                      padding: EdgeInsets.all(_fixedPadding),
                      child: PhoneAuthWidgets.getLogo(
                          logoPath: widget.logo, height: _height * 0.2),
                    ),

                    // AppName:
                    Text("Sign up as shopkeeper",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.0,
                            fontWeight: FontWeight.w700)),

                    SizedBox(height: _fixedPadding * 1.5),
                    Divider(),
                    SizedBox(height: _fixedPadding * 1.5),

                    Visibility(
                      visible: !otpSent,
                      child: Column(
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.only(top: 10.0, left: _fixedPadding),
                            child: PhoneAuthWidgets.subTitle('Enter your phone number'),
                          ),
                          //  PhoneNumber TextFormFields
                          Padding(
                            padding: EdgeInsets.only(
                                left: _fixedPadding,
                                right: _fixedPadding,
                                bottom: _fixedPadding),
                            child: PhoneAuthWidgets.phoneNumberField(_phoneNumberController,
                                countries[_selectedCountryIndex].dialCode),
                          ),

                          Padding(
                            padding: EdgeInsets.only(top: 10.0, left: _fixedPadding),
                            child: PhoneAuthWidgets.subTitle('Enter name of your shop'),
                          ),

                          Padding(
                            padding: EdgeInsets.only(
                                left: _fixedPadding,
                                right: _fixedPadding,
                                bottom: _fixedPadding),
                            child: PhoneAuthWidgets.textField(_shopNameController),
                          ),

                          Padding(
                            padding: EdgeInsets.only(top: 10.0, left: _fixedPadding),
                            child: PhoneAuthWidgets.subTitle('Select address of your place'),
                          ),


                          InkWell(
                            onTap: () async{
                              LocationResult result = await showLocationPicker(context, apiKey);
                              print(result.address);
                              print(result.latLng);
                              setState(() {
                                _shopAddressController.text = result.address;
                                shopAddress = result.address;
                                shopCoordinates = result.latLng;
                              });
                            },
                            child: Padding(
                              padding: EdgeInsets.only(
                                  left: _fixedPadding,
                                  right: _fixedPadding,
                                  bottom: _fixedPadding),
                              child: PhoneAuthWidgets.textFieldDisabled(_shopAddressController),
                            ),
                          ),

                          Padding(
                            padding: EdgeInsets.only(top: 10.0, left: _fixedPadding),
                            child: PhoneAuthWidgets.subTitle('Enter your name'),
                          ),

                          Padding(
                            padding: EdgeInsets.only(
                                left: _fixedPadding,
                                right: _fixedPadding,
                                bottom: _fixedPadding),
                            child: PhoneAuthWidgets.textField(_shopContactNameController),
                          ),

                          Padding(
                            padding: EdgeInsets.only(top: 10.0, left: _fixedPadding),
                            child: PhoneAuthWidgets.subTitle('Enter your GST Number (if applicable)'),
                          ),

                          Padding(
                            padding: EdgeInsets.only(
                                left: _fixedPadding,
                                right: _fixedPadding,
                                bottom: _fixedPadding),
                            child: PhoneAuthWidgets.textField(_shopGSTController),
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
                            onPressed: _verifyPhoneNumber,
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
                            onPressed: _signInWithPhoneNumber,
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
                    SizedBox(height: _fixedPadding * 1.5),
                  ],
                )
                    : Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
