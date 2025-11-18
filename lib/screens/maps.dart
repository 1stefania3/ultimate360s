import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapsPage extends StatelessWidget {
  const MapsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
               initialCenter: LatLng(4.7110, -74.0721), // Bogotá
                initialZoom: 12.5,
            ),
            children: [
              TileLayer(
                 urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                 userAgentPackageName: 'com.example.app',
              ),
              
             MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(4.70, -74.07),
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.shopping_cart,
                      color: Colors.blue,
                      size: 35,
                    ),
                  ),
                  Marker(
                    point: LatLng(4.72, -74.05),
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.sports_soccer,
                      color: Colors.green,
                      size: 35,
                    ),
                  ),
                  Marker(
                    point: LatLng(4.68, -74.08),
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.event,
                      color: Colors.purple,
                      size: 35,
                    ),
                  ),
                ],
              ),
/*
              PolygonLayer(
                polygons: [
                  Polygon(
                    points: [
                       LatLng(4.73, -74.1),
                      LatLng(4.72, -74.05),
                      LatLng(4.69, -74.06),
                    ],
                    color: Colors.red.withOpacity(0.3),
                    borderColor: Colors.red,
                    borderStrokeWidth: 1,
                  ),
                  Polygon(
                    points: [
                       LatLng(4.73, -74.1),
                      LatLng(4.72, -74.05),
                      LatLng(4.69, -74.06),
                    ],
                    color: Colors.blue.withOpacity(0.3),
                    borderColor: Colors.blue,
                    borderStrokeWidth: 1,
                  ),
                ],
              ),
              */
            ],
          ),

         Positioned(
  top: 0,
  left: 0,
  right: 0,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        height: 100,
        width: double.infinity,
        //padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.4),
        ),
        alignment: Alignment.center,
        child: const Text(
          "¿Dónde estás hoy?",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 0, 0, 0),
          ),
        ),
      ),

      const SizedBox(height: 10),

      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: const [
            SizedBox(width: 10),
            FilterButton(text: "Tiendas", color: Colors.lightGreen),
            SizedBox(width: 10),
            FilterButton(text: "Canchas", color: Colors.lightGreen),
            SizedBox(width: 10),
            FilterButton(text: "Eventos", color: Colors.lightGreen),
            SizedBox(width: 10),
            FilterButton(text: "Hoteles", color: Colors.lightGreen),
            SizedBox(width: 10),
          ],
        ),
      ),
    ],
  ),
),

        ],
      ),
    );
  }
}

class FilterButton extends StatelessWidget {
  final String text;
  final Color color;

  const FilterButton({required this.text, required this.color, super.key});
 Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: () {},
      child: Text(
        text,
        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
    );
  }

  
  

}