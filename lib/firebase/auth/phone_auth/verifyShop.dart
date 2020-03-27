import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase/firebase/auth/auth.dart';
import 'package:flutter_firebase/screens/homePage.dart';
import 'package:flutter_firebase/utils/widgets.dart';
import 'package:flutter_firebase/utils/constants.dart';
import 'package:flutter_firebase/firebase/auth/phone_auth/signUpShopkeeper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_firebase/data_models/ShopkeeperModel.dart';

import '../../../pin_test.dart';

// ignore: must_be_immutable
class PhoneAuthVerifyShop extends StatefulWidget {
  PhoneAuthVerifyShop({Key key, this.shopkeeperModel}) : super(key: key);

  final ShopkeeperModel shopkeeperModel;
  /*
   *  cardBackgroundColor & logo values will be passed to the constructor
   *  here we access these params in the _PhoneAuthState using "widget"
   */
  Color cardBackgroundColor = Color(0xFFFCA967);
  String logo = Assets.firebase;
  String appName = "ShopApp";

  @override
  _PhoneAuthVerifyStateShop createState() => _PhoneAuthVerifyStateShop();
}

class _PhoneAuthVerifyStateShop extends State<PhoneAuthVerifyShop> {
  double _height, _width, _fixedPadding;

  FocusNode focusNode1 = FocusNode();
  FocusNode focusNode2 = FocusNode();
  FocusNode focusNode3 = FocusNode();
  FocusNode focusNode4 = FocusNode();
  FocusNode focusNode5 = FocusNode();
  FocusNode focusNode6 = FocusNode();
  String code = "";

  String phoneNo;
  String smsCode;
  String verificationId;

  @override
  void initState() {
    verifyPhone();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //  Fetching height & width parameters from the MediaQuery
    //  _logoPadding will be a constant, scaling it according to device's size
    _height = MediaQuery.of(context).size.height;
    _width = MediaQuery.of(context).size.width;
    _fixedPadding = _height * 0.025;

    /*
     *  Scaffold: Using a Scaffold widget as parent
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
          child: _getColumnBody(),
        ),
      );

  Widget _getColumnBody() => Column(
        children: <Widget>[
          //  Logo: scaling to occupy 2 parts of 10 in the whole height of device
          Padding(
            padding: EdgeInsets.all(_fixedPadding),
            child: PhoneAuthWidgets.getLogo(
                logoPath: widget.logo, height: _height * 0.2),
          ),

          // AppName:
          Text(widget.appName,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24.0,
                  fontWeight: FontWeight.w700)),

          SizedBox(height: 20.0),

          //  Info text
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
            onPressed: signInAction,
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
          )
        ],
      );

  Future<void> verifyPhone() async {
    final PhoneCodeAutoRetrievalTimeout autoRetrieve = (String verId) {
      this.verificationId = verId;
    };

    final PhoneCodeSent smsCodeSent = (String verId, [int forceCodeResend]) {
      this.verificationId = verId;
    };

    final PhoneVerificationCompleted verifiedSuccess = (AuthCredential auth) async {
      FireBase.auth.signInWithCredential(auth).then((AuthResult value) async {
        if (value.user != null) {
          print("user not null");
          await Firestore.instance.collection('uid_type')
              .where('uid', isEqualTo: value.user.uid)
              .getDocuments()
              .then((docs) async{
            if(docs.documents.length == 0){
              Firestore.instance.collection('uid_type')
                  .add({'uid': value.user.uid,
                'type': 'shop',
              }).then((val){
                Firestore.instance.collection('users')
                    .add({'phone_number': widget.shopkeeperModel.phoneNumber,
                  'limit': 10,
                  'shop_name': widget.shopkeeperModel.shopName,
                  'shop_contact_name': widget.shopkeeperModel.contactName,
                  'shop_address': widget.shopkeeperModel.address,
                  'shop_lat': widget.shopkeeperModel.coordinates.latitude,
                  'shop_lon': widget.shopkeeperModel.coordinates.longitude,
                  'shop_geohash': widget.shopkeeperModel.geohash,
                  'shop_GST': widget.shopkeeperModel.GST,
                  'uid': value.user.uid,
                  'token': 'none'}).then((val2){
                  Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
                });
              });
            } else {
              _showInfoDialog(context, "Your account already exists, try signing in.");
              print("user already exists");
            }
          });
        } else {
          _showInfoDialog(context, "Something went wrong, please try again. If problem persists, contact us at hello@shopapp.com");
        }
      }).catchError((error) {
        print(error);
      });
    };

    final PhoneVerificationFailed veriFailed = (AuthException exception) {
      print('${exception.message}');
    };

    await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: "+91" + widget.shopkeeperModel.phoneNumber,
        codeAutoRetrievalTimeout: autoRetrieve,
        codeSent: smsCodeSent,
        timeout: const Duration(seconds: 5),
        verificationCompleted: verifiedSuccess,
        verificationFailed: veriFailed);
  }


  void signIn() {
    final AuthCredential credential = PhoneAuthProvider.getCredential(verificationId: verificationId, smsCode: code);

    FirebaseAuth.instance.signInWithCredential(credential)
        .then((user) async{
          if(user != null){
            await Firestore.instance.collection('uid_type')
                .where('uid', isEqualTo: user.user.uid)
                .getDocuments()
                .then((docs) async{
              if(docs.documents.length == 0){
                Firestore.instance.collection('uid_type')
                    .add({'uid': user.user.uid,
                  'type': 'shop',
                }).then((val){
                  Firestore.instance.collection('users')
                      .add({'phone_number': widget.shopkeeperModel.phoneNumber,
                    'limit': 10,
                    'shop_name': widget.shopkeeperModel.shopName,
                    'shop_contact_name': widget.shopkeeperModel.contactName,
                    'shop_address': widget.shopkeeperModel.address,
                    'shop_lat': widget.shopkeeperModel.coordinates.latitude,
                    'shop_lon': widget.shopkeeperModel.coordinates.longitude,
                    'shop_geohash': widget.shopkeeperModel.geohash,
                    'shop_GST': widget.shopkeeperModel.GST,
                    'uid': user.user.uid,
                    'token': 'none'}).then((val2){
                    Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
                  });
                });
              } else {
                _showInfoDialog(context, "Your account already exists, try signing in.");
                print("user already exists");
              }
            });
          } else {
            print("user null here");
          }

    }).catchError((error) {
      print(error.message);
    });
  }


  signInAction() async {
    if (code.length != 6) {
      //  TODO: show error
    }
    _showInfoDialog(context, "Authenticating...");
    FirebaseAuth.instance.currentUser().then((user) {
      if (user != null) {
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
      } else {
        //Navigator.of(context).pop();
        signIn();
      }
    });
    //await FirebasePhoneAuth.signInWithPhoneNumberUser(smsCode: code, userModel: widget.userModel);
    //sleep(Duration(seconds: 6));
    //Navigator.pop(context);
    //Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MyHomePage()));
    //Navigator.pushNamedAndRemoveUntil(context, "/home", (_) => false);

  }

  _showInfoDialog(BuildContext context, String text) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: SingleChildScrollView(
              child: Container(
                child: Text(text),
              ),
            ),

          );
        });
  }

  // This will return pin field - it accepts only single char
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
}
