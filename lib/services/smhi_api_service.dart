import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/station_model.dart';
import '../models/flow_obs.dart';

class SmhiApiService {
  static const _base =
      'https://opendata-download-hydroobs.smhi.se/api/version/1.0';

  /* ── Parameter‑ID:n vi stödjer ───────────────────────────── */
  static const paramFlow  = '1'; // vattenföring
  static const paramLevel = '5'; // vattenstånd

  /* ── Hämta stationer för valfri parameter ────────────────── */
  Future<List<Station>> fetchStations(String paramId) async {
    final url = Uri.parse('$_base/parameter/$paramId/station.json');
    final res = await http.get(url);
    if (res.statusCode != 200) {
      throw Exception('station.json (param $paramId) gav HTTP ${res.statusCode}');
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (decoded['station'] ?? decoded['value']) as List<dynamic>;
    return list
        .cast<Map<String, dynamic>>()
        .where((e) => (e['active'] as bool?) ?? true)
        .map(Station.fromJson)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  /* ── Hämta senaste observation(er) ───────────────────────── */
  Future<List<FlowObs>> fetchLatestValues(
    String stationId, {
    required String paramId,
    int take = 2,
  }) async {
    // 1) senaste dygnet
    var obs = await _getValues(stationId, paramId, 'latest-day');
    if (obs.length >= take) return _tail(obs, take);

    // 2) senaste månaden
    obs = await _getValues(stationId, paramId, 'latest-month');
    if (obs.isNotEmpty) return _tail(obs, take);

    // 3) full historik
    obs = await _getValues(stationId, paramId, 'corrected-archive');
    return _tail(obs, take);
  }

  /* ── Interna hjälpare ───────────────────────────────────── */
  Future<List<FlowObs>> _getValues(
      String id, String param, String period) async {
    final url =
        Uri.parse('$_base/parameter/$param/station/$id/period/$period/data.json');
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
