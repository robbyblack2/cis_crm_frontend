import 'package:cis_crm/features/reporting/data/models/pipeline_summary_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PipelineSummaryModel', () {
    test('fromJson parses correctly with data wrapper', () {
      final json = {
        'data': {
          'pipeline_id': 'p1',
          'total_records': 45,
          'total_value': 2250000,
          'by_stage': [
            {
              'stage_id': 's1',
              'stage_name': 'Qualified',
              'count': 10,
              'value': 500000,
            },
            {
              'stage_id': 's2',
              'stage_name': 'Proposal',
              'count': 5,
              'value': 250000,
            },
          ],
        },
      };

      final model = PipelineSummaryModel.fromJson(json);

      expect(model.pipelineId, 'p1');
      expect(model.totalRecords, 45);
      expect(model.totalValue, 2250000.0);
      expect(model.byStage.length, 2);
      expect(model.byStage[0].stageId, 's1');
      expect(model.byStage[0].stageName, 'Qualified');
      expect(model.byStage[0].count, 10);
      expect(model.byStage[0].value, 500000.0);
      expect(model.byStage[1].stageName, 'Proposal');
    });

    test('fromJson parses correctly without data wrapper', () {
      final json = {
        'pipeline_id': 'p2',
        'total_records': 10,
        'total_value': 100000,
        'by_stage': <Map<String, dynamic>>[],
      };

      final model = PipelineSummaryModel.fromJson(json);

      expect(model.pipelineId, 'p2');
      expect(model.totalRecords, 10);
      expect(model.totalValue, 100000.0);
      expect(model.byStage, isEmpty);
    });
  });

  group('PipelineStageSummaryModel', () {
    test('fromJson parses correctly', () {
      final json = {
        'stage_id': 's1',
        'stage_name': 'Discovery',
        'count': 7,
        'value': 350000,
      };

      final model = PipelineStageSummaryModel.fromJson(json);

      expect(model.stageId, 's1');
      expect(model.stageName, 'Discovery');
      expect(model.count, 7);
      expect(model.value, 350000.0);
    });

    test('toJson produces expected output', () {
      const model = PipelineStageSummaryModel(
        stageId: 's1',
        stageName: 'Discovery',
        count: 7,
        value: 350000,
      );

      final json = model.toJson();

      expect(json['stage_id'], 's1');
      expect(json['stage_name'], 'Discovery');
      expect(json['count'], 7);
      expect(json['value'], 350000.0);
    });
  });
}
