import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_firebase/firebase/auth/auth.dart';
import 'package:flutter_firebase/data_models/ShopkeeperModel.dart';
import 'package:flutter_firebase/data_models/userModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum PhoneAuthState {
  Started,
  CodeSent,
  CodeResent,
  Verified,
  Failed,
  Error,
  AutoRetrievalTimeOut
}

class FirebasePhoneAuth {
  static var _authCredential, actualCode, phone, status;
  static StreamController<String> statusStream =
      StreamController.broadcast();
  static StreamController<PhoneAuthState> phoneAuthState =
      StreamController.broadcast();
  static Stream stateStream = phoneAuthState.stream;

  static instantiate({String phoneNumber}) async {
    assert(phoneNumber != null);
    phone = phoneNumber;
    print(phone);
    startAuth();
  }

  static dispose() {
//    statusStream.close();
//    phoneAuthState.close();
  }

  static startAuth() {
    statusStream.stream
        .listen((String status) => print("PhoneAuth: " + status));
    addStatus('Phone auth started');
    FireBase.auth
        .verifyPhoneNumber(
            phoneNumber: phone.toString(),
            timeout: Duration(seconds: 120),
            verificationCompleted: verificationCompleted,
            verificationFailed: verificationFailed,
            codeSent: codeSent,
            codeAutoRetrievalTimeout: codeAutoRetrievalTimeout)
        .then((value) {
      addStatus('Code sent');
    }).catchError((error) {
      addStatus(error.toString());
    });
  }

  static final PhoneCodeSent codeSent =
      (String verificationId, [int forceResendingToken]) async {
    actualCode = verificationId;
    addStatus("\nEnter the code sent to " + phone);
    addState(PhoneAuthState.CodeSent);
  };

  static final PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout =
      (String verificationId) {
    actualCode = verificationId;
    addStatus("\nAuto retrieval time out");
    addState(PhoneAuthState.AutoRetrievalTimeOut);
  };

  static final PhoneVerificationFailed verificationFailed =
      (AuthException authException) {
    addStatus('${authException.message}');
    addState(PhoneAuthState.Error);
    if (authException.message.contains('not authorized'))
      addStatus('App not authroized');
    else if (authException.message.contains('Network'))
      addStatus('Please check your internet connection and try again');
    else
      addStatus('Something has gone wrong, please try later ' +
          authException.message);
  };

  static final PhoneVerificationCompleted verificationCompleted =
      (AuthCredential auth) {
    addStatus('Auto retrieving verification code');

    FireBase.auth.signInWithCredential(auth).then((AuthResult value) {
      if (value.user != null) {
        addStatus(status = 'Authentication successful');
        addState(PhoneAuthState.Verified);
        doNothing();
      } else {
        addState(PhoneAuthState.Failed);
        addStatus('Invalid code/invalid authentication');
      }
    }).catchError((error) {
      addState(PhoneAuthState.Error);
      addStatus('Something has gone wrong, please try later $error');
    });
  };

  static Future<bool> signInWithPhoneNumberShopkeeper({String smsCode, ShopkeeperModel skm}) async {
    _authCredential = PhoneAuthProvider.getCredential(
        verificationId: actualCode, smsCode: smsCode);

    FireBase.auth
        .signInWithCredential(_authCredential)
        .then((AuthResult result) async {
      addStatus('Authentication successful');
      addState(PhoneAuthState.Verified);
      onAuthenticationSuccessfulShopKeeper(skm, result.user);

    }).catchError((error) {
      addState(PhoneAuthState.Error);
      addStatus(
          'Something has gone wrong, please try later(signInWithPhoneNumber) $error');
    });
    return true;
  }

  static Future<bool> signInWithPhoneNumberUser({String smsCode, UserModel userModel}) async {
    _authCredential = PhoneAuthProvider.getCredential(
        verificationId: actualCode, smsCode: smsCode);

    FireBase.auth
        .signInWithCredential(_authCredential)
        .then((AuthResult result) async {
      addStatus('Authentication successful');
      addState(PhoneAuthState.Verified);
      onAuthenticationSuccessful(userModel, result.user);
      return true;
    }).catchError((error) {
      addState(PhoneAuthState.Error);
      addStatus(
          'Something has gone wrong, please try later(signInWithPhoneNumber) $error');
      return false;
    });
    return true;
  }

  static Future<bool> signInWithPhoneNumber({String smsCode}) async {
    _authCredential = PhoneAuthProvider.getCredential(
        verificationId: actualCode, smsCode: smsCode);

    FireBase.auth
        .signInWithCredential(_authCredential)
        .then((AuthResult result) async {
      addStatus('Authentication successful');
      addState(PhoneAuthState.Verified);
      doNothing();
      return true;
    }).catchError((error) {
      addState(PhoneAuthState.Error);
      addStatus(
          'Something has gone wrong, please try later(signInWithPhoneNumber) $error');
      return false;
    });
  }


  static doNothing(){}

  static onAuthenticationSuccessful(UserModel userModel, FirebaseUser user) {
    //  TODO: handle authentication successful

    Firestore.instance.collection('uid_type')
        .where('uid', isEqualTo: user.uid)
        .getDocuments()
        .then((docs){
      if(docs.documents.length == 0){
        Firestore.instance.collection('uid_type')
            .add({'uid': user.uid,
          'type': 'user',
        });
      } else {
        print("user already exists");
      }
    });

    Firestore.instance.collection('users')
        .where('phone_number', isEqualTo: userModel.phoneNumber)
        .getDocuments()
        .then((docs){
      if(docs.documents.length == 0){
        Firestore.instance.collection('users')
            .add({'phone_number': userModel.phoneNumber,
          'name': userModel.userName,
          'address': userModel.address,
          'lat': userModel.coordinates.latitude,
          'lon': userModel.coordinates.longitude,
          'geohash': userModel.geohash,
          'uid': user.uid,
          'token': 'none',
        });
      } else {
        print("user already exists");
      }
    });

  }

  static onAuthenticationSuccessfulShopKeeper(ShopkeeperModel skm, FirebaseUser user) {
    //  TODO: handle authentication successful

    Firestore.instance.collection('uid_type')
        .where('uid', isEqualTo: user.uid)
        .getDocuments()
        .then((docs){
      if(docs.documents.length == 0){
        Firestore.instance.collection('uid_type')
            .add({'uid': user.uid,
          'type': 'shop',
        });
      } else {
        print("shop already exists");
      }
    });

    Firestore.instance.collection('shops')
        .where('phone_number', isEqualTo: skm.phoneNumber)
        .getDocuments()
        .then((docs){
          if(docs.documents.length == 0){
            Firestore.instance.collection('shops')
                .add({'phone_number': skm.phoneNumber,
                      'limit': 10,
                      'shop_name': skm.shopName,
                      'shop_contact_name': skm.contactName,
                      'shop_address': skm.address,
                      'shop_lat': skm.coordinates.latitude,
                      'shop_lon': skm.coordinates.longitude,
                      'shop_geohash': skm.geohash,
                      'shop_GST': skm.GST,
                      'uid': user.uid,
                      'token': 'none'});
          } else {
            print("user already exists");
          }
    });
  }

  static addState(PhoneAuthState state) {

    print(state);
    phoneAuthState.sink.add(state);
  }

  static void addStatus(String s) {
    statusStream.sink.add(s);
    print(s);
  }
}
