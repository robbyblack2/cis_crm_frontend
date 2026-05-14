import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/example_entity.dart';

part 'example_model.g.dart';

/// Data Transfer Object for the `example` feature.
///
/// Knows about JSON. Extends [ExampleEntity] so it IS-A entity (no manual
/// mapping required — pass directly into domain code). Use field-level
/// `@JsonKey(name: ...)` to bridge API field naming.
@JsonSerializable()
class ExampleModel extends ExampleEntity {
  const ExampleModel({
    required super.id,
    required super.name,
    super.description,
  });

  factory ExampleModel.fromJson(Map<String, dynamic> json) =>
      _$ExampleModelFromJson(json);

  Map<String, dynamic> toJson() => _$ExampleModelToJson(this);
}
