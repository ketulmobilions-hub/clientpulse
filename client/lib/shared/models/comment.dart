import 'package:freezed_annotation/freezed_annotation.dart';

part 'comment.freezed.dart';
part 'comment.g.dart';

enum CommentAuthorType {
  agency,
  client;

  static CommentAuthorType fromApi(String v) =>
      v == 'client' ? client : agency;
}

CommentAuthorType _authorTypeFromJson(String v) => CommentAuthorType.fromApi(v);
String _authorTypeToJson(CommentAuthorType t) => t.name;

DateTime _timestampFromJson(String v) => DateTime.parse(v).toLocal();
String _timestampToJson(DateTime dt) => dt.toUtc().toIso8601String();

@freezed
class Comment with _$Comment {
  const factory Comment({
    required String id,
    @JsonKey(name: 'update_id') required String updateId,
    @JsonKey(name: 'parent_id') String? parentId,
    @JsonKey(name: 'author_id') String? authorId,
    @JsonKey(
      name: 'author_type',
      fromJson: _authorTypeFromJson,
      toJson: _authorTypeToJson,
    )
    required CommentAuthorType authorType,
    @JsonKey(name: 'author_name') required String authorName,
    required String body,
    @JsonKey(name: 'created_at', fromJson: _timestampFromJson, toJson: _timestampToJson)
    required DateTime createdAt,
    @JsonKey(name: 'updated_at', fromJson: _timestampFromJson, toJson: _timestampToJson)
    required DateTime updatedAt,
  }) = _Comment;

  factory Comment.fromJson(Map<String, dynamic> json) => _$CommentFromJson(json);
}
