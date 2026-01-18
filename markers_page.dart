import 'dart:async';
import 'dart:convert';
import 'dart:math' show cos, sqrt, asin;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart'; // Task 4: Step A
import 'package:flutter_polyline_points/flutter_polyline_points.dart'; // Task 4: Step B
import 'building_model.dart';

class MarkersPage extends StatefulWidget {
  const MarkersPage({super.key});

  @override
  State<MarkersPage> createState() => _MarkersPageState();
}

class _MarkersPageState extends State<MarkersPage> {
  late GoogleMapController mapController;
  Set<Marker> _markers = {};
  
  // Task 4 State Variables
  Position? _currentPosition;
  List<LatLng> polylineCoordinates = [];
  Map<PolylineId, Polyline> polylines = {};

  // Task 4 Step C: Custom Icons
  BitmapDescriptor? sourceIcon;
  BitmapDescriptor? destinationIcon;

  // Sila pastikan API Key anda aktif (Directions API & Maps SDK)
  final String googleApiKey = "AIzaSyBUrshHCtyLI9kGCWGCJ6KGzyI4Ipv4UzY";

  static const LatLng _mainEntrance = LatLng(1.853465, 103.086522);
  static const LatLng _libraryLocation = LatLng(1.857194, 103.081861);

  // Task 1: Dark Mode Style
  final String _darkMapStyle = '''
[
  { "elementType": "geometry", "stylers": [ { "color": "#242f3e" } ] },
  { "elementType": "labels.text.fill", "stylers": [ { "color": "#746855" } ] },
  { "elementType": "labels.text.stroke", "stylers": [ { "color": "#242f3e" } ] },
  { "featureType": "road", "elementType": "geometry", "stylers": [ { "color": "#38414e" } ] },
  { "featureType": "water", "elementType": "geometry", "stylers": [ { "color": "#17263c" } ] }
]
''';

  @override
  void initState() {
    super.initState();
    _loadBuildingsAndEntrance(); // Task 2
    _handleLocationPermission(); // Task 4 Step A
    _loadCustomIcons(); // Task 4 Step C
  }

  // --- TASK 4 STEP C: LOAD CUSTOM ICONS ---
  Future<void> _loadCustomIcons() async {
    sourceIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(30, 30)), 'assets/pin_start.png');
    destinationIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(30, 30)), 'assets/pin_end.png');
    setState(() {});
  }

  // --- TASK 4 STEP A: GEOLOCATOR PERMISSION ---
  Future<void> _handleLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      _currentPosition = await Geolocator.getCurrentPosition();
      setState(() {});
    }
  }

  // --- TASK 4 STEP B: NAVIGATE LOGIC ---
  void _navigateToNearest() async {
    if (_currentPosition == null) {
      _currentPosition = await Geolocator.getCurrentPosition();
    }

    LatLng userLoc = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    LatLng? nearestLoc;
    double minDistance = double.infinity;
    String buildingName = "";

    // Cari bangunan terdekat dari marker yang sedia ada
    for (var m in _markers) {
      double dist = _calculateDistance(userLoc, m.position);
      if (dist < minDistance) {
        minDistance = dist;
        nearestLoc = m.position;
        buildingName = m.infoWindow.title ?? "Building";
      }
    }

    if (nearestLoc != null) {
      PolylinePoints polylinePoints = PolylinePoints(apiKey: googleApiKey);
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        request: PolylineRequest(
          origin: PointLatLng(userLoc.latitude, userLoc.longitude),
          destination: PointLatLng(nearestLoc.latitude, nearestLoc.longitude),
          mode: TravelMode.driving,
        ),
      );

      if (result.points.isNotEmpty) {
        polylineCoordinates.clear();
        for (var point in result.points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }
        
        setState(() {
          // --- DI SINI PERUBAHAN WARNA KEPADA BIRU ---
          PolylineId id = const PolylineId("poly");
          polylines[id] = Polyline(
            polylineId: id,
            color: Colors.blue, // Ditukar dari merah ke biru
            points: polylineCoordinates,
            width: 6,
          );

          // Update markers with Custom Icons (Step C)
          _markers.add(Marker(
            markerId: const MarkerId('user_loc'),
            position: userLoc,
            icon: sourceIcon ?? BitmapDescriptor.defaultMarker,
            infoWindow: const InfoWindow(title: "You are here"),
          ));

          _markers.add(Marker(
            markerId: const MarkerId('target_dest'),
            position: nearestLoc!,
            icon: destinationIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            infoWindow: InfoWindow(title: "Dest: $buildingName"),
          ));
        });

        mapController.animateCamera(CameraUpdate.newLatLngZoom(nearestLoc, 15));
      }
    }
  }

  // Haversine formula (Task 3 Step C)
  double _calculateDistance(LatLng p1, LatLng p2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((p2.latitude - p1.latitude) * p) / 2 +
        c(p1.latitude * p) * c(p2.latitude * p) *
            (1 - c((p2.longitude - p1.longitude) * p)) / 2;
    return 12742 * asin(sqrt(a)); 
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    mapController.setMapStyle(_darkMapStyle);
  }

  // Task 2: Load JSON
  Future<void> _loadBuildingsAndEntrance() async {
    _markers.add(Marker(
      markerId: const MarkerId('entrance'),
      position: _mainEntrance,
      infoWindow: const InfoWindow(title: 'Main Entrance'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
    ));

    try {
      final String response = await rootBundle.loadString('assets/campus_data.json');
      final List<dynamic> data = json.decode(response);
      setState(() {
        for (var item in data) {
          final b = Building.fromJson(item);
          _markers.add(Marker(
            markerId: MarkerId(b.name),
            position: LatLng(b.lat, b.lng),
            infoWindow: InfoWindow(title: b.name, snippet: b.description),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
          ));
        }
      });
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1C1E),
      appBar: AppBar(
        title: const Text('UTHM Campus Explorer'),
        backgroundColor: const Color(0xFF1A1C1E),
        foregroundColor: Colors.white,
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: const CameraPosition(target: _mainEntrance, zoom: 16.0),
        markers: _markers,
        myLocationEnabled: true, // Step A: Blue Dot
        polylines: Set<Polyline>.of(polylines.values), // Step B: Polyline
        polygons: {
          Polygon(
            polygonId: const PolygonId('fsktm_zone'),
            points: const [
              LatLng(1.8610, 103.0840), LatLng(1.8610, 103.0850),
              LatLng(1.8595, 103.0850), LatLng(1.8595, 103.0840),
            ],
            strokeWidth: 2,
            strokeColor: Colors.blueAccent,
            fillColor: Colors.blueAccent.withOpacity(0.2),
          ),
        },
        circles: {
          Circle(
            circleId: const CircleId('library_zone'),
            center: _libraryLocation,
            radius: 200,
            strokeWidth: 2,
            strokeColor: Colors.redAccent,
            fillColor: Colors.redAccent.withOpacity(0.1),
          ),
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // BUTANG NAVIGATE (TASK 4 STEP B)
          FloatingActionButton.extended(
            onPressed: _navigateToNearest,
            label: const Text("Navigate"),
            icon: const Icon(Icons.directions),
            backgroundColor: Colors.blueAccent,
          ),
          const SizedBox(height: 12),
          // BUTANG BACK TO ENTRANCE (TASK 1)
          FloatingActionButton.extended(
            onPressed: () => mapController.animateCamera(CameraUpdate.newLatLngZoom(_mainEntrance, 17)),
            label: const Text("Back to Entrance"),
            icon: const Icon(Icons.home),
            backgroundColor: Colors.green.shade900,
          ),
        ],
      ),
    );
  }
}