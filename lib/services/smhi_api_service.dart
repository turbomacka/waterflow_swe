import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/station_model.dart';
import '../models/flow_obs.dart';

class SmhiApiService {
  static const _base =
      'https://opendata-download-hydroobs.smhi.se/api/version/1.0';
  static const _parameter = '1'; // vattenföring m³/s

  /// Hämta *aktiva* stationer sorterade alfabetiskt.
  Future<List<Station>> fetchStations() async {
    final url = Uri.parse('$_base/parameter/$_parameter/station.json');
    final res = await http.get(url);
    if (res.statusCode != 200) {
      throw Exception('Kunde inte hämta stationer (HTTP ${res.statusCode})');
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (decoded['station'] ?? decoded['value']) as List<dynamic>;

    return list
        .cast<Map<String, dynamic>>()
        .where((e) =>
            (e['active'] as bool?) ?? true) // filtrera inaktiva stationer
        .map(Station.fromJson)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  /// Hämta de `take` senaste observationerna med fallback‑logik.
  /// Returnerar **tom lista** om ingen data finns i någon endpoint.
  Future<List<FlowObs>> fetchLatestValues(String stationId,
      {int take = 2}) async {
    // 1) senaste dygnet
    var obs = await _getValues(stationId, 'latest-day');
    if (obs.length >= take) {
      return _tail(obs, take);
    }

    // 2) senaste månaden
    obs = await _getValues(stationId, 'latest-month');
    if (obs.isNotEmpty) {
      return _tail(obs, take);
    }

    // 3) full historik (dygnsagg.)
    obs = await _getValues(stationId, 'corrected-archive');
    return _tail(obs, take);
  }

  /* ── privata hjälpare ─────────────────────────────────────────────── */

  /// Hämta *alla* obs. för önskat period‑segment.
  Future<List<FlowObs>> _getValues(String id, String period) async {
    final url = Uri.parse(
        '$_base/parameter/$_parameter/station/$id/period/$period/data.json');
    final res = await http.get(url);
    if (res.statusCode != 200) return const [];

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final values = (decoded['value'] as List<dynamic>?) ?? const [];
    return values
        .cast<Map<String, dynamic>>()
        .map((e) => FlowObs(
              DateTime.fromMillisecondsSinceEpoch(e['date'] as int,
                  isUtc: true),
              double.tryParse(e['value'].toString()) ?? double.nan,
            ))
        .where((o) => o.value.isFinite)
        .toList();
  }

  List<FlowObs> _tail(List<FlowObs> list, int n) =>
      list.sublist(max(0, list.length - n));
}
