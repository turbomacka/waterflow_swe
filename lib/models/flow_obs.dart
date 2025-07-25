/// En observation med tidsstämpel och värde (m³/s).
class FlowObs {
  final DateTime time;
  final double value;

  const FlowObs(this.time, this.value);
}
