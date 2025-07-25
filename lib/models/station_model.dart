/// Metadata för en mätstation.
///
/// * latitude/longitude kan saknas eller komma som strängar.
/// * Vi tolkar både `lat/lon` och `latitude/longitude`.
class Station {
  final String id;
  final String name;
  final double? latitude;
  final double? longitude;

  const Station({
    required this.id,
    required this.name,
    this.latitude,
    this.longitude,
  });

  factory Station.fromJson(Map<String, dynamic> json) => Station(
        id: json['key'].toString(),
        name: (json['name'] ?? 'Okänd station').toString(),
        latitude: _toDouble(json['lat'] ?? json['latitude']),
        longitude: _toDouble(json['lon'] ?? json['longitude']),
      );

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  @override
  String toString() => name;
}
