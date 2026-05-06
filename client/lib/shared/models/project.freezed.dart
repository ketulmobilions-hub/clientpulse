// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Project _$ProjectFromJson(Map<String, dynamic> json) {
  return _Project.fromJson(json);
}

/// @nodoc
mixin _$Project {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'workspace_id')
  String get workspaceId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'client_name')
  String get clientName => throw _privateConstructorUsedError;
  @JsonKey(name: 'client_email')
  String get clientEmail => throw _privateConstructorUsedError;
  ProjectStatus get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'share_token')
  String? get shareToken => throw _privateConstructorUsedError;
  @JsonKey(
      name: 'start_date',
      fromJson: _localDateFromJson,
      toJson: _localDateToJson)
  DateTime? get startDate => throw _privateConstructorUsedError;
  @JsonKey(
      name: 'expected_end_date',
      fromJson: _localDateFromJson,
      toJson: _localDateToJson)
  DateTime? get expectedEndDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt =>
      throw _privateConstructorUsedError; // Aggregate fields populated only by list endpoint; null on detail/create/update responses
  @JsonKey(name: 'update_count')
  int? get updateCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'comment_count')
  int? get commentCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'latest_update_title')
  String? get latestUpdateTitle =>
      throw _privateConstructorUsedError; // 0–100 inclusive, or null when project has no milestones (progress is undefined, not zero)
  @JsonKey(name: 'progress_pct')
  int? get progressPct => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ProjectCopyWith<Project> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectCopyWith<$Res> {
  factory $ProjectCopyWith(Project value, $Res Function(Project) then) =
      _$ProjectCopyWithImpl<$Res, Project>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'workspace_id') String workspaceId,
      String name,
      String? description,
      @JsonKey(name: 'client_name') String clientName,
      @JsonKey(name: 'client_email') String clientEmail,
      ProjectStatus status,
      @JsonKey(name: 'share_token') String? shareToken,
      @JsonKey(
          name: 'start_date',
          fromJson: _localDateFromJson,
          toJson: _localDateToJson)
      DateTime? startDate,
      @JsonKey(
          name: 'expected_end_date',
          fromJson: _localDateFromJson,
          toJson: _localDateToJson)
      DateTime? expectedEndDate,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime updatedAt,
      @JsonKey(name: 'update_count') int? updateCount,
      @JsonKey(name: 'comment_count') int? commentCount,
      @JsonKey(name: 'latest_update_title') String? latestUpdateTitle,
      @JsonKey(name: 'progress_pct') int? progressPct});
}

/// @nodoc
class _$ProjectCopyWithImpl<$Res, $Val extends Project>
    implements $ProjectCopyWith<$Res> {
  _$ProjectCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? workspaceId = null,
    Object? name = null,
    Object? description = freezed,
    Object? clientName = null,
    Object? clientEmail = null,
    Object? status = null,
    Object? shareToken = freezed,
    Object? startDate = freezed,
    Object? expectedEndDate = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? updateCount = freezed,
    Object? commentCount = freezed,
    Object? latestUpdateTitle = freezed,
    Object? progressPct = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      workspaceId: null == workspaceId
          ? _value.workspaceId
          : workspaceId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      clientName: null == clientName
          ? _value.clientName
          : clientName // ignore: cast_nullable_to_non_nullable
              as String,
      clientEmail: null == clientEmail
          ? _value.clientEmail
          : clientEmail // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as ProjectStatus,
      shareToken: freezed == shareToken
          ? _value.shareToken
          : shareToken // ignore: cast_nullable_to_non_nullable
              as String?,
      startDate: freezed == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      expectedEndDate: freezed == expectedEndDate
          ? _value.expectedEndDate
          : expectedEndDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updateCount: freezed == updateCount
          ? _value.updateCount
          : updateCount // ignore: cast_nullable_to_non_nullable
              as int?,
      commentCount: freezed == commentCount
          ? _value.commentCount
          : commentCount // ignore: cast_nullable_to_non_nullable
              as int?,
      latestUpdateTitle: freezed == latestUpdateTitle
          ? _value.latestUpdateTitle
          : latestUpdateTitle // ignore: cast_nullable_to_non_nullable
              as String?,
      progressPct: freezed == progressPct
          ? _value.progressPct
          : progressPct // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectImplCopyWith<$Res> implements $ProjectCopyWith<$Res> {
  factory _$$ProjectImplCopyWith(
          _$ProjectImpl value, $Res Function(_$ProjectImpl) then) =
      __$$ProjectImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'workspace_id') String workspaceId,
      String name,
      String? description,
      @JsonKey(name: 'client_name') String clientName,
      @JsonKey(name: 'client_email') String clientEmail,
      ProjectStatus status,
      @JsonKey(name: 'share_token') String? shareToken,
      @JsonKey(
          name: 'start_date',
          fromJson: _localDateFromJson,
          toJson: _localDateToJson)
      DateTime? startDate,
      @JsonKey(
          name: 'expected_end_date',
          fromJson: _localDateFromJson,
          toJson: _localDateToJson)
      DateTime? expectedEndDate,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime updatedAt,
      @JsonKey(name: 'update_count') int? updateCount,
      @JsonKey(name: 'comment_count') int? commentCount,
      @JsonKey(name: 'latest_update_title') String? latestUpdateTitle,
      @JsonKey(name: 'progress_pct') int? progressPct});
}

/// @nodoc
class __$$ProjectImplCopyWithImpl<$Res>
    extends _$ProjectCopyWithImpl<$Res, _$ProjectImpl>
    implements _$$ProjectImplCopyWith<$Res> {
  __$$ProjectImplCopyWithImpl(
      _$ProjectImpl _value, $Res Function(_$ProjectImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? workspaceId = null,
    Object? name = null,
    Object? description = freezed,
    Object? clientName = null,
    Object? clientEmail = null,
    Object? status = null,
    Object? shareToken = freezed,
    Object? startDate = freezed,
    Object? expectedEndDate = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? updateCount = freezed,
    Object? commentCount = freezed,
    Object? latestUpdateTitle = freezed,
    Object? progressPct = freezed,
  }) {
    return _then(_$ProjectImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      workspaceId: null == workspaceId
          ? _value.workspaceId
          : workspaceId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      clientName: null == clientName
          ? _value.clientName
          : clientName // ignore: cast_nullable_to_non_nullable
              as String,
      clientEmail: null == clientEmail
          ? _value.clientEmail
          : clientEmail // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as ProjectStatus,
      shareToken: freezed == shareToken
          ? _value.shareToken
          : shareToken // ignore: cast_nullable_to_non_nullable
              as String?,
      startDate: freezed == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      expectedEndDate: freezed == expectedEndDate
          ? _value.expectedEndDate
          : expectedEndDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updateCount: freezed == updateCount
          ? _value.updateCount
          : updateCount // ignore: cast_nullable_to_non_nullable
              as int?,
      commentCount: freezed == commentCount
          ? _value.commentCount
          : commentCount // ignore: cast_nullable_to_non_nullable
              as int?,
      latestUpdateTitle: freezed == latestUpdateTitle
          ? _value.latestUpdateTitle
          : latestUpdateTitle // ignore: cast_nullable_to_non_nullable
              as String?,
      progressPct: freezed == progressPct
          ? _value.progressPct
          : progressPct // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProjectImpl implements _Project {
  const _$ProjectImpl(
      {required this.id,
      @JsonKey(name: 'workspace_id') required this.workspaceId,
      required this.name,
      this.description,
      @JsonKey(name: 'client_name') required this.clientName,
      @JsonKey(name: 'client_email') required this.clientEmail,
      required this.status,
      @JsonKey(name: 'share_token') this.shareToken,
      @JsonKey(
          name: 'start_date',
          fromJson: _localDateFromJson,
          toJson: _localDateToJson)
      this.startDate,
      @JsonKey(
          name: 'expected_end_date',
          fromJson: _localDateFromJson,
          toJson: _localDateToJson)
      this.expectedEndDate,
      @JsonKey(name: 'created_at') required this.createdAt,
      @JsonKey(name: 'updated_at') required this.updatedAt,
      @JsonKey(name: 'update_count') this.updateCount,
      @JsonKey(name: 'comment_count') this.commentCount,
      @JsonKey(name: 'latest_update_title') this.latestUpdateTitle,
      @JsonKey(name: 'progress_pct') this.progressPct});

  factory _$ProjectImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'workspace_id')
  final String workspaceId;
  @override
  final String name;
  @override
  final String? description;
  @override
  @JsonKey(name: 'client_name')
  final String clientName;
  @override
  @JsonKey(name: 'client_email')
  final String clientEmail;
  @override
  final ProjectStatus status;
  @override
  @JsonKey(name: 'share_token')
  final String? shareToken;
  @override
  @JsonKey(
      name: 'start_date',
      fromJson: _localDateFromJson,
      toJson: _localDateToJson)
  final DateTime? startDate;
  @override
  @JsonKey(
      name: 'expected_end_date',
      fromJson: _localDateFromJson,
      toJson: _localDateToJson)
  final DateTime? expectedEndDate;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
// Aggregate fields populated only by list endpoint; null on detail/create/update responses
  @override
  @JsonKey(name: 'update_count')
  final int? updateCount;
  @override
  @JsonKey(name: 'comment_count')
  final int? commentCount;
  @override
  @JsonKey(name: 'latest_update_title')
  final String? latestUpdateTitle;
// 0–100 inclusive, or null when project has no milestones (progress is undefined, not zero)
  @override
  @JsonKey(name: 'progress_pct')
  final int? progressPct;

  @override
  String toString() {
    return 'Project(id: $id, workspaceId: $workspaceId, name: $name, description: $description, clientName: $clientName, clientEmail: $clientEmail, status: $status, shareToken: $shareToken, startDate: $startDate, expectedEndDate: $expectedEndDate, createdAt: $createdAt, updatedAt: $updatedAt, updateCount: $updateCount, commentCount: $commentCount, latestUpdateTitle: $latestUpdateTitle, progressPct: $progressPct)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.workspaceId, workspaceId) ||
                other.workspaceId == workspaceId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.clientName, clientName) ||
                other.clientName == clientName) &&
            (identical(other.clientEmail, clientEmail) ||
                other.clientEmail == clientEmail) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.shareToken, shareToken) ||
                other.shareToken == shareToken) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.expectedEndDate, expectedEndDate) ||
                other.expectedEndDate == expectedEndDate) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.updateCount, updateCount) ||
                other.updateCount == updateCount) &&
            (identical(other.commentCount, commentCount) ||
                other.commentCount == commentCount) &&
            (identical(other.latestUpdateTitle, latestUpdateTitle) ||
                other.latestUpdateTitle == latestUpdateTitle) &&
            (identical(other.progressPct, progressPct) ||
                other.progressPct == progressPct));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      workspaceId,
      name,
      description,
      clientName,
      clientEmail,
      status,
      shareToken,
      startDate,
      expectedEndDate,
      createdAt,
      updatedAt,
      updateCount,
      commentCount,
      latestUpdateTitle,
      progressPct);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectImplCopyWith<_$ProjectImpl> get copyWith =>
      __$$ProjectImplCopyWithImpl<_$ProjectImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectImplToJson(
      this,
    );
  }
}

abstract class _Project implements Project {
  const factory _Project(
      {required final String id,
      @JsonKey(name: 'workspace_id') required final String workspaceId,
      required final String name,
      final String? description,
      @JsonKey(name: 'client_name') required final String clientName,
      @JsonKey(name: 'client_email') required final String clientEmail,
      required final ProjectStatus status,
      @JsonKey(name: 'share_token') final String? shareToken,
      @JsonKey(
          name: 'start_date',
          fromJson: _localDateFromJson,
          toJson: _localDateToJson)
      final DateTime? startDate,
      @JsonKey(
          name: 'expected_end_date',
          fromJson: _localDateFromJson,
          toJson: _localDateToJson)
      final DateTime? expectedEndDate,
      @JsonKey(name: 'created_at') required final DateTime createdAt,
      @JsonKey(name: 'updated_at') required final DateTime updatedAt,
      @JsonKey(name: 'update_count') final int? updateCount,
      @JsonKey(name: 'comment_count') final int? commentCount,
      @JsonKey(name: 'latest_update_title') final String? latestUpdateTitle,
      @JsonKey(name: 'progress_pct') final int? progressPct}) = _$ProjectImpl;

  factory _Project.fromJson(Map<String, dynamic> json) = _$ProjectImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'workspace_id')
  String get workspaceId;
  @override
  String get name;
  @override
  String? get description;
  @override
  @JsonKey(name: 'client_name')
  String get clientName;
  @override
  @JsonKey(name: 'client_email')
  String get clientEmail;
  @override
  ProjectStatus get status;
  @override
  @JsonKey(name: 'share_token')
  String? get shareToken;
  @override
  @JsonKey(
      name: 'start_date',
      fromJson: _localDateFromJson,
      toJson: _localDateToJson)
  DateTime? get startDate;
  @override
  @JsonKey(
      name: 'expected_end_date',
      fromJson: _localDateFromJson,
      toJson: _localDateToJson)
  DateTime? get expectedEndDate;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt;
  @override // Aggregate fields populated only by list endpoint; null on detail/create/update responses
  @JsonKey(name: 'update_count')
  int? get updateCount;
  @override
  @JsonKey(name: 'comment_count')
  int? get commentCount;
  @override
  @JsonKey(name: 'latest_update_title')
  String? get latestUpdateTitle;
  @override // 0–100 inclusive, or null when project has no milestones (progress is undefined, not zero)
  @JsonKey(name: 'progress_pct')
  int? get progressPct;
  @override
  @JsonKey(ignore: true)
  _$$ProjectImplCopyWith<_$ProjectImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
