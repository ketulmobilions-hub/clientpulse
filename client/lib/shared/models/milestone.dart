import 'package:freezed_annotation/freezed_annotation.dart';

part 'milestone.freezed.dart';
part 'milestone.g.dart';

enum MilestoneStatus {
  upcoming,
  delayed,
  completed;

  String get displayLabel => switch (this) {
        upcoming => 'Upcoming',
        delayed => 'Delayed',
        completed => 'Completed',
      };
}

@freezed
class Milestone with _$Milestone {
  const factory Milestone({
    required String id,
    @JsonKey(name: 'project_id') required String projectId,
    required String title,
    @JsonKey(name: 'due_date') String? dueDate,
    required bool completed,
    @JsonKey(name: 'completed_at') String? completedAt,
    required int position,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
  }) = _Milestone;

  factory Milestone.fromJson(Map<String, dynamic> json) =>
      _$MilestoneFromJson(json);
}

extension MilestoneStatusX on Milestone {
  MilestoneStatus get status {
    if (completed) return MilestoneStatus.completed;
    if (dueDate != null) {
      final due = DateTime.tryParse(dueDate!);
      if (due != null) {
        // Compare date-to-date: strip time so today is not considered overdue.
        final today = DateTime.now();
        final todayMidnight = DateTime(today.year, today.month, today.day);
        if (due.isBefore(todayMidnight)) return MilestoneStatus.delayed;
      }
    }
    return MilestoneStatus.upcoming;
  }
}
