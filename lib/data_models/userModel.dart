import 'package:google_maps_flutter/google_maps_flutter.dart';

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