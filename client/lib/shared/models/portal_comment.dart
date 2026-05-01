import 'package:freezed_annotation/freezed_annotation.dart';

part 'portal_comment.freezed.dart';
part 'portal_comment.g.dart';

DateTime _timestampFromJson(String v) => DateTime.parse(v).toLocal();
String _timestampToJson(DateTime dt) => dt.toUtc().toIso8601String();

@freezed
class PortalComment with _$PortalComment {
  const factory PortalComment({
    required String id,
    @JsonKey(name: 'update_id') required String updateId,
    @JsonKey(name: 'parent_id') String? parentId,
    @JsonKey(name: 'author_name') required String authorName,
    required String body,
    @JsonKey(name: 'created_at', fromJson: _timestampFromJson, toJson: _timestampToJson)
    required DateTime createdAt,
  }) = _PortalComment;

  factory PortalComment.fromJson(Map<String, dynamic> json) =>
      _$PortalCommentFromJson(json);
}
