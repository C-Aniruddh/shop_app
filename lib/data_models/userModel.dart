import 'package:google_map_location_picker/google_map_location_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dart_geohash/dart_geohash.dart';

class UserModel{
  String userName;
  String address;
  LatLng coordinates;
  String geohash;
  String phoneNumber;

  UserModel(this.userName, this.address, this.phoneNumber, this.coordinates,
  this.geohash);
}