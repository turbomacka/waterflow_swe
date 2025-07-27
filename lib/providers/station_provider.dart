import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/station_model.dart';
import '../models/flow_obs.dart';
import '../services/smhi_api_service.dart';

class StationProvider extends ChangeNotifier {
  final _api = SmhiApiService();
  final _dist = Distance();

  /* ── Station‑lista ─────────────────────────────────────────── */
  List<Station> _allStations = [];

  /* ── “nära mig”‑läge ───────────────────────────────────────── */
  Position? _userPos;
  static const double _radiusKm = 50;
  bool _nearMode = false;

  /* ── Vald station & flöden ─────────────────────────────────── */
  Station? _selected;
  FlowObs? _current;
  FlowObs? _previous;

  /* ── Laddning & fel ────────────────────────────────────────── */
  bool _loading = false;
  String? _error;

  /* ── Publika getters ───────────────────────────────────────── */
  List<Station> get stations => _nearMode && _userPos != null
      ? _filterNear(_allStations)
      : _allStations;

  bool get isNearMode => _nearMode;
  LatLng? get userLatLng =>
      _userPos == null ? null : LatLng(_userPos!.latitude, _userPos!.longitude);

  Station? get selected => _selected;
  FlowObs? get current => _current;
  FlowObs? get previous => _previous;
  bool get isLoading => _loading;
  String? get error => _error;

  bool? get isRising =>
      (_current != null && _previous != null)
          ? _current!.value > _previous!.value
          : null;

  /* ── Ladda stationer ───────────────────────────────────────── */
  Future<void> loadStations() async {
    _loading = true;
    _error = null;
    try {
      _allStations = await _api.fetchStations();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /* ── “Nära mig”‑knapp ──────────────────────────────────────── */
  Future<void> toggleNearMode() async {
    if (_nearMode) {
      _nearMode = false;
      notifyListeners();
      return;
    }
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        if (await Geolocator.requestPermission() ==
            LocationPermission.denied) {
          throw 'Plats­tillstånd nekat';
        }
      }
      if (perm == LocationPermission.deniedForever) {
        throw 'Plats­tillstånd permanent nekat';
      }
      _userPos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _nearMode = true;
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  List<Station> _filterNear(List<Station> list) {
    if (_userPos == null) return [];
    return list
        .where((s) =>
            s.latitude != null &&
            s.longitude != null &&
            _dist(
                    LatLng(_userPos!.latitude, _userPos!.longitude),
                    LatLng(s.latitude!, s.longitude!)) <=
                _radiusKm * 1000)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  /* ── Välj station ──────────────────────────────────────────── */
  Future<void> selectStation(Station station) async {
    _selected = station;
    _current = _previous = null;
    _error = null;
    _loading = true;
    notifyListeners();

    try {
      final obs = await _api.fetchLatestValues(station.id, take: 2);
      if (obs.isNotEmpty) _current = obs.last;
      if (obs.length > 1) _previous = obs[obs.length - 2];
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
