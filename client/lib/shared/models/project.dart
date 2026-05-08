import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'project.freezed.dart';
part 'project.g.dart';

enum ProjectStatus {
  @JsonValue('active') active,
  @JsonValue('completed') completed,
  @JsonValue('archived') archived,
}

// Parses 'YYYY-MM-DD' as a local DateTime, avoiding the timezone off-by-one
// that occurs when DateTime.parse() treats a naive date string as UTC midnight.
DateTime? _localDateFromJson(dynamic value) {
  if (value == null) return null;
  final parts = (value as String).split('-');
  if (parts.length != 3) return null;
  return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
}

String? _localDateToJson(DateTime? dt) {
  if (dt == null) return null;
  return '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';
}

@freezed
class Project with _$Project {
  const factory Project({
    required String id,
    @JsonKey(name: 'workspace_id') required String workspaceId,
    required String name,
    String? description,
    @JsonKey(name: 'client_name') required String clientName,
    @JsonKey(name: 'client_email') required String clientEmail,
    required ProjectStatus status,
    @JsonKey(name: 'share_token') String? shareToken,
    @JsonKey(name: 'start_date', fromJson: _localDateFromJson, toJson: _localDateToJson)
    DateTime? startDate,
    @JsonKey(name: 'expected_end_date', fromJson: _localDateFromJson, toJson: _localDateToJson)
    DateTime? expectedEndDate,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    // Aggregate fields populated only by list endpoint; null on detail/create/update responses
    @JsonKey(name: 'update_count') int? updateCount,
    @JsonKey(name: 'comment_count') int? commentCount,
    @JsonKey(name: 'latest_update_title') String? latestUpdateTitle,
    // 0–100 inclusive, or null when project has no milestones (progress is undefined, not zero)
    @JsonKey(name: 'progress_pct') int? progressPct,
  }) = _Project;

  factory Project.fromJson(Map<String, dynamic> json) => _$ProjectFromJson(json);
}
