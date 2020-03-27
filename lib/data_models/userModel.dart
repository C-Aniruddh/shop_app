import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_map_location_picker/google_map_location_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dart_geohash/dart_geohash.dart';

import '../firebase/auth/auth.dart';

class UserModel{
  String userName;
  String address;
  LatLng coordinates;
  String geohash;
  String phoneNumber;
  String uid;

  UserModel(this.userName, this.address, this.phoneNumber, this.coordinates,
  this.geohash, this.uid);
}