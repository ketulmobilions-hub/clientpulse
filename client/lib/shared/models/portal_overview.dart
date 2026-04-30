import 'package:freezed_annotation/freezed_annotation.dart';

part 'portal_overview.freezed.dart';
part 'portal_overview.g.dart';

enum PortalProjectStatus {
  active,
  completed,
  archived,
  unknown;

  String get displayLabel => switch (this) {
        active => 'Active',
        completed => 'Completed',
        archived => 'Archived',
        unknown => 'Unknown',
      };
}

PortalProjectStatus _projectStatusFromJson(String v) => switch (v) {
      'active' => PortalProjectStatus.active,
      'completed' => PortalProjectStatus.completed,
      'archived' => PortalProjectStatus.archived,
      _ => PortalProjectStatus.unknown,
    };

String _projectStatusToJson(PortalProjectStatus s) =>
    s == PortalProjectStatus.unknown ? 'active' : s.name;

@freezed
class PortalWorkspace with _$PortalWorkspace {
  const PortalWorkspace._();

  const factory PortalWorkspace({
    required String name,
    required String slug,
    @JsonKey(name: 'logo_url') String? logoUrl,
  }) = _PortalWorkspace;

  factory PortalWorkspace.fromJson(Map<String, dynamic> json) =>
      _$PortalWorkspaceFromJson(json);
}

@freezed
class PortalProject with _$PortalProject {
  const PortalProject._();

  const factory PortalProject({
    required String id,
    required String name,
    String? description,
    @JsonKey(name: 'client_name') required String clientName,
    @JsonKey(fromJson: _projectStatusFromJson, toJson: _projectStatusToJson)
    required PortalProjectStatus status,
    @JsonKey(name: 'start_date') String? startDate,
    @JsonKey(name: 'expected_end_date') String? expectedEndDate,
  }) = _PortalProject;

  factory PortalProject.fromJson(Map<String, dynamic> json) =>
      _$PortalProjectFromJson(json);
}

@freezed
class PortalMilestone with _$PortalMilestone {
  const PortalMilestone._();

  const factory PortalMilestone({
    required String id,
    required String title,
    @JsonKey(name: 'due_date') String? dueDate,
    required bool completed,
    @JsonKey(name: 'completed_at') String? completedAt,
    required int position,
  }) = _PortalMilestone;

  factory PortalMilestone.fromJson(Map<String, dynamic> json) =>
      _$PortalMilestoneFromJson(json);
}

@freezed
class PortalProgress with _$PortalProgress {
  const PortalProgress._();

  // percent is double to safely accept both int and float JSON values.
  const factory PortalProgress({
    required int total,
    required int completed,
    required double percent,
  }) = _PortalProgress;

  factory PortalProgress.fromJson(Map<String, dynamic> json) =>
      _$PortalProgressFromJson(json);
}

@freezed
class PortalOverview with _$PortalOverview {
  const PortalOverview._();

  const factory PortalOverview({
    required PortalWorkspace workspace,
    required PortalProject project,
    required List<PortalMilestone> milestones,
    required PortalProgress progress,
  }) = _PortalOverview;

  factory PortalOverview.fromJson(Map<String, dynamic> json) =>
      _$PortalOverviewFromJson(json);
}
