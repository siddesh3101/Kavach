import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:easy_geofencing/easy_geofencing.dart';
import 'package:easy_geofencing/enums/geofence_status.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kavach/cameraScreen.dart';
import 'package:location/location.dart' as location;
import 'package:meta/meta.dart';
import 'dart:convert';

class GeoFencing extends StatefulWidget {
  GeoFencing({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  _GeoFencingState createState() => _GeoFencingState();
}

class _GeoFencingState extends State<GeoFencing> {
  TextEditingController latitudeController = new TextEditingController();
  TextEditingController longitudeController = new TextEditingController();
  TextEditingController radiusController = new TextEditingController();
  location.Location loc = location.Location();
  StreamSubscription<GeofenceStatus>? geofenceStatusStream;
  Geolocator geolocator = Geolocator();
  String geofenceStatus = '';
  bool isReady = false;
  Position? position;
  @override
  void initState() {
    super.initState();
    getCurrentPosition();
    try {
      startSendingLocation();
    } catch (e) {
      print(e);
    }
  }

  getCurrentPosition() async {
    position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    print("LOCATION => ${position!.toJson()}");
    isReady = (position != null) ? true : false;
  }

  Future<void> sendLocationToApi(location.LocationData locationData) async {
    // String apiUrl = 'http://<ip_address_daalo_apnaa>/sample';
    String apiUrl = "https://playful-leeward-close.glitch.me/kavach2";
    Map<String, dynamic> requestBody = {
      'latitude': locationData.latitude.toString(),
      'longitude': locationData.longitude.toString(),
    };
    // http.Response response =

    await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(requestBody),
    );
    // print(response.body); // Optional: print the response from the API
  }

  setLocation() async {
    await getCurrentPosition();
    // print("POSITION => ${position!.toJson()}");
    latitudeController =
        TextEditingController(text: position!.latitude.toString());
    longitudeController =
        TextEditingController(text: position!.longitude.toString());
  }

  void startSendingLocation() {
    Timer.periodic(Duration(seconds: 5), (Timer timer) async {
      location.LocationData locationData = await loc.getLocation();
      await sendLocationToApi(locationData);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: Text(widget.title!),
        actions: [
          IconButton(
            icon: Icon(Icons.my_location),
            onPressed: () {
              if (isReady) {
                setState(() {
                  setLocation();
                });
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: latitudeController,
              decoration: InputDecoration(
                  border: InputBorder.none, hintText: 'Enter pointed latitude'),
            ),
            TextField(
              controller: longitudeController,
              decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Enter pointed longitude'),
            ),
            TextField(
              controller: radiusController,
              decoration: InputDecoration(
                  border: InputBorder.none, hintText: 'Enter radius in meter'),
            ),
            SizedBox(
              height: 60,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final camera = await availableCameras();
                    print(camera.first);
                    var firstCamera = camera.first;
                    // ignore: use_build_context_synchronously
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CameraScreen(camera: firstCamera),
                      ),
                    );
                  },
                  child: const Text("Camera"),
                ),
                SizedBox(
                  width: 10.0,
                ),
                ElevatedButton(
                  child: Text("Start"),
                  onPressed: () async {
                    print("starting geoFencing Service");
                    EasyGeofencing.startGeofenceService(
                        pointedLatitude: latitudeController.text,
                        pointedLongitude: longitudeController.text,
                        radiusMeter: radiusController.text,
                        eventPeriodInSeconds: 5);
                    location.LocationData locationData =
                        await loc.getLocation();
                    await sendLocationToApi(locationData);
                    // startSendingLocation();
                    try {
                      location.LocationData locationData =
                          await loc.getLocation();
                      await sendLocationToApi(locationData);
                    } catch (e) {
                      print("Errrrorrrr: ${e}");
                    }
                    if (geofenceStatusStream == null) {
                      geofenceStatusStream = EasyGeofencing.getGeofenceStream()!
                          .listen((GeofenceStatus status) {
                        // print(status.toString());
                        setState(() {
                          geofenceStatus = status.toString();
                        });
                      });
                    }
                  },
                ),
                SizedBox(
                  width: 10.0,
                ),
                ElevatedButton(
                  child: Text("Stop"),
                  onPressed: () {
                    print("stop");
                    EasyGeofencing.stopGeofenceService();
                    geofenceStatusStream!.cancel();
                  },
                ),
              ],
            ),
            SizedBox(
              height: 100,
            ),
            Text(
              "Geofence Status: \n\n\n" + geofenceStatus,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    latitudeController.dispose();
    longitudeController.dispose();
    radiusController.dispose();
    super.dispose();
  }
}
