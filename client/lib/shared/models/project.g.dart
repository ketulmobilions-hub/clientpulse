// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProjectImpl _$$ProjectImplFromJson(Map<String, dynamic> json) =>
    _$ProjectImpl(
      id: json['id'] as String,
      workspaceId: json['workspace_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      clientName: json['client_name'] as String,
      clientEmail: json['client_email'] as String,
      status: $enumDecode(_$ProjectStatusEnumMap, json['status']),
      shareToken: json['share_token'] as String?,
      startDate: _localDateFromJson(json['start_date']),
      expectedEndDate: _localDateFromJson(json['expected_end_date']),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      updateCount: (json['update_count'] as num?)?.toInt(),
      commentCount: (json['comment_count'] as num?)?.toInt(),
      latestUpdateTitle: json['latest_update_title'] as String?,
      progressPct: (json['progress_pct'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$ProjectImplToJson(_$ProjectImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'workspace_id': instance.workspaceId,
      'name': instance.name,
      'description': instance.description,
      'client_name': instance.clientName,
      'client_email': instance.clientEmail,
      'status': _$ProjectStatusEnumMap[instance.status]!,
      'share_token': instance.shareToken,
      'start_date': _localDateToJson(instance.startDate),
      'expected_end_date': _localDateToJson(instance.expectedEndDate),
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'update_count': instance.updateCount,
      'comment_count': instance.commentCount,
      'latest_update_title': instance.latestUpdateTitle,
      'progress_pct': instance.progressPct,
    };

const _$ProjectStatusEnumMap = {
  ProjectStatus.active: 'active',
  ProjectStatus.completed: 'completed',
  ProjectStatus.archived: 'archived',
};
