import 'package:google_maps_flutter/google_maps_flutter.dart';

class ShopkeeperModel{
  String shopName;
  String contactName;
  String gst;
  String address;
  LatLng coordinates;
  String geohash;
  String phoneNumber;

  ShopkeeperModel(this.shopName, this.contactName, this.gst,
      this.address, this.coordinates, this.geohash, this.phoneNumber);
}