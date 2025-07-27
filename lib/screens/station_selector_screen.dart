import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/station_provider.dart';
import '../models/station_model.dart';
import 'map_station_selector_screen.dart';

class StationSelectorScreen extends StatefulWidget {
  const StationSelectorScreen({super.key});

  @override
  State<StationSelectorScreen> createState() => _StationSelectorScreenState();
}

class _StationSelectorScreenState extends State<StationSelectorScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<StationProvider>().loadStations(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<StationProvider>();
    final fmtTime = DateFormat.Hm();

    return Scaffold(
      appBar: AppBar(
        title: const Text('SMHI – Vattenflöde'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            tooltip: 'Karta',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MapStationSelectorScreen(),
              ),
            ),
          ),
        ],
      ),
      body: Builder(builder: (_) {
        if (prov.isLoading && prov.stations.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── FilterChip “Nära mig” ───────────────────────────
              FilterChip(
                label: const Text('Visa enbart stationer nära mig'),
                avatar: const Icon(Icons.my_location, size: 20),
                selected: prov.isNearMode,
                onSelected: (_) async {
                  await context.read<StationProvider>().toggleNearMode();
                  if (prov.error != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(prov.error!)),
                    );
                  }
                },
              ),
              const SizedBox(height: 24),

              // ── Dropdown med (filtrerade) stationer ────────────
              if (prov.stations.isEmpty)
                const Text('Inga stationer inom 50 km.'),
              if (prov.stations.isNotEmpty)
                DropdownButton<Station>(
                  value: prov.selected,
                  hint: const Text('Välj mätstation'),
                  isExpanded: true,
                  items: prov.stations
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.name),
                          ))
                      .toList(),
                  onChanged: (s) {
                    if (s != null) prov.selectStation(s);
                  },
                ),

              const SizedBox(height: 24),

              // ── Data / laddning / fel ─────────────────────────
              if (prov.isLoading && prov.selected != null)
                const CircularProgressIndicator(),
              if (prov.error != null && prov.selected != null)
                Text('Fel: ${prov.error}'),
              if (!prov.isLoading &&
                  prov.selected != null &&
                  prov.current == null)
                const Text('Inga observationer (senaste månaden).'),
              if (prov.current != null) ...[
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${prov.current!.value.toStringAsFixed(2)} m³/s',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tidpunkt: ${fmtTime.format(prov.current!.time.toLocal())}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        if (prov.isRising != null)
                          Row(
                            children: [
                              Icon(
                                prov.isRising!
                                    ? Icons.trending_up
                                    : Icons.trending_down,
                                color: prov.isRising!
                                    ? Colors.red
                                    : Colors.blue,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                prov.isRising! ? 'Stigande' : 'Avtagande',
                                style:
                                    Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }),
    );
  }
}
