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
    emit(const GoogleIntegrationLoading());
    final result = await _repository.getAuthUrl();
    switch (result) {
      case Success(:final data):
        return data;
      case Failure(:final error):
        emit(GoogleIntegrationError(error));
        return null;
    }
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
}
