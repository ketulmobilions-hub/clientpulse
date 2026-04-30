import 'package:freezed_annotation/freezed_annotation.dart';

part 'update.freezed.dart';
part 'update.g.dart';

enum UpdateStatus {
  draft,
  published;

  String get apiValue => name;

  static UpdateStatus fromApi(String v) => switch (v) {
        'published' => published,
        _ => draft,
      };
}

UpdateStatus _statusFromJson(String v) => UpdateStatus.fromApi(v);
String _statusToJson(UpdateStatus s) => s.apiValue;

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
    @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson) required UpdateStatus status,
    @JsonKey(fromJson: _categoryFromJson, toJson: _categoryToJson)
    required UpdateCategory category,
    required int position,
    @JsonKey(name: 'notification_sent_at') String? notificationSentAt,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
    @JsonKey(name: 'attachment_count') int? attachmentCount,
  }) = _Update;

  factory Update.fromJson(Map<String, dynamic> json) => _$UpdateFromJson(json);
}
