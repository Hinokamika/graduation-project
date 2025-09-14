import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService _instance = ConnectivityService._();
  factory ConnectivityService() => _instance;

  final Connectivity _connectivity = Connectivity();

  // Raw stream from connectivity_plus v6+: emits a list of connectivity states
  Stream<List<ConnectivityResult>> get onStatusChangesRaw => _connectivity.onConnectivityChanged;

  // Convenience: stream of online/offline booleans
  Stream<bool> get onlineChanges =>
      _connectivity.onConnectivityChanged.map((list) => list.any((r) => r != ConnectivityResult.none));

  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }
}
