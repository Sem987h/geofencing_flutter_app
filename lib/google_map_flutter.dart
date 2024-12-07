import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:native_geofence/native_geofence.dart';

class GoogleMapFlutter extends StatefulWidget {
  const GoogleMapFlutter({super.key});

  @override
  State<GoogleMapFlutter> createState() => _GoogleMapFlutterState();
}

class _GoogleMapFlutterState extends State<GoogleMapFlutter> {
  double? latitude;
  double? longitude;
  LatLng myLocation = const LatLng(23.0225, 72.5714); // Default location

  final List<Marker> _markers = <Marker>[];
  final Set<Circle> _circles = {}; // Set to store the circle
  GoogleMapController? _controller; // Controller to handle camera movement

  @override
  void initState() {
    super.initState();

    // Initialize geofence manager
    NativeGeofenceManager.instance.initialize();

    // Get user current location
    getUserCurrentLocation().then((value) {
      setState(() {
        latitude = value.latitude;
        longitude = value.longitude;
        myLocation = LatLng(value.latitude, value.longitude);

        // Move the camera to the user's current location
        _controller?.animateCamera(
          CameraUpdate.newLatLngZoom(myLocation, 15),
        );
      });
    });
  }

  Future<Position> getUserCurrentLocation() async {
    await Geolocator.requestPermission()
        .then((value) {})
        .onError((e, stackTrace) {
      log(e.toString());
    });

    return await Geolocator.getCurrentPosition();
  }

  void addGeofence(LatLng position) async {
    // final newGeofence = Geofence(
    //   id: 'geofence_${position.latitude}_${position.longitude}',
    //   location:
    //       Location(latitude: position.latitude, longitude: position.longitude),
    //   radiusMeters: 50,
    //   triggers: const {
    //     GeofenceEvent.enter,
    //     GeofenceEvent.exit,
    //     GeofenceEvent.dwell,
    //   },
    //   iosSettings: const IosGeofenceSettings(
    //     initialTrigger: true,
    //   ),
    //   androidSettings: const AndroidGeofenceSettings(
    //     initialTriggers: {GeofenceEvent.enter},
    //     expiration: Duration(days: 7),
    //     loiteringDelay: Duration(minutes: 5),
    //     notificationResponsiveness: Duration(minutes: 5),
    //   ),
    // );

    try {
      NativeGeofenceManager.instance;
      log("Geofence added at ${position.latitude}, ${position.longitude}");
    } catch (e) {
      log("Error adding geofence: $e");
    }

    // Add a circle around the marker (representing the geofence area)
    setState(() {
      _circles.add(
        Circle(
          circleId: CircleId(position.toString()),
          center: position,
          radius: 50,
          strokeWidth: 2,
          strokeColor: Colors.blue.withOpacity(0.5),
          fillColor: Colors.blue.withOpacity(0.2),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Google Map",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              "Latitude - ${_markers.isNotEmpty ? _markers.first.position.latitude : latitude} \nLongitude - ${_markers.isNotEmpty ? _markers.first.position.longitude : longitude}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                _controller = controller;
              },
              initialCameraPosition: CameraPosition(
                target: myLocation,
                zoom: 15,
              ),
              markers: Set<Marker>.of(_markers),
              circles: _circles, // Add circles to the map
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onTap: (LatLng position) {
                setState(() {
                  // Clear previous markers and circles
                  _markers.clear();
                  _circles.clear();

                  // Add marker to the map
                  _markers.add(
                    Marker(
                      markerId: MarkerId(position.toString()),
                      position: position,
                      infoWindow: InfoWindow(
                        title: "Geofence Location",
                        snippet:
                            "Lat: ${position.latitude}, Lng: ${position.longitude}",
                      ),
                    ),
                  );
                });

                // Add geofence and circle at tapped location
                addGeofence(position);
              },
            ),
          ),
        ],
      ),
    );
  }
}
