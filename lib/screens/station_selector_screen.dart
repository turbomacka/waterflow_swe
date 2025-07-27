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

    Widget paramIcon(Station s) {
      final hasF = prov.hasFlow(s);
      final hasL = prov.hasLevel(s);
      if (hasF && hasL) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.water, color: Colors.red, size: 16),
            SizedBox(width: 2),
            Icon(Icons.straighten, color: Colors.blue, size: 16),
          ],
        );
      }
      return Icon(
        hasF ? Icons.water : Icons.straighten,
        color: hasF ? Colors.red : Colors.blue,
        size: 16,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('SMHI – Flöde & Nivå'),
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
              /* ── Mät‑parameter‑växling ─────────────────────── */
              SegmentedButton<HydroMode>(
                segments: const [
                  ButtonSegment(
                    value: HydroMode.flow,
                    icon: Icon(Icons.water),
                    label: Text('Flöde'),
                  ),
                  ButtonSegment(
                    value: HydroMode.level,
                    icon: Icon(Icons.straighten),
                    label: Text('Vattenstånd'),
                  ),
                ],
                selected: {prov.mode},
                onSelectionChanged: (s) =>
                    context.read<StationProvider>().setMode(s.first),
              ),
              const SizedBox(height: 12),

              /* ── FilterChip “Nära mig” ────────────────────── */
              FilterChip(
                label: const Text('Visa enbart stationer nära mig'),
                avatar: const Icon(Icons.my_location, size: 20),
                selected: prov.isNearMode,
                onSelected: (_) async {
                  await context.read<StationProvider>().toggleNearMode();
                  if (prov.error != null && context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(prov.error!)));
                  }
                },
              ),
              const SizedBox(height: 24),

              /* ── Station‑lista ───────────────────────────── */
              if (prov.stations.isEmpty)
                const Text('Inga stationer i listan.'),
              if (prov.stations.isNotEmpty)
                DropdownButton<Station>(
                  value: prov.selected,
                  hint: const Text('Välj mätstation'),
                  isExpanded: true,
                  items: prov.stations
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Row(
                              children: [
                                paramIcon(s),
                                const SizedBox(width: 6),
                                Flexible(child: Text(s.name)),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (s) {
                    if (s != null) prov.selectStation(s);
                  },
                ),
              const SizedBox(height: 24),

              /* ── Data / laddning / fel ───────────────────── */
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
                          prov.mode == HydroMode.flow
                              ? '${prov.current!.value.toStringAsFixed(2)} m³/s'
                              : '${prov.current!.value.toStringAsFixed(2)} m',
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
