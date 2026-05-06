import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

// ─── Low-level service ────────────────────────────────────────────────────────

class ConnectivityService {
  static final ConnectivityService instance = ConnectivityService._();
  ConnectivityService._();

  final _connectivity = Connectivity();

  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  Stream<bool> get onlineStream => _connectivity.onConnectivityChanged
      .map((results) => results.any((r) => r != ConnectivityResult.none));
}

// ─── ChangeNotifier Provider ──────────────────────────────────────────────────

class ConnectivityProvider extends ChangeNotifier {
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  StreamSubscription<bool>? _sub;

  ConnectivityProvider() {
    _init();
  }

  Future<void> _init() async {
    _isOnline = await ConnectivityService.instance.checkConnectivity();
    notifyListeners();
    _sub = ConnectivityService.instance.onlineStream.listen((online) {
      if (_isOnline != online) {
        _isOnline = online;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
