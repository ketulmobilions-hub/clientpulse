// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'portal_overview.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PortalWorkspaceImpl _$$PortalWorkspaceImplFromJson(
        Map<String, dynamic> json) =>
    _$PortalWorkspaceImpl(
      name: json['name'] as String,
      slug: json['slug'] as String,
      logoUrl: json['logo_url'] as String?,
    );

Map<String, dynamic> _$$PortalWorkspaceImplToJson(
        _$PortalWorkspaceImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'slug': instance.slug,
      'logo_url': instance.logoUrl,
    };

_$PortalProjectImpl _$$PortalProjectImplFromJson(Map<String, dynamic> json) =>
    _$PortalProjectImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      clientName: json['client_name'] as String,
      status: _projectStatusFromJson(json['status'] as String),
      startDate: json['start_date'] as String?,
      expectedEndDate: json['expected_end_date'] as String?,
    );

Map<String, dynamic> _$$PortalProjectImplToJson(_$PortalProjectImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'client_name': instance.clientName,
      'status': _projectStatusToJson(instance.status),
      'start_date': instance.startDate,
      'expected_end_date': instance.expectedEndDate,
    };

_$PortalMilestoneImpl _$$PortalMilestoneImplFromJson(
        Map<String, dynamic> json) =>
    _$PortalMilestoneImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      dueDate: json['due_date'] as String?,
      completed: json['completed'] as bool,
      completedAt: json['completed_at'] as String?,
      position: (json['position'] as num).toInt(),
    );

Map<String, dynamic> _$$PortalMilestoneImplToJson(
        _$PortalMilestoneImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'due_date': instance.dueDate,
      'completed': instance.completed,
      'completed_at': instance.completedAt,
      'position': instance.position,
    };

_$PortalProgressImpl _$$PortalProgressImplFromJson(Map<String, dynamic> json) =>
    _$PortalProgressImpl(
      total: (json['total'] as num).toInt(),
      completed: (json['completed'] as num).toInt(),
      percent: (json['percent'] as num).toDouble(),
    );

Map<String, dynamic> _$$PortalProgressImplToJson(
        _$PortalProgressImpl instance) =>
    <String, dynamic>{
      'total': instance.total,
      'completed': instance.completed,
      'percent': instance.percent,
    };

_$PortalOverviewImpl _$$PortalOverviewImplFromJson(Map<String, dynamic> json) =>
    _$PortalOverviewImpl(
      workspace:
          PortalWorkspace.fromJson(json['workspace'] as Map<String, dynamic>),
      project: PortalProject.fromJson(json['project'] as Map<String, dynamic>),
      milestones: (json['milestones'] as List<dynamic>)
          .map((e) => PortalMilestone.fromJson(e as Map<String, dynamic>))
          .toList(),
      progress:
          PortalProgress.fromJson(json['progress'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$PortalOverviewImplToJson(
        _$PortalOverviewImpl instance) =>
    <String, dynamic>{
      'workspace': instance.workspace,
      'project': instance.project,
      'milestones': instance.milestones,
      'progress': instance.progress,
    };
