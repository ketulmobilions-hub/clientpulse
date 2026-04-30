import 'package:freezed_annotation/freezed_annotation.dart';

part 'update.freezed.dart';
part 'update.g.dart';

enum UpdateCategory {
  progress,
  milestone,
  deliverable,
  blocker,
  inputNeeded;

  String get displayLabel => switch (this) {
        progress => 'Progress',
        milestone => 'Milestone',
        deliverable => 'Deliverable',
        blocker => 'Blocker',
        inputNeeded => 'Input Needed',
      };

  String get apiValue => switch (this) {
        inputNeeded => 'input_needed',
        _ => name,
      };

  static UpdateCategory fromApi(String v) => switch (v) {
        'input_needed' => inputNeeded,
        _ => UpdateCategory.values.firstWhere(
              (e) => e.name == v,
              orElse: () => UpdateCategory.progress,
            ),
      };
}

UpdateCategory _categoryFromJson(String v) => UpdateCategory.fromApi(v);
String _categoryToJson(UpdateCategory c) => c.apiValue;

@freezed
class Update with _$Update {
  const factory Update({
    required String id,
    @JsonKey(name: 'project_id') required String projectId,
    @JsonKey(name: 'author_id') required String authorId,
    required String title,
    required String body,
    required String status,
    @JsonKey(fromJson: _categoryFromJson, toJson: _categoryToJson)
    required UpdateCategory category,
    required int position,
    @JsonKey(name: 'notification_sent_at') String? notificationSentAt,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
  }) = _Update;

  factory Update.fromJson(Map<String, dynamic> json) => _$UpdateFromJson(json);
}
