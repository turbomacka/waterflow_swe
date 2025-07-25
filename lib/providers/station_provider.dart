import 'package:flutter/foundation.dart';
import '../models/station_model.dart';
import '../models/flow_obs.dart';
import '../services/smhi_api_service.dart';

class StationProvider extends ChangeNotifier {
  final _api = SmhiApiService();

  List<Station> _stations = [];
  Station? _selected;
  FlowObs? _current;
  FlowObs? _previous;
  bool _loading = false;
  String? _error;

  List<Station> get stations => _stations;
  Station? get selected => _selected;
  FlowObs? get current => _current;
  FlowObs? get previous => _previous;
  bool get isLoading => _loading;
  String? get error => _error;

  /// true = stigande, false = avtagande, null = okänt
  bool? get isRising {
    if (_current == null || _previous == null) return null;
    return _current!.value > _previous!.value;
  }

  /* ── Station‑lista ──────────────────────────────────────────────── */

  Future<void> loadStations() async {
    _loading = true;
    _error = null;
    try {
      _stations = await _api.fetchStations();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /* ── Välj station och hämta senaste obs. ────────────────────────── */

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
