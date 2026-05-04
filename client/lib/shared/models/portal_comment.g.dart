// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'portal_comment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PortalCommentImpl _$$PortalCommentImplFromJson(Map<String, dynamic> json) =>
    _$PortalCommentImpl(
      id: json['id'] as String,
      updateId: json['update_id'] as String,
      parentId: json['parent_id'] as String?,
      authorName: json['author_name'] as String,
      body: json['body'] as String,
      createdAt: _timestampFromJson(json['created_at'] as String),
    );

Map<String, dynamic> _$$PortalCommentImplToJson(_$PortalCommentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'update_id': instance.updateId,
      'parent_id': instance.parentId,
      'author_name': instance.authorName,
      'body': instance.body,
      'created_at': _timestampToJson(instance.createdAt),
    };
