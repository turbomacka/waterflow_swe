import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/station_model.dart';
import '../models/flow_obs.dart';
import '../services/smhi_api_service.dart';

enum HydroMode { flow, level }

class StationProvider extends ChangeNotifier {
  final _api = SmhiApiService();
  final _dist = Distance();

  /* ── Två listor + id‑set för snabb lookup ───────────────── */
  List<Station> _flowStations = [];
  List<Station> _levelStations = [];
  final _flowIds = <String>{};
  final _levelIds = <String>{};

  /* ── När‑mig‑filter ─────────────────────────────────────── */
  Position? _userPos;
  static const double _radiusKm = 50;
  bool _nearMode = false;

  /* ── State för UI ────────────────────────────────────────── */
  HydroMode _mode = HydroMode.flow;
  Station? _selected;
  FlowObs? _current;
  FlowObs? _previous;
  bool _loading = false;
  String? _error;

  /* ── Publika getters ─────────────────────────────────────── */
  List<Station> get stations {
    List<Station> base =
        _mode == HydroMode.flow ? _flowStations : _levelStations;
    if (_nearMode && _userPos != null) base = _filterNear(base);
    return base;
  }

  bool hasFlow(Station s) => _flowIds.contains(s.id);
  bool hasLevel(Station s) => _levelIds.contains(s.id);

  bool get isNearMode => _nearMode;
  HydroMode get mode => _mode;
  Station? get selected => _selected;
  FlowObs? get current => _current;
  FlowObs? get previous => _previous;
  bool get isLoading => _loading;
  String? get error => _error;

  bool? get isRising =>
      (_current != null && _previous != null)
          ? _current!.value > _previous!.value
          : null;

  LatLng? get userLatLng =>
      _userPos == null ? null : LatLng(_userPos!.latitude, _userPos!.longitude);

  /* ── Ladda stationer för båda parametrar ────────────────── */
  Future<void> loadStations() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _api.fetchStations(SmhiApiService.paramFlow),
        _api.fetchStations(SmhiApiService.paramLevel),
      ]);
      _flowStations = results[0];
      _levelStations = results[1];
      _flowIds.addAll(_flowStations.map((s) => s.id));
      _levelIds.addAll(_levelStations.map((s) => s.id));
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /* ── Växla param‑läge ───────────────────────────────────── */
  Future<void> setMode(HydroMode m) async {
    if (_mode == m) return;
    _mode = m;
    _selected = null;
    _current = _previous = null;
    notifyListeners();
  }

  /* ── Välj station & hämta obs ───────────────────────────── */
  Future<void> selectStation(Station s) async {
    _selected = s;
    await _fetchObsForSelected();
  }

  Future<void> _fetchObsForSelected() async {
    if (_selected == null) return;
    _current = _previous = null;
    _error = null;
    _loading = true;
    notifyListeners();

    final pid = _mode == HydroMode.flow
        ? SmhiApiService.paramFlow
        : SmhiApiService.paramLevel;

    try {
      final obs =
          await _api.fetchLatestValues(_selected!.id, paramId: pid, take: 2);
      if (obs.isNotEmpty) _current = obs.last;
      if (obs.length > 1) _previous = obs[obs.length - 2];
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /* ── “Nära mig” ‑toggle ─────────────────────────────────── */
  Future<void> toggleNearMode() async {
    if (_nearMode) {
      _nearMode = false;
      notifyListeners();
      return;
    }
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        throw 'Plats­tillstånd saknas';
      }
      _userPos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _nearMode = true;
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  /* ── Hjälpare för radie‑filter ──────────────────────────── */
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
}
