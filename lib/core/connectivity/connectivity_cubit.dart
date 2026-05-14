import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum ConnectivityStatus { online, offline }

class ConnectivityCubit extends Cubit<ConnectivityStatus> {
  ConnectivityCubit({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity(),
        super(ConnectivityStatus.online) {
    _subscription = _connectivity.onConnectivityChanged.listen(_onChanged);
  }

  final Connectivity _connectivity;
  late final StreamSubscription<List<ConnectivityResult>> _subscription;

  void _onChanged(List<ConnectivityResult> results) {
    final isOffline = results.every((r) => r == ConnectivityResult.none);
    emit(isOffline ? ConnectivityStatus.offline : ConnectivityStatus.online);
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
