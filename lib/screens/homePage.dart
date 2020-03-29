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
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:jiffy/jiffy.dart';

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
  String userUID;

  bool userLoaded = false;
  bool timeSlotsLoaded = false;

  DocumentSnapshot userData;

  String token;

  GeoHasher gH = GeoHasher();

  TextEditingController startTimeController = new TextEditingController();
  TextEditingController endTimeController = new TextEditingController();
  TextEditingController otpController = new TextEditingController();
  TextEditingController _dataController = TextEditingController();

  List<String> timeSlots;

  @override
  void dispose() {
    startTimeController.dispose();
    endTimeController.dispose();
    otpController.dispose();
    _dataController.dispose();
    super.dispose();
  }

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
    if (userType == "shops"){
      updateTimeSlots();
    }
  }

  List<String> calculateFilter() {
    if (widget.type == "user" && userLoaded) {
      double addLat = userData['lat'];
      double addLon = userData['lon'];
      print(addLat);
      print(addLon);
      num queryDistance = 1000.round();

      final Distance distance = const Distance();
      //final num query_distance = (EARTH_RADIUS * PI / 4).round();

      final p1 = new LatLng(addLat, addLon);
      final upperP = distance.offset(p1, queryDistance, 45);
      final lowerP = distance.offset(p1, queryDistance, 220);

      print(upperP);
      print(lowerP);

      GeoHasher geoHasher = GeoHasher();

      String lower = geoHasher.encode(lowerP.longitude, lowerP.latitude);
      String upper = geoHasher.encode(upperP.longitude, upperP.latitude);

      List<String> upperLower = [];
      upperLower.add(upper);
      upperLower.add(lower);
      return upperLower;
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

  String getCity(String address){
    List<String> elements = address.split(',');
    String city = elements[elements.length - 3];
    return city.trim();
  }

  getIntervals(String st, String et){
    List<String> start = st.split(':');
    List<String> end = et.split(':');

    int start_hour = int.parse(start[0]);
    int start_minute = int.parse(start[1]);
    int end_hour = int.parse(end[0]);
    int end_minute = int.parse(end[1]);

    Jiffy start_time = Jiffy({
      "hour" : start_hour,
      "minute": start_minute
    });

    Jiffy end_time = Jiffy({
      "hour" : end_hour,
      "minute": end_minute
    });

    int current_hour = 0;
    int current_minute = 0;

    List<String> slots = [];
    Jiffy previous_time = start_time;

    while(previous_time.isBefore(end_time)){
      Jiffy temp_time = new Jiffy(previous_time);
      Jiffy new_time = Jiffy(temp_time.add(duration: Duration(minutes: 15)));
      current_hour = new_time.hour;
      current_minute = new_time.minute;
      slots.add(previous_time.format("HH:mm") + "--" + new_time.format("HH:mm"));
      previous_time = new_time;
    }
    // print(slots);
    return slots;
  }


  updateTimeSlots() async {
    print(getCity(userData['shop_address']));
    Firestore.instance.collection('cities')
        .where('city', isEqualTo: getCity(userData['shop_address']))
        .getDocuments()
        .then((docs) async {
          if(docs.documents.isEmpty){
            print("empty");
            String start_time = "04:00";
            String end_time = "21:00";
            timeSlots = getIntervals(start_time, end_time);
            setState(() {
              timeSlots = getIntervals(start_time, end_time);
            });
          } else {
            String start_time = docs.documents[0]['start_time'];
            String end_time = docs.documents[0]['end_time'];
            timeSlots = getIntervals(start_time, end_time);
            setState(() {
              timeSlots = getIntervals(start_time, end_time);
              timeSlotsLoaded = true;
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

  String distanceBetween(String shopGeoHash) {
    String userGeoHash = userData['geohash'];
    GeoHasher geoHasher = GeoHasher();
    List<double> shopCoordinates = geoHasher.decode(shopGeoHash);
    List<double> userCoordinates = geoHasher.decode(userGeoHash);
    print(userCoordinates);
    Distance distance = new Distance();
    double meter = distance(
        new LatLng(shopCoordinates[1], shopCoordinates[0]),
        new LatLng(userCoordinates[1], userCoordinates[0]));
    return meter.round().toString();
  }

  List<DocumentSnapshot> filterByDistance(List<DocumentSnapshot> allDocs) {
    List<DocumentSnapshot> toReturn = [];
    for (var i = 0; i < allDocs.length; i++) {
      if (double.parse(distanceBetween(allDocs[i]['shop_geohash'])) < 1000) {
        toReturn.add(allDocs[i]);
      } else {
        // do nothing
      }
    }
    return toReturn;
  }

  Widget buildHomeUser() {
    List<String> upperLower = calculateFilter();
    String upper = upperLower[0];
    String lower = upperLower[1];

    return Container(
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
                return new Center(
                  child: CircularProgressIndicator(
                    backgroundColor: Theme.of(context).accentColor,
                  ),
                );
              default:
                List<DocumentSnapshot> filterList = new List();
                filterList = filterByDistance(snapshot.data.documents);
                if(filterList.length<1) {
                  return Center(
                    child: Text(
                      "There are no shops around you."
                    ),
                  );
                }
                else {
                  return new Container(
                      child: ListView.builder(
                          itemCount: filterList.length,
                          itemBuilder: (BuildContext ctxt, int index) {
                            var document = filterList[index];
                            return Card(
                              margin: EdgeInsets.all(10.0),
                              elevation: 2,
                              child: Container(
                                child: new ListTile(
                                  contentPadding: EdgeInsets.all(8),
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => ShopPage(
                                              shopDetails: document,
                                              userDetails: userData,
                                            )));
                                  },
                                  leading: Container(
                                    padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                                    child: CircleAvatar(
                                      backgroundColor: Theme.of(context).accentColor,
                                      child: Text(document['shop_name'][0]
                                          .toString()
                                          .toUpperCase()),
                                    ),
                                  ),
                                  title: Text(document['shop_name']),
                                  subtitle: Text(
                                    distanceBetween(document['shop_geohash']) +
                                        " meters away",
                                  ),
                                  trailing: IconButton(
                                    padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
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
                          }
                      )
                  );
                }
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
                                                          Theme.of(context).accentColor,
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
                                                          Theme.of(context).accentColor,
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
                                                          Theme.of(context).accentColor,
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
        child: StreamBuilder<QuerySnapshot>(
          stream: Firestore.instance
              .collection('appointments')
              .where('appointment_status', whereIn: status)
              .where('shopper_uid', isEqualTo: userUID)
              .snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) return new Text('Error: ${snapshot.error}');
            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
                return new Center(
                  child: CircularProgressIndicator(
                    backgroundColor: Theme.of(context).accentColor,
                  ),
                );
              default:
                List<DocumentSnapshot> documents = new List();
                documents = (snapshot.data.documents);
                if(documents.length<1) {
                  return Center(
                    child: Text(
                        "You currently have no appointments."
                    ),
                  );
                }
                else {
                  return new Container(
                      child: ListView.builder(
                          itemCount: documents.length,
                          itemBuilder: (BuildContext ctxt, int index) {
                            DocumentSnapshot document = documents[index];
                            return Card(
                              margin: EdgeInsets.all(10.0),
                              elevation: 2,
                              child: Container(
                                child: new ListTile(
                                  contentPadding: EdgeInsets.all(8),
                                  onTap: () {
                                    _showModalAppointmentDetails(document);

                                    // Navigator.push(context, MaterialPageRoute(builder: (context)=> ShopPage(shopDetails: document, userDetails: userData,)));
                                  },
                                  leading: Container(
                                    padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                                    child: CircleAvatar(
                                      backgroundColor: Theme.of(context).accentColor,
                                      child: Text(document['shop_name'][0]
                                          .toString()
                                          .toUpperCase()),
                                    ),
                                  ),
                                  title: Text(document['shop_name']),
                                  subtitle: Text(document['appointment_status']),
                                  trailing: IconButton(
                                    padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
                                    icon: Icon(Icons.info),
                                    onPressed: () {
                                      print("Open");
                                      _showModalAppointmentDetails(document);
                                    },
                                  ),
                                ),
                              ),
                            );
                          }
                      )
                  );
                }
            }
          },
        ));
  }

  Widget buildAppointmentsDoneUser() {
    return Container(
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
                return new Center(
                  child: CircularProgressIndicator(
                    backgroundColor: Theme.of(context).accentColor,
                  ),
                );
              default:
                List<DocumentSnapshot> documents = new List();
                documents = (snapshot.data.documents);
                if(documents.length<1) {
                  return Center(
                    child: Text(
                        "You have never booked an appointment."
                    ),
                  );
                }
                else {
                  return new Container(
                      child: ListView.builder(
                          itemCount: documents.length,
                          itemBuilder: (BuildContext ctxt, int index) {
                            DocumentSnapshot document = documents[index];
                            return Card(
                              margin: EdgeInsets.all(10.0),
                              elevation: 2,
                              child: Container(
                                child: new ListTile(
                                  contentPadding: EdgeInsets.all(8),
                                  onTap: () {
                                    _showModalAppointmentDetails(document);
                                    //Navigator.push(context, MaterialPageRoute(builder: (context)=> ShopPage(shopDetails: document, userDetails: userData,)));
                                  },
                                  leading: Container(
                                    padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                                    child: CircleAvatar(
                                      backgroundColor: Theme.of(context).accentColor,
                                      child: Text(document['shop_name'][0]
                                          .toString()
                                          .toUpperCase()),
                                    ),
                                  ),
                                  title: Text(document['shop_name']),
                                  subtitle: Text(document['appointment_status']),
                                  trailing: IconButton(
                                    padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
                                    icon: Icon(Icons.info),
                                    onPressed: () {
                                      print("Open");
                                      _showModalAppointmentDetails(document);
                                    },
                                  ),
                                ),
                              ),
                            );
                          }
                      )
                  );
                }
            }
          },
        ));
  }

  Widget buildHomeShop() {
    return Container(
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
                return new Center(
                  child: CircularProgressIndicator(
                    backgroundColor: Theme.of(context).accentColor,
                  ),
                );
              default:
                List<DocumentSnapshot> documents = new List();
                documents = (snapshot.data.documents);
                if(documents.length<1) {
                  return Center(
                    child: Text(
                        "You have no scheduled appointments."
                    ),
                  );
                }
                else {
                  return new Container(
                      child: ListView.builder(
                          itemCount: documents.length,
                          itemBuilder: (BuildContext ctxt, int index) {
                            DocumentSnapshot document = documents[index];
                            return Card(
                              margin: EdgeInsets.all(10.0),
                              elevation: 2,
                              child: Container(
                                child: new ListTile(
                                  contentPadding: EdgeInsets.all(8),
                                  onTap: () {
                                    _showCompleteDialog(
                                        context, document.documentID, document['otp']);
                                    //Navigator.push(context, MaterialPageRoute(builder: (context)=> ShopPage(shopDetails: document, userDetails: userData,)));
                                  },
                                  leading: Container(
                                      padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                                      child: CircleAvatar(
                                      backgroundColor: Theme.of(context).accentColor,
                                      child: Text(document['shopper_name'][0]
                                          .toString()
                                          .toUpperCase()),
                                    )
                                  ),
                                  title: Text(document['shopper_name']),
                                  subtitle: Text(document['appointment_status']),
                                  trailing: IconButton(
                                    padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
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
                          }
                      )
                  );
                }
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
                return new Center(
                  child: CircularProgressIndicator(
                    backgroundColor: Theme.of(context).accentColor,
                  ),
                );
              default:
                List<DocumentSnapshot> documents = new List();
                documents = (snapshot.data.documents);
                if(documents.length<1) {
                  return Center(
                    child: Text(
                        "You have no appointment requests."
                    ),
                  );
                }
                else {
                  return new Container(
                      child: ListView.builder(
                          itemCount: documents.length,
                          itemBuilder: (BuildContext ctxt, int index) {
                            DocumentSnapshot document = documents[index];
                            return Card(
                              margin: EdgeInsets.all(10.0),
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: new ListTile(
                                  contentPadding: EdgeInsets.all(8),
                                  onTap: () async {
                                    String startTime;
                                    String endTime;
                                    String value_drop;
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
                                                                              timeSlotsLoaded ?
                                                                              Card(
                                                                                elevation: 2,
                                                                                child: ListTile(
                                                                                  title: Text("Select time slot"),
                                                                                  subtitle: DropdownButton<String>(
                                                                                    items: timeSlots.map((String value) {
                                                                                      return new DropdownMenuItem<String>(
                                                                                        value: value,
                                                                                        child: new Text(value),
                                                                                      );
                                                                                    }).toList(),
                                                                                    onChanged: (_) {
                                                                                      value_drop = _;
                                                                                      setStateSheet(() {
                                                                                        value_drop = _;
                                                                                        startTimeController.text = value_drop.split('--')[0];
                                                                                        endTimeController.text = value_drop.split('--')[1];
                                                                                      });
                                                                                    },
                                                                                  ),
                                                                                ),
                                                                              )
                                                                              : Container(),
                                                                              Center(
                                                                                child:
                                                                                RaisedButton(
                                                                                  color: Colors
                                                                                      .cyan,
                                                                                  child: Text(
                                                                                      "Confirm"),
                                                                                  onPressed:
                                                                                      () {
                                                                                    startTime = value_drop.split('--')[0];
                                                                                    endTime = value_drop.split('--')[1];
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
                                    backgroundColor: Theme.of(context).accentColor,
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
                          }
                      )
                  );
                }
            }
          },
        ));
  }

  Widget buildCompletedShop() {
    return Container(
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
                return new Center(
                  child: CircularProgressIndicator(
                    backgroundColor: Theme.of(context).accentColor,
                  ),
                );
              default:
                List<DocumentSnapshot> documents = new List();
                documents = (snapshot.data.documents);
                if(documents.length<1) {
                  return Center(
                    child: Text(
                        "You have never accepted an appointment."
                    ),
                  );
                }
                else {
                  return new Container(
                      child: ListView.builder(
                          itemCount: documents.length,
                          itemBuilder: (BuildContext ctxt, int index) {
                            DocumentSnapshot document = documents[index];
                            return Card(
                              margin: EdgeInsets.all(10.0),
                              elevation: 2,
                              child: Container(
                                child: new ListTile(
                                  contentPadding: EdgeInsets.all(8),
                                  onTap: () {
                                    //Navigator.push(context, MaterialPageRoute(builder: (context)=> ShopPage(shopDetails: document, userDetails: userData,)));
                                    _showModalAppointmentDetails(document);
                                  },
                                  leading: Container(
                                    padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                                    child: CircleAvatar(
                                      backgroundColor: Theme.of(context).accentColor,
                                      child: Text(document['shopper_name'][0]
                                          .toString()
                                          .toUpperCase()),
                                    ),
                                  ),
                                  title: Text(document['shopper_name']),
                                  subtitle: Text(document['appointment_status']),
                                  trailing: IconButton(
                                    padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
                                    icon: Icon(Icons.info),
                                    onPressed: () {
                                      print("Open");
                                      _showModalAppointmentDetails(document);
                                    },
                                  ),
                                ),
                              ),
                            );
                          }
                      )
                  );
                }
            }
          },
        ));
  }


  _showModalEditUserData(String dataType, String oldData) async {
    _dataController.text = oldData;
    String newData = "";
    String result = await showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateSheet) =>
              AlertDialog(
                title: Text(
                    'Change your $dataType'),
                content: TextField(
                  controller: _dataController,
                  cursorColor: Theme.of(context).accentColor,
                ),
                actions: <Widget>[
                  FlatButton(
                    child: Text(
                      'Save',
                      style:
                      TextStyle(
                        color: Theme.of(context).accentColor),
                    ),
                    onPressed: () async {
                      if(_dataController.text!=oldData){
                        // Data changed
                        newData = _dataController.text;
                      }
                      Navigator.of(context).pop();
                    },
                  ),
                  FlatButton(
                    child: Text(
                      'Cancel',
                      style:
                      TextStyle(
                          color: Theme.of(context).accentColor),
                    ),
                    onPressed: () async {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              )
        ));
    return newData;
  }

  Widget buildUserProfile() {
    return Container(
        child: FutureBuilder<DocumentSnapshot>(
          future: Firestore.instance
              .collection('users')
              .document(userData['uid'])
            .get(),
          builder:
              (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
            if (snapshot.hasError) return new Text('Error: ${snapshot.error}');
            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
                return new Center(
                  child: CircularProgressIndicator(
                    backgroundColor: Theme.of(context).accentColor,
                  ),
                );
              default:
                DocumentSnapshot document = snapshot.data;
                return new ListView(
                  children: [
                    Card(
                      margin: EdgeInsets.all(10.0),
                      elevation: 2,
                      child: Container(
                        child: new ListTile(
                          contentPadding: EdgeInsets.all(8),
                          onTap: () async {
                            var newData = await _showModalEditUserData("Name", document['name']);
                            if(newData!="") {
                              Firestore.instance.collection('users').document(userData['uid']).updateData({'name':newData});
                              setState(() {});
                            }
                          },
                          leading: Container(
                            padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                            child: CircleAvatar(
                              backgroundColor: Theme.of(context).accentColor,
                              child: Text("N"
                                  .toString()
                                  .toUpperCase()),
                            ),
                          ),
                          title: Text("Name"),
                          subtitle: Text(snapshot.data['name']),
                          trailing: IconButton(
                            padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
                            icon: Icon(Icons.edit),
                            onPressed: () async {
                              var newData = await _showModalEditUserData("Name", document['name']);
                              if(newData!="") {
                                Firestore.instance.collection('users').document(userData['uid']).updateData({'name':newData});
                                setState(() {});
                              }
                            },
                          ),
                        ),
                      ),
                    ),

                    Card(
                      margin: EdgeInsets.all(10.0),
                      elevation: 2,
                      child: Container(
                        child: new ListTile(
                          contentPadding: EdgeInsets.all(8),
                          onTap: () async {
                          },
                          leading: Container(
                            padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                            child: CircleAvatar(
                              backgroundColor: Theme.of(context).accentColor,
                              child: Text("P"
                                  .toString()
                                  .toUpperCase()),
                            ),
                          ),
                          title: Text("Phone Number"),
                          subtitle: Text(snapshot.data['phone_number']),
                          trailing: IconButton(
                            padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
                            icon: Icon(Icons.edit),
                            onPressed: () async {
                            },
                          ),
                        ),
                      ),
                    ),

                    Card(
                      margin: EdgeInsets.all(10.0),
                      elevation: 2,
                      child: Container(
                        child: new ListTile(
                          contentPadding: EdgeInsets.all(8),
                          onTap: () async {
                            var newData = await _showModalEditUserData("Address", document['address']);
                            if(newData!="") {
                              Firestore.instance.collection('users').document(userData['uid']).updateData({'address':newData});
                              setState(() {});
                            }
                          },
                          leading: Container(
                            padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                            child: CircleAvatar(
                              backgroundColor: Theme.of(context).accentColor,
                              child: Text("A"
                                  .toString()
                                  .toUpperCase()),
                            ),
                          ),
                          title: Text("Your Address"),
                          subtitle: Text(snapshot.data['address']),
                          trailing: IconButton(
                            padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
                            icon: Icon(Icons.edit),
                            onPressed: () async {
                              var newData = await _showModalEditUserData("Address", document['address']);
                              if(newData!="") {
                                Firestore.instance.collection('users').document(userData['uid']).updateData({'address':newData});
                                setState(() {});
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ]
                );
            }
          },
        ));
  }

  Widget buildShopProfile() {
    return Container(
        child: FutureBuilder<DocumentSnapshot>(
          future: Firestore.instance
              .collection('shops')
              .document(userData['uid'])
              .get(),
          builder:
              (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
            if (snapshot.hasError) return new Text('Error: ${snapshot.error}');
            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
                return new Center(
                  child: CircularProgressIndicator(
                    backgroundColor: Theme.of(context).accentColor,
                  ),
                );
              default:
                DocumentSnapshot document = snapshot.data;
                return new ListView(
                    children: [
                      Card(
                        margin: EdgeInsets.all(10.0),
                        elevation: 2,
                        child: Container(
                          child: new ListTile(
                            contentPadding: EdgeInsets.all(8),
                            onTap: () async {
                              var newData = await _showModalEditUserData("Shop Name", document['shop_name']);
                              if(newData!="") {
                                Firestore.instance.collection('shops').document(userData['uid']).updateData({'shop_name':newData});
                                setState(() {});
                              }
                            },
                            leading: Container(
                              padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                              child: CircleAvatar(
                                backgroundColor: Theme.of(context).accentColor,
                                child: Text("N"
                                    .toString()
                                    .toUpperCase()),
                              ),
                            ),
                            title: Text("Shop Name"),
                            subtitle: Text(snapshot.data['shop_name']),
                            trailing: IconButton(
                              padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
                              icon: Icon(Icons.edit),
                              onPressed: () async {
                                var newData = await _showModalEditUserData("Shop Name", document['shop_name']);
                                if(newData!="") {
                                  Firestore.instance.collection('shops').document(userData['uid']).updateData({'shop_name':newData});
                                  setState(() {});
                                }
                              },
                            ),
                          ),
                        ),
                      ),

                      Card(
                        margin: EdgeInsets.all(10.0),
                        elevation: 2,
                        child: Container(
                          child: new ListTile(
                            contentPadding: EdgeInsets.all(8),
                            onTap: () async {
                              var newData = await _showModalEditUserData("Your Name", document['shop_contact_name']);
                              if(newData!="") {
                                Firestore.instance.collection('shops').document(userData['uid']).updateData({'shop_contact_name':newData});
                                setState(() {});
                              }
                            },
                            leading: Container(
                              padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                              child: CircleAvatar(
                                backgroundColor: Theme.of(context).accentColor,
                                child: Text("N"
                                    .toString()
                                    .toUpperCase()),
                              ),
                            ),
                            title: Text("Your Name"),
                            subtitle: Text(snapshot.data['shop_contact_name']),
                            trailing: IconButton(
                              padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
                              icon: Icon(Icons.edit),
                              onPressed: () async {
                                var newData = await _showModalEditUserData("Your Name", document['shop_contact_name']);
                                if(newData!="") {
                                  Firestore.instance.collection('shops').document(userData['uid']).updateData({'shop_contact_name':newData});
                                  setState(() {});
                                }
                              },
                            ),
                          ),
                        ),
                      ),

                      Card(
                        margin: EdgeInsets.all(10.0),
                        elevation: 2,
                        child: Container(
                          child: new ListTile(
                            contentPadding: EdgeInsets.all(8),
                            onTap: () async {
                            },
                            leading: Container(
                              padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                              child: CircleAvatar(
                                backgroundColor: Theme.of(context).accentColor,
                                child: Text("P"
                                    .toString()
                                    .toUpperCase()),
                              ),
                            ),
                            title: Text("Phone Number"),
                            subtitle: Text(snapshot.data['phone_number']),
                            trailing: IconButton(
                              padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
                              icon: Icon(Icons.edit),
                              onPressed: () async {
                              },
                            ),
                          ),
                        ),
                      ),

                      Card(
                        margin: EdgeInsets.all(10.0),
                        elevation: 2,
                        child: Container(
                          child: new ListTile(
                            contentPadding: EdgeInsets.all(8),
                            onTap: () async {
                              var newData = await _showModalEditUserData("Shop Address", document['shop_address']);
                              if(newData!="") {
                                Firestore.instance.collection('shops').document(userData['uid']).updateData({'shop_address':newData});
                                setState(() {});
                              }
                            },
                            leading: Container(
                              padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                              child: CircleAvatar(
                                backgroundColor: Theme.of(context).accentColor,
                                child: Text("A"
                                    .toString()
                                    .toUpperCase()),
                              ),
                            ),
                            title: Text("Your Address"),
                            subtitle: Text(snapshot.data['shop_address']),
                            trailing: IconButton(
                              padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
                              icon: Icon(Icons.edit),
                              onPressed: () async {
                                var newData = await _showModalEditUserData("Shop Address", document['shop_address']);
                                if(newData!="") {
                                  Firestore.instance.collection('shops').document(userData['uid']).updateData({'shop_address':newData});
                                  setState(() {});
                                }
                              },
                            ),
                          ),
                        ),
                      ),

                      Card(
                        margin: EdgeInsets.all(10.0),
                        elevation: 2,
                        child: Container(
                          child: new ListTile(
                            contentPadding: EdgeInsets.all(8),
                            onTap: () async {
                              var newData = await _showModalEditUserData("Shop GST", document['shop_GST']);
                              if(newData!="") {
                                Firestore.instance.collection('shops').document(userData['uid']).updateData({'shop_GST':newData});
                                setState(() {});
                              }
                            },
                            leading: Container(
                              padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                              child: CircleAvatar(
                                backgroundColor: Theme.of(context).accentColor,
                                child: Text("G"
                                    .toString()
                                    .toUpperCase()),
                              ),
                            ),
                            title: Text("Shop GST"),
                            subtitle: Text(snapshot.data['shop_GST']!=""?snapshot.data['shop_GST']:"Not Entered"),
                            trailing: IconButton(
                              padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
                              icon: Icon(Icons.edit),
                              onPressed: () async {
                                var newData = await _showModalEditUserData("Shop GST", document['shop_GST']);
                                if(newData!="") {
                                  Firestore.instance.collection('shops').document(userData['uid']).updateData({'shop_GST':newData});
                                  setState(() {});
                                }
                              },
                            ),
                          ),
                        ),
                      ),

                      Card(
                        margin: EdgeInsets.all(10.0),
                        elevation: 2,
                        child: Container(
                          child: new ListTile(
                            contentPadding: EdgeInsets.all(8),
                            onTap: () async {
                              var newData = await _showModalEditUserData("Limit", document['limit'].toString());
                              if(newData!="") {
                                Firestore.instance.collection('shops').document(userData['uid']).updateData({'limit':int.parse(newData)});
                                setState(() {});
                              }
                            },
                            leading: Container(
                              padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                              child: CircleAvatar(
                                backgroundColor: Theme.of(context).accentColor,
                                child: Text("L"
                                    .toString()
                                    .toUpperCase()),
                              ),
                            ),
                            title: Text("Your Limit"),
                            subtitle: Text(snapshot.data['limit'].toString()),
                            trailing: IconButton(
                              padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
                              icon: Icon(Icons.edit),
                              onPressed: () async {
                                var newData = await _showModalEditUserData("Limit", document['limit'].toString());
                                if(newData!="") {
                                  Firestore.instance.collection('shops').document(userData['uid']).updateData({'limit':int.parse(newData)});
                                  setState(() {});
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ]
                );
            }
          },
        ));
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
          });
        },
      ),
    );
  }
}
