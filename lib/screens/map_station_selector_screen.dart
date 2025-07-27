import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/station_provider.dart';

class MapStationSelectorScreen extends StatelessWidget {
  const MapStationSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<StationProvider>();

    final markers = prov.stations
        .where((s) => s.latitude != null && s.longitude != null)
        .map<Marker>(
          (s) => Marker(
            point: LatLng(s.latitude!, s.longitude!),
            width: 45,
            height: 45,
            child: GestureDetector(
              onTap: () => prov.selectStation(s),
              child: const Icon(Icons.location_on,
                  color: Colors.redAccent, size: 40),
            ),
          ),
        )
        .toList();

    final initCenter = prov.userLatLng ?? const LatLng(62.0, 15.0);
    final initZoom = prov.userLatLng != null ? 8.5 : 4.8;

    return Scaffold(
      appBar: AppBar(title: const Text('Välj station på karta')),
      body: prov.stations.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              options: MapOptions(
                initialCenter: initCenter,
                initialZoom: initZoom,
                maxZoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.wf3_app',
                ),
                MarkerClusterLayerWidget(
                  options: MarkerClusterLayerOptions(
                    markers: markers,
                    maxClusterRadius: 50,
                    size: const Size(40, 40),
                    builder: (context, clusterMarkers) => Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${clusterMarkers.length}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: prov.selected == null
          ? null
          : FloatingActionButton.extended(
              icon: const Icon(Icons.check),
              label: Text(prov.selected!.name),
              onPressed: () => Navigator.pop(context),
            ),
    );
  }
}
