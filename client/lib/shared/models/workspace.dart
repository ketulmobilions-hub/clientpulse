import 'package:freezed_annotation/freezed_annotation.dart';

part 'workspace.freezed.dart';
part 'workspace.g.dart';

@freezed
class Workspace with _$Workspace {
  const factory Workspace({
    required String id,
    required String name,
    required String slug,
    @JsonKey(name: 'logo_url') String? logoUrl,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _Workspace;

  factory Workspace.fromJson(Map<String, dynamic> json) => _$WorkspaceFromJson(json);
}
