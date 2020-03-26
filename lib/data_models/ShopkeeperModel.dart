import 'package:google_map_location_picker/google_map_location_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dart_geohash/dart_geohash.dart';

class ShopkeeperModel{
  String shopName;
  String contactName;
  String GST;
  String address;
  LatLng coordinates;
  String geohash;
  String phoneNumber;

  ShopkeeperModel(this.shopName, this.contactName, this.GST,
      this.address, this.coordinates, this.geohash, this.phoneNumber);
}