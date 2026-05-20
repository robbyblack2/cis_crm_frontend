import 'dart:async';

import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/settings/domain/entities/google_connection.dart';
import 'package:cis_crm/features/settings/domain/repositories/google_repository.dart';
import 'package:cis_crm/features/settings/presentation/bloc/google_integration_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GoogleIntegrationCubit extends Cubit<GoogleIntegrationState> {
  GoogleIntegrationCubit({required GoogleRepository repository})
      : _repository = repository,
        super(const GoogleIntegrationInitial());

  final GoogleRepository _repository;
  Timer? _pollTimer;

  Future<void> loadStatus() async {
    emit(const GoogleIntegrationLoading());
    final result = await _repository.getStatus();
    switch (result) {
      case Success(:final data):
        emit(GoogleIntegrationLoaded(data));
      case Failure(:final error):
        emit(GoogleIntegrationError(error));
    }
  }

  Future<String?> connectGoogle() async {
    // Don't emit loading — keep current state so UI doesn't blank out
    final result = await _repository.getAuthUrl();
    switch (result) {
      case Success(:final data):
        return data;
      case Failure(:final error):
        emit(GoogleIntegrationError(error));
        return null;
    }
  }

  /// Polls the status endpoint every [interval] until connected or [timeout].
  Future<void> pollUntilConnected({
    Duration interval = const Duration(seconds: 3),
    Duration timeout = const Duration(minutes: 2),
  }) async {
    _pollTimer?.cancel();
    emit(const GoogleIntegrationLoading());

    final deadline = DateTime.now().add(timeout);
    final completer = Completer<void>();

    _pollTimer = Timer.periodic(interval, (timer) async {
      if (DateTime.now().isAfter(deadline)) {
        timer.cancel();
        _pollTimer = null;
        // Timeout — load final status
        await loadStatus();
        if (!completer.isCompleted) completer.complete();
        return;
      }

      final result = await _repository.getStatus();
      switch (result) {
        case Success(:final data):
          if (data.connected) {
            timer.cancel();
            _pollTimer = null;
            emit(GoogleIntegrationLoaded(data));
            if (!completer.isCompleted) completer.complete();
          }
        case Failure():
          // Keep polling on transient errors
          break;
      }
    });

    return completer.future;
  }

  Future<void> disconnectGoogle() async {
    emit(const GoogleIntegrationLoading());
    final result = await _repository.disconnect();
    switch (result) {
      case Success():
        emit(const GoogleIntegrationLoaded(GoogleConnection.disconnected));
      case Failure(:final error):
        emit(GoogleIntegrationError(error));
    }
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }
}
