import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  late Connectivity _connectivity;
  bool _isOnline = true;

  factory ConnectivityService() {
    return _instance;
  }

  ConnectivityService._internal() {
    _connectivity = Connectivity();
  }

  bool get isOnline => _isOnline;

  Future<void> initialize() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = result != ConnectivityResult.none;

    _connectivity.onConnectivityChanged.listen((result) {
      _isOnline = result != ConnectivityResult.none;
    });
  }

  Future<bool> checkConnection() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = result != ConnectivityResult.none;
    return _isOnline;
  }
}
