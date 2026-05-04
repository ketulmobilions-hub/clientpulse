// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UpdateImpl _$$UpdateImplFromJson(Map<String, dynamic> json) => _$UpdateImpl(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      authorId: json['author_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      status: _statusFromJson(json['status'] as String),
      category: _categoryFromJson(json['category'] as String),
      position: (json['position'] as num).toInt(),
      notificationSentAt: json['notification_sent_at'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      attachmentCount: (json['attachment_count'] as num?)?.toInt(),
      commentCount: (json['comment_count'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$UpdateImplToJson(_$UpdateImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'project_id': instance.projectId,
      'author_id': instance.authorId,
      'title': instance.title,
      'body': instance.body,
      'status': _statusToJson(instance.status),
      'category': _categoryToJson(instance.category),
      'position': instance.position,
      'notification_sent_at': instance.notificationSentAt,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'attachment_count': instance.attachmentCount,
      'comment_count': instance.commentCount,
    };
