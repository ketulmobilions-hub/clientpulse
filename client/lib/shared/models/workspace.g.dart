// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WorkspaceImpl _$$WorkspaceImplFromJson(Map<String, dynamic> json) =>
    _$WorkspaceImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      logoUrl: json['logo_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$WorkspaceImplToJson(_$WorkspaceImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'slug': instance.slug,
      'logo_url': instance.logoUrl,
      'created_at': instance.createdAt.toIso8601String(),
    };
