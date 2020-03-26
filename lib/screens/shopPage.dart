import 'dart:async';
import 'dart:core';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_firebase/utils/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_firebase/screens/homePage.dart';

class ShopPage extends StatefulWidget {
  ShopPage({Key key, this.shopDetails, this.userDetails}) : super(key: key);

  DocumentSnapshot shopDetails;
  DocumentSnapshot userDetails;

  @override
  _ShopPageState createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  CameraPosition _kGooglePlex;
  Completer<GoogleMapController> _controller = Completer();

  bool mapLoaded = false;
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};

  final TextEditingController _textEditingController = new TextEditingController();

  void _add() {
    var markerIdVal = 'marker';
    final MarkerId markerId = MarkerId(markerIdVal);

    // creating a new MARKER
    final Marker marker = Marker(
      markerId: markerId,
      position: LatLng(
          widget.shopDetails['shop_lat'], widget.shopDetails['shop_lon']),
    );

    setState(() {
      // adding a new marker to map
      markers[markerId] = marker;
    });
  }

  void setupMap() async {
    _kGooglePlex = CameraPosition(
      target: LatLng(
          widget.shopDetails['shop_lat'], widget.shopDetails['shop_lon']),
      zoom: 17,
    );
    _add();
  }

  void setup() async {
    await setupMap();
    setState(() {
      mapLoaded = true;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    setup();
    super.initState();
  }

  _showInformationDialog(BuildContext context, String text) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: SingleChildScrollView(
              child: Container(
                child: Text(text),
              ),
            ),
            actions: <Widget>[
              FlatButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'Okay',
                ),
              ),
            ],
          );
        });
  }
  _showDialog() async {
    await showDialog<String>(
      context: context,
      child: AlertDialog(
        contentPadding: const EdgeInsets.all(16.0),
        content: Column(mainAxisSize: MainAxisSize.min,
            children: <Widget>[
          Text("Request an appointment"),
          TextFormField(
            maxLines: 5,
            autofocus: true,
            decoration: InputDecoration(labelText: 'What do you want to buy?'),
            keyboardType: TextInputType.multiline,
            controller: _textEditingController,
          ),
        ]),
        actions: <Widget>[
          FlatButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
              }),
          FlatButton(
              child: Text('Request Appointment'),
              onPressed: () {
                var rng = new Random();
                var now = new DateTime.now();
                Firestore.instance.collection('appointments')
                    .add({'timestamp': now,
                  'items': _textEditingController.text,
                  'target_shop': widget.shopDetails['uid'],
                  'shopper_uid': widget.userDetails['uid'],
                  'shopper_name': widget.userDetails['name'],
                  'shop_name': widget.shopDetails['shop_name'],
                  'shop_geohash': widget.shopDetails['shop_geohash'],
                  'appointment_status': 'pending',
                  'appointment_start': null,
                  'appointment_end': null,
                  'otp': (rng.nextInt(10000) + 1000).toString()
                });
                Navigator.pop(context);
                _showInformationDialog(context, "Your appointment was successfully requested");
              })
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var _fixedPadding = MediaQuery.of(context).size.height * 0.025;
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(widget.shopDetails['shop_name']),
      ),
      body: Column(
        children: <Widget>[
          SizedBox(
              height: MediaQuery.of(context).size.height * 0.50,
              width: MediaQuery.of(context).size.width,
              child: mapLoaded
                  ? GoogleMap(
                      mapType: MapType.normal,
                      initialCameraPosition: _kGooglePlex,
                      markers: Set<Marker>.of(markers.values),
                      onMapCreated: (GoogleMapController controller) {
                        _controller.complete(controller);
                      },
                    )
                  : Container()),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Container(
                    child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ListTile(
                          title: Text("Address"),
                          leading: CircleAvatar(
                            backgroundColor: Colors.cyan,
                            child: Text("A"),
                          ),
                          subtitle: Text(widget.shopDetails['shop_address']),
                          trailing: IconButton(
                            icon: Icon(Icons.map),
                            onPressed: () {
                              print("Open");
                              MapUtils.openMap(widget.shopDetails['shop_lat'],
                                  widget.shopDetails['shop_lon']);
                            },
                          ),
                        ),
                      ),
                    ),
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ListTile(
                          title: Text("Contact Owner"),
                          leading: CircleAvatar(
                            backgroundColor: Colors.cyan,
                            child: Text("C"),
                          ),
                          subtitle: Text(
                              widget.shopDetails['shop_contact_name'] +
                                  " (" +
                                  widget.shopDetails['phone_number'] +
                                  ")"),
                          trailing: IconButton(
                            icon: Icon(Icons.call),
                            onPressed: () {
                              print("Open");
                              // MapUtils.openMap(widget.shopDetails['shop_lat'], widget.shopDetails['shop_lon']);
                            },
                          ),
                        ),
                      ),
                    ),
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ListTile(
                          title: Text("User Limit (Every 10 minutes)"),
                          leading: CircleAvatar(
                            backgroundColor: Colors.cyan,
                            child: Text("L"),
                          ),
                          subtitle:
                              Text(widget.shopDetails['limit'].toString()),
                          trailing: IconButton(
                            icon: Icon(Icons.info),
                            onPressed: () {
                              print("Open");
                              // MapUtils.openMap(widget.shopDetails['shop_lat'], widget.shopDetails['shop_lon']);
                            },
                          ),
                        ),
                      ),
                    )
                  ],
                ))),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showDialog();
        },
        tooltip: 'Make an appointment',
        child: Icon(Icons.add),
      ),
    );
  }
}
