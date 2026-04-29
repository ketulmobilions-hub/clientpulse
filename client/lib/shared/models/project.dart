import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'project.freezed.dart';
part 'project.g.dart';

enum ProjectStatus {
  @JsonValue('active') active,
  @JsonValue('completed') completed,
  @JsonValue('archived') archived,
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
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _Project;

  factory Project.fromJson(Map<String, dynamic> json) => _$ProjectFromJson(json);
}
