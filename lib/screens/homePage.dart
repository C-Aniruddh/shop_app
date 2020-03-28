import 'package:dart_geohash/dart_geohash.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_firebase/screens/loginPage.dart';
import 'package:cuberto_bottom_bar/cuberto_bottom_bar.dart';
import 'package:flutter_firebase/handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_firebase/screens/shopPage.dart';
import 'package:flutter_firebase/utils/widgets.dart';
import 'package:latlong/latlong.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';

import '../data_models/ShopkeeperModel.dart';
import '../data_models/userModel.dart';
import 'loginPage.dart';

class MapUtils {
  MapUtils._();

  static Future<void> openMap(double latitude, double longitude) async {
    String googleUrl =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    if (await canLaunch(googleUrl)) {
      await launch(googleUrl);
    } else {
      throw 'Could not open the map.';
    }
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.userModel, this.shopkeeperModel, this.type}) : super(key: key);

  final UserModel userModel;
  final ShopkeeperModel shopkeeperModel;
  String type;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int currentPage = 0;
  String currentTitle = "Home";
  Color currentColor = Colors.cyan;

  String user_uid;

  bool userLoaded = false;

  DocumentSnapshot userData;

  String token;

  GeoHasher gH = GeoHasher();

  TextEditingController startTimeController = new TextEditingController();
  TextEditingController endTimeController = new TextEditingController();
  TextEditingController otpController = new TextEditingController();

  void setUserData(String type, String uid) async {
    token = await FirebaseNotifications().setUpFirebase();
    var userType = "";
    if (type == "user") {
      userType = "users";
    } else {
      userType = "shops";
    }
    await Firestore.instance
        .collection(userType)
        .document(uid)
        .get()
        .then((data) {
      userData = data;
    });
    await Firestore.instance
        .collection(userType)
        .document(uid)
        .updateData({'token': token});
    setState(() {
      userLoaded = true;
    });
  }

  List<String> calculateFilter() {
    if (widget.type == "user" && userLoaded) {
      String address_geohash = userData['geohash'];
      double add_lat = userData['lat'];
      double add_lon = userData['lon'];
      print(add_lat);
      print(add_lon);
      num queryDistance = 1000.round();

      final Distance distance = const Distance();
      //final num query_distance = (EARTH_RADIUS * PI / 4).round();

      final p1 = new LatLng(add_lat, add_lon);
      final upperP = distance.offset(p1, queryDistance, 45);
      final lowerP = distance.offset(p1, queryDistance, 220);

      print(upperP);
      print(lowerP);

      GeoHasher geoHasher = GeoHasher();

      String lower = geoHasher.encode(lowerP.longitude, lowerP.latitude);
      String upper = geoHasher.encode(upperP.longitude, upperP.latitude);

      List<String> upper_lower = [];
      upper_lower.add(upper);
      upper_lower.add(lower);
      return upper_lower;
    } else {
      return [];
    }
  }

  void checkUser() async {
    String uid;
    String type;
    await FirebaseAuth.instance.currentUser().then((user){
      if(user == null){
        //Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
        Navigator.pushNamedAndRemoveUntil(context, "/login", (_) => false);
      } else {
        uid = user.uid;
        Firestore.instance.collection('uid_type')
        .document(uid)
        .get()
        .then((value) async {
          type = value.data['type'];
          setState(() {
            widget.type = type;
          });
          setUserData(type, uid);
        });
      }
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    startTimeController.text = "Select start time";
    endTimeController.text = "Select end time";
    checkUser();
    super.initState();
  }

  String distanceBetween(String shop_geohash) {
    String user_geohash = userData['geohash'];
    GeoHasher geoHasher = GeoHasher();
    List<double> shop_coordinates = geoHasher.decode(shop_geohash);
    List<double> user_coordinates = geoHasher.decode(user_geohash);
    print(user_coordinates);
    Distance distance = new Distance();
    double meter = distance(
        new LatLng(shop_coordinates[1], shop_coordinates[0]),
        new LatLng(user_coordinates[1], user_coordinates[0]));
    return meter.round().toString();
  }

  List<DocumentSnapshot> filterByDistance(List<DocumentSnapshot> all_docs) {
    List<DocumentSnapshot> to_return = [];
    for (var i = 0; i < all_docs.length; i++) {
      if (double.parse(distanceBetween(all_docs[i]['shop_geohash'])) < 1000) {
        to_return.add(all_docs[i]);
      } else {
        // do nothing
      }
    }
    return to_return;
  }

  Widget buildHomeUser() {
    List<String> upper_lower = calculateFilter();
    String upper = upper_lower[0];
    String lower = upper_lower[1];

    return Container(
        padding: const EdgeInsets.all(10.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: Firestore.instance
              .collection('shops')
              .where("shop_geohash", isGreaterThanOrEqualTo: lower)
              .where("shop_geohash", isLessThanOrEqualTo: upper)
              .snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) return new Text('Error: ${snapshot.error}');
            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
                return new Text('Loading...');
              default:
                return new ListView(
                  children: filterByDistance(snapshot.data.documents)
                      .map((DocumentSnapshot document) {
                    return Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: new ListTile(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ShopPage(
                                          shopDetails: document,
                                          userDetails: userData,
                                        )));
                          },
                          leading: CircleAvatar(
                            backgroundColor: Colors.cyan,
                            child: Text(document['shop_name'][0]
                                .toString()
                                .toUpperCase()),
                          ),
                          title: Text(document['shop_name']),
                          subtitle: Text(
                            distanceBetween(document['shop_geohash']) +
                                " meters away",
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.map),
                            onPressed: () {
                              print("Open");
                              MapUtils.openMap(
                                  document['shop_lat'], document['shop_lon']);
                            },
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
            }
          },
        ));
  }

  _showModalAppointmentDetails(DocumentSnapshot document) {
    showModalBottomSheet(
        context: context,
        builder: (context) => StatefulBuilder(
              builder: (BuildContext context, StateSetter setStateSheet) =>
                  SingleChildScrollView(
                child: Container(
                    color: Colors.grey[900],
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: Column(
                      children: <Widget>[
                        Align(
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Icon(Icons.info),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text('Appointment Details',
                                    style: TextStyle(fontSize: 16.0)),
                              ),
                              InkWell(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Icon(
                                    Icons.close,
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        Divider(
                          color: Colors.black26,
                        ),
                        SizedBox(
                            height: 300,
                            child: Container(
                                child: Column(
                              children: <Widget>[
                                Flexible(
                                  child: Padding(
                                      padding: EdgeInsets.fromLTRB(
                                          16.0, 8.0, 16.0, 0),
                                      child: Column(
                                        children: <Widget>[
                                          Card(
                                              child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: ListTile(
                                                    leading: CircleAvatar(
                                                      backgroundColor:
                                                          Colors.cyan,
                                                      child: Icon(Icons.lock),
                                                    ),
                                                    title: Text("OTP"),
                                                    subtitle:
                                                        Text(document['otp']),
                                                  ))),
                                          Card(
                                              child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: ListTile(
                                                    leading: CircleAvatar(
                                                      backgroundColor:
                                                          Colors.cyan,
                                                      child: Icon(Icons.timer),
                                                    ),
                                                    title: Text("Start Time"),
                                                    subtitle: Text(document[
                                                            'appointment_start']
                                                        .toString()),
                                                  ))),
                                          Card(
                                              child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: ListTile(
                                                    leading: CircleAvatar(
                                                      backgroundColor:
                                                          Colors.cyan,
                                                      child: Icon(Icons.timer),
                                                    ),
                                                    title: Text("End Time"),
                                                    subtitle: Text(document[
                                                            'appointment_end']
                                                        .toString()),
                                                  ))),
                                        ],
                                      )),
                                ),
                              ],
                            )))
                      ],
                    )),
              ),
            ));
  }

  Widget buildAppointmentsUser() {
    List<String> status = ['pending', 'scheduled'];
    return Container(
        padding: const EdgeInsets.all(10.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: Firestore.instance
              .collection('appointments')
              .where('appointment_status', whereIn: status)
              .where('shopper_uid', isEqualTo: user_uid)
              .snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) return new Text('Error: ${snapshot.error}');
            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
                return new Text('Loading...');
              default:
                return new ListView(
                  children:
                      snapshot.data.documents.map((DocumentSnapshot document) {
                    return Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: new ListTile(
                          onTap: () {
                            _showModalAppointmentDetails(document);

                            // Navigator.push(context, MaterialPageRoute(builder: (context)=> ShopPage(shopDetails: document, userDetails: userData,)));
                          },
                          leading: CircleAvatar(
                            backgroundColor: Colors.cyan,
                            child: Text(document['shop_name'][0]
                                .toString()
                                .toUpperCase()),
                          ),
                          title: Text(document['shop_name']),
                          subtitle: Text(document['appointment_status']),
                          trailing: IconButton(
                            icon: Icon(Icons.info),
                            onPressed: () {
                              print("Open");
                              _showModalAppointmentDetails(document);
                            },
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
            }
          },
        ));
  }

  Widget buildAppointmentsDoneUser() {
    return Container(
        padding: const EdgeInsets.all(10.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: Firestore.instance
              .collection('appointments')
              .where('appointment_status', isEqualTo: 'completed')
              .where('shopper_uid', isEqualTo: userData['uid'])
              .snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) return new Text('Error: ${snapshot.error}');
            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
                return new Text('Loading...');
              default:
                return new ListView(
                  children:
                      snapshot.data.documents.map((DocumentSnapshot document) {
                    return Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: new ListTile(
                          onTap: () {
                            _showModalAppointmentDetails(document);
                            //Navigator.push(context, MaterialPageRoute(builder: (context)=> ShopPage(shopDetails: document, userDetails: userData,)));
                          },
                          leading: CircleAvatar(
                            backgroundColor: Colors.cyan,
                            child: Text(document['shop_name'][0]
                                .toString()
                                .toUpperCase()),
                          ),
                          title: Text(document['shop_name']),
                          subtitle: Text(document['appointment_status']),
                          trailing: IconButton(
                            icon: Icon(Icons.info),
                            onPressed: () {
                              print("Open");
                              _showModalAppointmentDetails(document);
                            },
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
            }
          },
        ));
  }

  Widget buildHomeShop() {
    return Container(
        padding: const EdgeInsets.all(10.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: Firestore.instance
              .collection('appointments')
              .where('appointment_status', isEqualTo: 'scheduled')
              .where('target_shop', isEqualTo: userData['uid'])
              .snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) return new Text('Error: ${snapshot.error}');
            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
                return new Text('Loading...');
              default:
                return new ListView(
                  children:
                      snapshot.data.documents.map((DocumentSnapshot document) {
                    return Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: new ListTile(
                          onTap: () {
                            _showCompleteDialog(
                                context, document.documentID, document['otp']);
                            //Navigator.push(context, MaterialPageRoute(builder: (context)=> ShopPage(shopDetails: document, userDetails: userData,)));
                          },
                          leading: CircleAvatar(
                            backgroundColor: Colors.cyan,
                            child: Text(document['shopper_name'][0]
                                .toString()
                                .toUpperCase()),
                          ),
                          title: Text(document['shopper_name']),
                          subtitle: Text(document['appointment_status']),
                          trailing: IconButton(
                            icon: Icon(Icons.check),
                            onPressed: () {
                              print("Open");
                              _showCompleteDialog(context, document.documentID,
                                  document['otp']);
                            },
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
            }
          },
        ));
  }

  _showCompleteDialog(BuildContext context, String documentID, String otp) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: SingleChildScrollView(
              child: Container(
                  child: Column(
                children: <Widget>[
                  PhoneAuthWidgets.subTitle("Enter OTP"),
                  PhoneAuthWidgets.textField(otpController),
                ],
              )),
            ),
            actions: <Widget>[
              FlatButton(
                onPressed: () async {
                  if (otpController.text == otp) {
                    await Firestore.instance
                        .collection('appointments')
                        .document(documentID)
                        .updateData({'appointment_status': 'completed'}).then((value) async{
                          await Firestore.instance.collection('appointments')
                          .document(documentID).get().then((doc) async{
                            var title = "Apopintment completed";
                            var body = "Your appointment at " + doc['shop_name'] + " was marked completed";
                            await Firestore.instance.collection('notifications')
                                .add({'sender_type': "shops",
                              'receiver_uid': doc['shopper_uid'],
                              'title': title,
                              'body': body,
                            });
                          });
                    });
                    Navigator.pop(context);
                  } else {
                    Navigator.pop(context);
                    _showInfoDialog(context, "The entered OTP is wrong");
                  }
                },
                child: Text(
                  'Yes',
                ),
              ),
            ],
          );
        });
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
            actions: <Widget>[
              FlatButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'OKAY',
                ),
              ),
            ],
          );
        });
  }

  Widget buildPendingShop() {
    return Container(
        padding: const EdgeInsets.all(10.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: Firestore.instance
              .collection('appointments')
              .where('appointment_status', isEqualTo: 'pending')
              .where('target_shop', isEqualTo: userData['uid'])
              .snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) return new Text('Error: ${snapshot.error}');
            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
                return new Text('Loading...');
              default:
                return new ListView(
                  children:
                      snapshot.data.documents.map((DocumentSnapshot document) {
                    return Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: new ListTile(
                          onTap: () {
                            var startTime;
                            var endTime;
                            showModalBottomSheet(
                                context: context,
                                builder: (context) => StatefulBuilder(
                                      builder: (BuildContext context,
                                              StateSetter setStateSheet) =>
                                          SingleChildScrollView(
                                        child: Container(
                                            color: Colors.grey[900],
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.5,
                                            child: Column(
                                              children: <Widget>[
                                                Align(
                                                  alignment: Alignment.center,
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: <Widget>[
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(16.0),
                                                        child: Icon(Icons.info),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(16.0),
                                                        child: Text(
                                                            'Fix an appointment',
                                                            style: TextStyle(
                                                                fontSize:
                                                                    16.0)),
                                                      ),
                                                      InkWell(
                                                        onTap: () {
                                                          Navigator.pop(
                                                              context);
                                                        },
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(16.0),
                                                          child: Icon(
                                                            Icons.close,
                                                          ),
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                ),
                                                Divider(
                                                  color: Colors.black26,
                                                ),
                                                SizedBox(
                                                    height: 300,
                                                    child: Container(
                                                        child: Column(
                                                      children: <Widget>[
                                                        Flexible(
                                                          child: Padding(
                                                              padding:
                                                                  EdgeInsets
                                                                      .fromLTRB(
                                                                          16.0,
                                                                          8.0,
                                                                          16.0,
                                                                          0),
                                                              child: Column(
                                                                children: <
                                                                    Widget>[
                                                                  Card(
                                                                      child:
                                                                          Padding(
                                                                    padding:
                                                                        const EdgeInsets.all(
                                                                            0.0),
                                                                    child:
                                                                        ListTile(
                                                                      title: Text(
                                                                          "User needs : "),
                                                                      subtitle:
                                                                          Text(
                                                                        document[
                                                                            'items'],
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                        maxLines:
                                                                            5,
                                                                      ),
                                                                    ),
                                                                  )),
                                                                  InkWell(
                                                                      onTap:
                                                                          () {
                                                                        DatePicker.showTime12hPicker(
                                                                            context,
                                                                            theme: DatePickerTheme(
                                                                                backgroundColor: Colors.grey[900],
                                                                                itemStyle: TextStyle(color: Colors.white),
                                                                                cancelStyle: TextStyle(color: Colors.white)),
                                                                            showTitleActions: true, onChanged: (date) {
                                                                          print('change $date in time zone ' +
                                                                              date.timeZoneOffset.inHours.toString());
                                                                        }, onConfirm: (date) {
                                                                          startTime =
                                                                              date;
                                                                          setStateSheet(
                                                                              () {
                                                                            startTimeController.text =
                                                                                startTime.toString();
                                                                          });
                                                                        }, currentTime: DateTime.now());
                                                                      },
                                                                      child: PhoneAuthWidgets
                                                                          .textFieldDisabled(
                                                                              startTimeController)),
                                                                  InkWell(
                                                                      onTap:
                                                                          () {
                                                                        DatePicker.showTime12hPicker(
                                                                            context,
                                                                            theme: DatePickerTheme(
                                                                                backgroundColor: Colors.grey[900],
                                                                                itemStyle: TextStyle(color: Colors.white),
                                                                                cancelStyle: TextStyle(color: Colors.white)),
                                                                            showTitleActions: true, onChanged: (date) {
                                                                          print('change $date in time zone ' +
                                                                              date.timeZoneOffset.inHours.toString());
                                                                        }, onConfirm: (date) {
                                                                          endTime =
                                                                              date;
                                                                          setStateSheet(
                                                                              () {
                                                                            endTimeController.text =
                                                                                endTime.toString();
                                                                          });
                                                                        }, currentTime: DateTime.now());
                                                                      },
                                                                      child: PhoneAuthWidgets
                                                                          .textFieldDisabled(
                                                                              endTimeController)),
                                                                  Center(
                                                                    child:
                                                                        RaisedButton(
                                                                      color: Colors
                                                                          .cyan,
                                                                      child: Text(
                                                                          "Confirm"),
                                                                      onPressed:
                                                                          () {
                                                                        Firestore
                                                                            .instance
                                                                            .collection('appointments')
                                                                            .document(document.documentID)
                                                                            .updateData({
                                                                          'appointment_start':
                                                                              startTime,
                                                                          'appointment_end':
                                                                              endTime,
                                                                          'appointment_status':
                                                                              'scheduled'
                                                                        }).then((value) async {
                                                                          await Firestore.instance.collection('appointments')
                                                                              .document(document.documentID).get().then((doc) async{
                                                                            var title = "Apopintment scheduled";
                                                                            var body = "Your appointment at " + doc['shop_name'] + " is scheduled";
                                                                            await Firestore.instance.collection('notifications')
                                                                                .add({'sender_type': "shops",
                                                                              'receiver_uid': doc['shopper_uid'],
                                                                              'title': title,
                                                                              'body': body,
                                                                            });
                                                                          });
                                                                        });
                                                                        Navigator.pop(
                                                                            context);
                                                                      },
                                                                    ),
                                                                  )
                                                                ],
                                                              )),
                                                        ),
                                                      ],
                                                    )))
                                              ],
                                            )),
                                      ),
                                    ));
                          },
                          leading: CircleAvatar(
                            backgroundColor: Colors.cyan,
                            child: Text(document['shopper_name'][0]
                                .toString()
                                .toUpperCase()),
                          ),
                          title: Text(document['shopper_name']),
                          subtitle: Text("Tap to view more"),
                          trailing: IconButton(
                            icon: Icon(Icons.info),
                            onPressed: () {
                              print("Open");
                              List<double> pt =
                                  gH.decode(document['shop_geohash']);
                              MapUtils.openMap(pt[1], pt[0]);
                            },
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
            }
          },
        ));
  }

  Widget buildCompletedShop() {
    return Container(
        padding: const EdgeInsets.all(10.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: Firestore.instance
              .collection('appointments')
              .where('appointment_status', isEqualTo: 'completed')
              .where('target_shop', isEqualTo: userData['uid'])
              .snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) return new Text('Error: ${snapshot.error}');
            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
                return new Text('Loading...');
              default:
                return new ListView(
                  children:
                      snapshot.data.documents.map((DocumentSnapshot document) {
                    return Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: new ListTile(
                          onTap: () {
                            //Navigator.push(context, MaterialPageRoute(builder: (context)=> ShopPage(shopDetails: document, userDetails: userData,)));
                            _showModalAppointmentDetails(document);
                          },
                          leading: CircleAvatar(
                            backgroundColor: Colors.cyan,
                            child: Text(document['shopper_name'][0]
                                .toString()
                                .toUpperCase()),
                          ),
                          title: Text(document['shopper_name']),
                          subtitle: Text(document['appointment_status']),
                          trailing: IconButton(
                            icon: Icon(Icons.info),
                            onPressed: () {
                              print("Open");
                              _showModalAppointmentDetails(document);
                            },
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
            }
          },
        ));
  }

  Widget buildUserProfile() {
    return Container(
        padding: const EdgeInsets.all(10.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: Firestore.instance
              .collection('users')
              .where('target_shop', isEqualTo: userData['uid'])
              .snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) return new Text('Error: ${snapshot.error}');
            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
                return new Text('Loading...');
              default:
                return new ListView(
                  children:
                      snapshot.data.documents.map((DocumentSnapshot document) {
                    return Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: new ListTile(
                          onTap: () {
                            //Navigator.push(context, MaterialPageRoute(builder: (context)=> ShopPage(shopDetails: document, userDetails: userData,)));
                            _showModalAppointmentDetails(document);
                          },
                          leading: CircleAvatar(
                            backgroundColor: Colors.cyan,
                            child: Text(document['shopper_name'][0]
                                .toString()
                                .toUpperCase()),
                          ),
                          title: Text(document['shopper_name']),
                          subtitle: Text(document['appointment_status']),
                          trailing: IconButton(
                            icon: Icon(Icons.info),
                            onPressed: () {
                              print("Open");
                              _showModalAppointmentDetails(document);
                            },
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
            }
          },
        ));
  }

  Widget buildShopProfile() {
    return Container();
  }

  Widget buildBody() {
    print("WIDGET: " + widget.type.toString());
    if (currentPage == 0) {
      if (widget.type == "user") {
        return buildHomeUser();
      } else {
        return buildHomeShop();
      }
    } else if (currentPage == 1) {
      if (widget.type == "user") {
        return buildAppointmentsUser();
      } else {
        return buildPendingShop();
      }
    } else if (currentPage == 2) {
      if (widget.type == "user") {
        return buildAppointmentsDoneUser();
      } else {
        return buildCompletedShop();
      }
    } else {
      if (widget.type == "user") {
        return buildUserProfile();
      } else {
        return buildShopProfile();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(currentTitle),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.power_settings_new),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                  context,
                  new MaterialPageRoute(
                      builder: (context) =>
                      new LoginPage()),
                  ModalRoute.withName("/login"));
              print("Logging out");
            },
          )
        ],
      ),
      body:
          userLoaded ? buildBody() : Center(child: CircularProgressIndicator()),
      bottomNavigationBar: CubertoBottomBar(
        inactiveIconColor: Colors.white70,
        tabStyle: CubertoTabStyle.STYLE_FADED_BACKGROUND,
        // By default its CubertoTabStyle.STYLE_NORMAL
        selectedTab: currentPage,
        // By default its 0, Current page which is fetched when a tab is clickd, should be set here so as the change the tabs, and the same can be done if willing to programmatically change the tab.
        tabs: widget.type == "user"
            ? [
                TabData(
                  iconData: Icons.home,
                  title: "Nearby",
                  tabColor: Theme.of(context).accentColor,
                ),
                TabData(
                  iconData: Icons.access_time,
                  title: "Appointments",
                  tabColor: Theme.of(context).accentColor,
                ),
                TabData(
                    iconData: Icons.list,
                    title: "History",
                  tabColor: Theme.of(context).accentColor,
                ),
                TabData(
                    iconData: Icons.supervisor_account,
                    title: "Profile",
                  tabColor: Theme.of(context).accentColor,
                ),
              ]
            : [
                TabData(
                  iconData: Icons.access_time,
                  title: "Scheduled",
                  tabColor: Theme.of(context).accentColor,
                ),
                TabData(
                  iconData: Icons.av_timer,
                  title: "Pending",
                  tabColor: Theme.of(context).accentColor,
                ),
                TabData(
                  iconData: Icons.list,
                  title: "History",
                  tabColor: Theme.of(context).accentColor,
                ),
                TabData(
                    iconData: Icons.supervisor_account,
                    title: "Profile",
                  tabColor: Theme.of(context).accentColor,
                ),
              ],
        onTabChangedListener: (position, title, color) {
          setState(() {
            currentPage = position;
            currentTitle = title;
            currentColor = color;
          });
        },
      ),
    );
  }
}
