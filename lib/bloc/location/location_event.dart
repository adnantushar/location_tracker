abstract class LocationEvent {}

class ToggleLocation extends LocationEvent {
  final bool enabled;
  ToggleLocation(this.enabled);
}
