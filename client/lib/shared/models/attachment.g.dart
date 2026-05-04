// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attachment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AttachmentImpl _$$AttachmentImplFromJson(Map<String, dynamic> json) =>
    _$AttachmentImpl(
      id: json['id'] as String,
      updateId: json['update_id'] as String,
      fileName: json['file_name'] as String,
      fileUrl: json['file_url'] as String,
      fileSize: (json['file_size'] as num?)?.toInt(),
      mimeType: json['mime_type'] as String?,
      uploadedBy: json['uploaded_by'] as String?,
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$$AttachmentImplToJson(_$AttachmentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'update_id': instance.updateId,
      'file_name': instance.fileName,
      'file_url': instance.fileUrl,
      'file_size': instance.fileSize,
      'mime_type': instance.mimeType,
      'uploaded_by': instance.uploadedBy,
      'created_at': instance.createdAt,
    };
