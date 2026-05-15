import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
class ReportResult extends Equatable {
  const ReportResult({
    required this.columns,
    required this.rows,
  });

  final List<String> columns;
  final List<Map<String, dynamic>> rows;

  @override
  List<Object?> get props => [columns, rows];
}
