// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'portal_update.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PortalAttachmentImpl _$$PortalAttachmentImplFromJson(
        Map<String, dynamic> json) =>
    _$PortalAttachmentImpl(
      id: json['id'] as String,
      fileName: json['file_name'] as String,
      fileUrl: json['file_url'] as String,
      fileSize: (json['file_size'] as num?)?.toInt(),
      mimeType: json['mime_type'] as String?,
      createdAt: _timestampFromJson(json['created_at'] as String),
    );

Map<String, dynamic> _$$PortalAttachmentImplToJson(
        _$PortalAttachmentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'file_name': instance.fileName,
      'file_url': instance.fileUrl,
      'file_size': instance.fileSize,
      'mime_type': instance.mimeType,
      'created_at': _timestampToJson(instance.createdAt),
    };

_$PortalUpdateImpl _$$PortalUpdateImplFromJson(Map<String, dynamic> json) =>
    _$PortalUpdateImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      category: _categoryFromJson(json['category'] as String),
      position: (json['position'] as num).toInt(),
      createdAt: _timestampFromJson(json['created_at'] as String),
      updatedAt: _timestampFromJson(json['updated_at'] as String),
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => PortalAttachment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$PortalUpdateImplToJson(_$PortalUpdateImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'body': instance.body,
      'category': _categoryToJson(instance.category),
      'position': instance.position,
      'created_at': _timestampToJson(instance.createdAt),
      'updated_at': _timestampToJson(instance.updatedAt),
      'attachments': instance.attachments,
    };
