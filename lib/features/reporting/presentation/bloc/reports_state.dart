import 'package:cis_crm/features/reporting/domain/entities/report.dart';
import 'package:cis_crm/features/reporting/domain/entities/report_result.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
sealed class ReportsState extends Equatable {
  const ReportsState();

  @override
  List<Object?> get props => [];
}

final class ReportsInitial extends ReportsState {
  const ReportsInitial();
}

final class ReportsLoading extends ReportsState {
  const ReportsLoading();
}

final class ReportsLoaded extends ReportsState {
  const ReportsLoaded(this.reports);

  final List<Report> reports;

  @override
  List<Object?> get props => [reports];
}

final class ReportRunning extends ReportsState {
  const ReportRunning();
}

final class ReportLoaded extends ReportsState {
  const ReportLoaded(this.result);

  final ReportResult result;

  @override
  List<Object?> get props => [result];
}

final class ReportsError extends ReportsState {
  const ReportsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
