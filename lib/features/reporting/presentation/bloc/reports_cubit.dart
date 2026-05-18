import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/reporting/domain/repositories/report_repository.dart';
import 'package:cis_crm/features/reporting/presentation/bloc/reports_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ReportsCubit extends Cubit<ReportsState> {
  ReportsCubit({required ReportRepository repository})
      : _repository = repository,
        super(const ReportsInitial());

  final ReportRepository _repository;

  Future<void> loadReports() async {
    emit(const ReportsLoading());
    final result = await _repository.getReports();
    switch (result) {
      case Success(:final data):
        emit(ReportsLoaded(data));
      case Failure(:final error):
        emit(ReportsError(error.message));
    }
  }

  Future<void> runReport(String id) async {
    emit(const ReportRunning());
    final result = await _repository.runReport(id);
    switch (result) {
      case Success(:final data):
        emit(ReportLoaded(data));
      case Failure(:final error):
        emit(ReportsError(error.message));
    }
  }

  Future<void> loadPipelineSummary(String pipelineId) async {
    emit(const PipelineSummaryLoading());
    final result = await _repository.getPipelineSummary(pipelineId);
    switch (result) {
      case Success(:final data):
        emit(PipelineSummaryLoaded(data));
      case Failure(:final error):
        emit(ReportsError(error.message));
    }
  }
}
