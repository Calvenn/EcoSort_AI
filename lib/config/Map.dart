import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatelessWidget {
  final List<Map<String, dynamic>> recyclingCenters = [
    {'name': 'Penang Green Centre', 'lat': 5.4141, 'lng': 100.3288},
    {'name': 'Jelutong Recycling Station', 'lat': 5.3890, 'lng': 100.3170},
    {'name': 'Farlim Recycle Bin Station', 'lat': 5.4045, 'lng': 100.2850},
    {'name': 'USM Recycling Point', 'lat': 5.3560, 'lng': 100.3010},
    {'name': 'Bayan Baru Community Center', 'lat': 5.3360, 'lng': 100.3050},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[200],
        title: Row(
          children: [
            Icon(Icons.map, color: Colors.green),
            Text('  Recycling Centers'),
          ],
        ),
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(5.39, 100.31),
          initialZoom: 12.5,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'com.example.ecosort',
          ),
          MarkerLayer(
            markers: recyclingCenters.map((center) {
              return Marker(
                point: LatLng(center['lat'], center['lng']),
                width: 50,
                height: 50,
                child: Tooltip(
                  message: center['name'],
                  child: Icon(Icons.location_on, color: Colors.green, size: 40),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
