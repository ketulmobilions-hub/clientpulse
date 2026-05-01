// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CommentImpl _$$CommentImplFromJson(Map<String, dynamic> json) =>
    _$CommentImpl(
      id: json['id'] as String,
      updateId: json['update_id'] as String,
      parentId: json['parent_id'] as String?,
      authorId: json['author_id'] as String?,
      authorType: _authorTypeFromJson(json['author_type'] as String),
      authorName: json['author_name'] as String,
      body: json['body'] as String,
      createdAt: _timestampFromJson(json['created_at'] as String),
      updatedAt: _timestampFromJson(json['updated_at'] as String),
    );

Map<String, dynamic> _$$CommentImplToJson(_$CommentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'update_id': instance.updateId,
      'parent_id': instance.parentId,
      'author_id': instance.authorId,
      'author_type': _authorTypeToJson(instance.authorType),
      'author_name': instance.authorName,
      'body': instance.body,
      'created_at': _timestampToJson(instance.createdAt),
      'updated_at': _timestampToJson(instance.updatedAt),
    };
