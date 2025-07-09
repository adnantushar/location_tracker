part of 'location_bloc.dart';

abstract class LocationServiceEvent extends Equatable {
  const LocationServiceEvent();

  @override
  List<Object> get props => [];
}

class StartTrackingRequested extends LocationServiceEvent {}

class StopTrackingRequested extends LocationServiceEvent {}

// Events from the background isolate
class BackgroundServiceStarted extends LocationServiceEvent {
  final String? lastUpdate;
  const BackgroundServiceStarted({this.lastUpdate});

  @override
  List<Object> get props => [lastUpdate ?? ''];
}

class BackgroundServiceStopped extends LocationServiceEvent {}

class LocationUpdateReceived extends LocationServiceEvent {
  final String lastUpdate;
  const LocationUpdateReceived(this.lastUpdate);

  @override
  List<Object> get props => [lastUpdate];
}

class LocationUpdateFailed extends LocationServiceEvent {
  final String lastUpdate;
  final String error;
  const LocationUpdateFailed(this.lastUpdate, this.error);

  @override
  List<Object> get props => [lastUpdate, error];
}

// Event for initial status check when the Bloc is created
class CheckInitialServiceStatus extends LocationServiceEvent {}
