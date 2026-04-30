// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'portal_overview.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PortalWorkspace _$PortalWorkspaceFromJson(Map<String, dynamic> json) {
  return _PortalWorkspace.fromJson(json);
}

/// @nodoc
mixin _$PortalWorkspace {
  String get name => throw _privateConstructorUsedError;
  String get slug => throw _privateConstructorUsedError;
  @JsonKey(name: 'logo_url')
  String? get logoUrl => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PortalWorkspaceCopyWith<PortalWorkspace> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PortalWorkspaceCopyWith<$Res> {
  factory $PortalWorkspaceCopyWith(
          PortalWorkspace value, $Res Function(PortalWorkspace) then) =
      _$PortalWorkspaceCopyWithImpl<$Res, PortalWorkspace>;
  @useResult
  $Res call(
      {String name, String slug, @JsonKey(name: 'logo_url') String? logoUrl});
}

/// @nodoc
class _$PortalWorkspaceCopyWithImpl<$Res, $Val extends PortalWorkspace>
    implements $PortalWorkspaceCopyWith<$Res> {
  _$PortalWorkspaceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? slug = null,
    Object? logoUrl = freezed,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      slug: null == slug
          ? _value.slug
          : slug // ignore: cast_nullable_to_non_nullable
              as String,
      logoUrl: freezed == logoUrl
          ? _value.logoUrl
          : logoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PortalWorkspaceImplCopyWith<$Res>
    implements $PortalWorkspaceCopyWith<$Res> {
  factory _$$PortalWorkspaceImplCopyWith(_$PortalWorkspaceImpl value,
          $Res Function(_$PortalWorkspaceImpl) then) =
      __$$PortalWorkspaceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name, String slug, @JsonKey(name: 'logo_url') String? logoUrl});
}

/// @nodoc
class __$$PortalWorkspaceImplCopyWithImpl<$Res>
    extends _$PortalWorkspaceCopyWithImpl<$Res, _$PortalWorkspaceImpl>
    implements _$$PortalWorkspaceImplCopyWith<$Res> {
  __$$PortalWorkspaceImplCopyWithImpl(
      _$PortalWorkspaceImpl _value, $Res Function(_$PortalWorkspaceImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? slug = null,
    Object? logoUrl = freezed,
  }) {
    return _then(_$PortalWorkspaceImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      slug: null == slug
          ? _value.slug
          : slug // ignore: cast_nullable_to_non_nullable
              as String,
      logoUrl: freezed == logoUrl
          ? _value.logoUrl
          : logoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PortalWorkspaceImpl extends _PortalWorkspace {
  const _$PortalWorkspaceImpl(
      {required this.name,
      required this.slug,
      @JsonKey(name: 'logo_url') this.logoUrl})
      : super._();

  factory _$PortalWorkspaceImpl.fromJson(Map<String, dynamic> json) =>
      _$$PortalWorkspaceImplFromJson(json);

  @override
  final String name;
  @override
  final String slug;
  @override
  @JsonKey(name: 'logo_url')
  final String? logoUrl;

  @override
  String toString() {
    return 'PortalWorkspace(name: $name, slug: $slug, logoUrl: $logoUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PortalWorkspaceImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, name, slug, logoUrl);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PortalWorkspaceImplCopyWith<_$PortalWorkspaceImpl> get copyWith =>
      __$$PortalWorkspaceImplCopyWithImpl<_$PortalWorkspaceImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PortalWorkspaceImplToJson(
      this,
    );
  }
}

abstract class _PortalWorkspace extends PortalWorkspace {
  const factory _PortalWorkspace(
          {required final String name,
          required final String slug,
          @JsonKey(name: 'logo_url') final String? logoUrl}) =
      _$PortalWorkspaceImpl;
  const _PortalWorkspace._() : super._();

  factory _PortalWorkspace.fromJson(Map<String, dynamic> json) =
      _$PortalWorkspaceImpl.fromJson;

  @override
  String get name;
  @override
  String get slug;
  @override
  @JsonKey(name: 'logo_url')
  String? get logoUrl;
  @override
  @JsonKey(ignore: true)
  _$$PortalWorkspaceImplCopyWith<_$PortalWorkspaceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PortalProject _$PortalProjectFromJson(Map<String, dynamic> json) {
  return _PortalProject.fromJson(json);
}

/// @nodoc
mixin _$PortalProject {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'client_name')
  String get clientName => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _projectStatusFromJson, toJson: _projectStatusToJson)
  PortalProjectStatus get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'start_date')
  String? get startDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'expected_end_date')
  String? get expectedEndDate => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PortalProjectCopyWith<PortalProject> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PortalProjectCopyWith<$Res> {
  factory $PortalProjectCopyWith(
          PortalProject value, $Res Function(PortalProject) then) =
      _$PortalProjectCopyWithImpl<$Res, PortalProject>;
  @useResult
  $Res call(
      {String id,
      String name,
      String? description,
      @JsonKey(name: 'client_name') String clientName,
      @JsonKey(fromJson: _projectStatusFromJson, toJson: _projectStatusToJson)
      PortalProjectStatus status,
      @JsonKey(name: 'start_date') String? startDate,
      @JsonKey(name: 'expected_end_date') String? expectedEndDate});
}

/// @nodoc
class _$PortalProjectCopyWithImpl<$Res, $Val extends PortalProject>
    implements $PortalProjectCopyWith<$Res> {
  _$PortalProjectCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? clientName = null,
    Object? status = null,
    Object? startDate = freezed,
    Object? expectedEndDate = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
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
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as PortalProjectStatus,
      startDate: freezed == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as String?,
      expectedEndDate: freezed == expectedEndDate
          ? _value.expectedEndDate
          : expectedEndDate // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PortalProjectImplCopyWith<$Res>
    implements $PortalProjectCopyWith<$Res> {
  factory _$$PortalProjectImplCopyWith(
          _$PortalProjectImpl value, $Res Function(_$PortalProjectImpl) then) =
      __$$PortalProjectImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String? description,
      @JsonKey(name: 'client_name') String clientName,
      @JsonKey(fromJson: _projectStatusFromJson, toJson: _projectStatusToJson)
      PortalProjectStatus status,
      @JsonKey(name: 'start_date') String? startDate,
      @JsonKey(name: 'expected_end_date') String? expectedEndDate});
}

/// @nodoc
class __$$PortalProjectImplCopyWithImpl<$Res>
    extends _$PortalProjectCopyWithImpl<$Res, _$PortalProjectImpl>
    implements _$$PortalProjectImplCopyWith<$Res> {
  __$$PortalProjectImplCopyWithImpl(
      _$PortalProjectImpl _value, $Res Function(_$PortalProjectImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? clientName = null,
    Object? status = null,
    Object? startDate = freezed,
    Object? expectedEndDate = freezed,
  }) {
    return _then(_$PortalProjectImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
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
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as PortalProjectStatus,
      startDate: freezed == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as String?,
      expectedEndDate: freezed == expectedEndDate
          ? _value.expectedEndDate
          : expectedEndDate // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PortalProjectImpl extends _PortalProject {
  const _$PortalProjectImpl(
      {required this.id,
      required this.name,
      this.description,
      @JsonKey(name: 'client_name') required this.clientName,
      @JsonKey(fromJson: _projectStatusFromJson, toJson: _projectStatusToJson)
      required this.status,
      @JsonKey(name: 'start_date') this.startDate,
      @JsonKey(name: 'expected_end_date') this.expectedEndDate})
      : super._();

  factory _$PortalProjectImpl.fromJson(Map<String, dynamic> json) =>
      _$$PortalProjectImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? description;
  @override
  @JsonKey(name: 'client_name')
  final String clientName;
  @override
  @JsonKey(fromJson: _projectStatusFromJson, toJson: _projectStatusToJson)
  final PortalProjectStatus status;
  @override
  @JsonKey(name: 'start_date')
  final String? startDate;
  @override
  @JsonKey(name: 'expected_end_date')
  final String? expectedEndDate;

  @override
  String toString() {
    return 'PortalProject(id: $id, name: $name, description: $description, clientName: $clientName, status: $status, startDate: $startDate, expectedEndDate: $expectedEndDate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PortalProjectImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.clientName, clientName) ||
                other.clientName == clientName) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.expectedEndDate, expectedEndDate) ||
                other.expectedEndDate == expectedEndDate));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, description,
      clientName, status, startDate, expectedEndDate);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PortalProjectImplCopyWith<_$PortalProjectImpl> get copyWith =>
      __$$PortalProjectImplCopyWithImpl<_$PortalProjectImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PortalProjectImplToJson(
      this,
    );
  }
}

abstract class _PortalProject extends PortalProject {
  const factory _PortalProject(
      {required final String id,
      required final String name,
      final String? description,
      @JsonKey(name: 'client_name') required final String clientName,
      @JsonKey(fromJson: _projectStatusFromJson, toJson: _projectStatusToJson)
      required final PortalProjectStatus status,
      @JsonKey(name: 'start_date') final String? startDate,
      @JsonKey(name: 'expected_end_date')
      final String? expectedEndDate}) = _$PortalProjectImpl;
  const _PortalProject._() : super._();

  factory _PortalProject.fromJson(Map<String, dynamic> json) =
      _$PortalProjectImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get description;
  @override
  @JsonKey(name: 'client_name')
  String get clientName;
  @override
  @JsonKey(fromJson: _projectStatusFromJson, toJson: _projectStatusToJson)
  PortalProjectStatus get status;
  @override
  @JsonKey(name: 'start_date')
  String? get startDate;
  @override
  @JsonKey(name: 'expected_end_date')
  String? get expectedEndDate;
  @override
  @JsonKey(ignore: true)
  _$$PortalProjectImplCopyWith<_$PortalProjectImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PortalMilestone _$PortalMilestoneFromJson(Map<String, dynamic> json) {
  return _PortalMilestone.fromJson(json);
}

/// @nodoc
mixin _$PortalMilestone {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  @JsonKey(name: 'due_date')
  String? get dueDate => throw _privateConstructorUsedError;
  bool get completed => throw _privateConstructorUsedError;
  @JsonKey(name: 'completed_at')
  String? get completedAt => throw _privateConstructorUsedError;
  int get position => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PortalMilestoneCopyWith<PortalMilestone> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PortalMilestoneCopyWith<$Res> {
  factory $PortalMilestoneCopyWith(
          PortalMilestone value, $Res Function(PortalMilestone) then) =
      _$PortalMilestoneCopyWithImpl<$Res, PortalMilestone>;
  @useResult
  $Res call(
      {String id,
      String title,
      @JsonKey(name: 'due_date') String? dueDate,
      bool completed,
      @JsonKey(name: 'completed_at') String? completedAt,
      int position});
}

/// @nodoc
class _$PortalMilestoneCopyWithImpl<$Res, $Val extends PortalMilestone>
    implements $PortalMilestoneCopyWith<$Res> {
  _$PortalMilestoneCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? dueDate = freezed,
    Object? completed = null,
    Object? completedAt = freezed,
    Object? position = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      dueDate: freezed == dueDate
          ? _value.dueDate
          : dueDate // ignore: cast_nullable_to_non_nullable
              as String?,
      completed: null == completed
          ? _value.completed
          : completed // ignore: cast_nullable_to_non_nullable
              as bool,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      position: null == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PortalMilestoneImplCopyWith<$Res>
    implements $PortalMilestoneCopyWith<$Res> {
  factory _$$PortalMilestoneImplCopyWith(_$PortalMilestoneImpl value,
          $Res Function(_$PortalMilestoneImpl) then) =
      __$$PortalMilestoneImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      @JsonKey(name: 'due_date') String? dueDate,
      bool completed,
      @JsonKey(name: 'completed_at') String? completedAt,
      int position});
}

/// @nodoc
class __$$PortalMilestoneImplCopyWithImpl<$Res>
    extends _$PortalMilestoneCopyWithImpl<$Res, _$PortalMilestoneImpl>
    implements _$$PortalMilestoneImplCopyWith<$Res> {
  __$$PortalMilestoneImplCopyWithImpl(
      _$PortalMilestoneImpl _value, $Res Function(_$PortalMilestoneImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? dueDate = freezed,
    Object? completed = null,
    Object? completedAt = freezed,
    Object? position = null,
  }) {
    return _then(_$PortalMilestoneImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      dueDate: freezed == dueDate
          ? _value.dueDate
          : dueDate // ignore: cast_nullable_to_non_nullable
              as String?,
      completed: null == completed
          ? _value.completed
          : completed // ignore: cast_nullable_to_non_nullable
              as bool,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      position: null == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PortalMilestoneImpl extends _PortalMilestone {
  const _$PortalMilestoneImpl(
      {required this.id,
      required this.title,
      @JsonKey(name: 'due_date') this.dueDate,
      required this.completed,
      @JsonKey(name: 'completed_at') this.completedAt,
      required this.position})
      : super._();

  factory _$PortalMilestoneImpl.fromJson(Map<String, dynamic> json) =>
      _$$PortalMilestoneImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  @JsonKey(name: 'due_date')
  final String? dueDate;
  @override
  final bool completed;
  @override
  @JsonKey(name: 'completed_at')
  final String? completedAt;
  @override
  final int position;

  @override
  String toString() {
    return 'PortalMilestone(id: $id, title: $title, dueDate: $dueDate, completed: $completed, completedAt: $completedAt, position: $position)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PortalMilestoneImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.dueDate, dueDate) || other.dueDate == dueDate) &&
            (identical(other.completed, completed) ||
                other.completed == completed) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.position, position) ||
                other.position == position));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, title, dueDate, completed, completedAt, position);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PortalMilestoneImplCopyWith<_$PortalMilestoneImpl> get copyWith =>
      __$$PortalMilestoneImplCopyWithImpl<_$PortalMilestoneImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PortalMilestoneImplToJson(
      this,
    );
  }
}

abstract class _PortalMilestone extends PortalMilestone {
  const factory _PortalMilestone(
      {required final String id,
      required final String title,
      @JsonKey(name: 'due_date') final String? dueDate,
      required final bool completed,
      @JsonKey(name: 'completed_at') final String? completedAt,
      required final int position}) = _$PortalMilestoneImpl;
  const _PortalMilestone._() : super._();

  factory _PortalMilestone.fromJson(Map<String, dynamic> json) =
      _$PortalMilestoneImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  @JsonKey(name: 'due_date')
  String? get dueDate;
  @override
  bool get completed;
  @override
  @JsonKey(name: 'completed_at')
  String? get completedAt;
  @override
  int get position;
  @override
  @JsonKey(ignore: true)
  _$$PortalMilestoneImplCopyWith<_$PortalMilestoneImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PortalProgress _$PortalProgressFromJson(Map<String, dynamic> json) {
  return _PortalProgress.fromJson(json);
}

/// @nodoc
mixin _$PortalProgress {
  int get total => throw _privateConstructorUsedError;
  int get completed => throw _privateConstructorUsedError;
  double get percent => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PortalProgressCopyWith<PortalProgress> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PortalProgressCopyWith<$Res> {
  factory $PortalProgressCopyWith(
          PortalProgress value, $Res Function(PortalProgress) then) =
      _$PortalProgressCopyWithImpl<$Res, PortalProgress>;
  @useResult
  $Res call({int total, int completed, double percent});
}

/// @nodoc
class _$PortalProgressCopyWithImpl<$Res, $Val extends PortalProgress>
    implements $PortalProgressCopyWith<$Res> {
  _$PortalProgressCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? total = null,
    Object? completed = null,
    Object? percent = null,
  }) {
    return _then(_value.copyWith(
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      completed: null == completed
          ? _value.completed
          : completed // ignore: cast_nullable_to_non_nullable
              as int,
      percent: null == percent
          ? _value.percent
          : percent // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PortalProgressImplCopyWith<$Res>
    implements $PortalProgressCopyWith<$Res> {
  factory _$$PortalProgressImplCopyWith(_$PortalProgressImpl value,
          $Res Function(_$PortalProgressImpl) then) =
      __$$PortalProgressImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int total, int completed, double percent});
}

/// @nodoc
class __$$PortalProgressImplCopyWithImpl<$Res>
    extends _$PortalProgressCopyWithImpl<$Res, _$PortalProgressImpl>
    implements _$$PortalProgressImplCopyWith<$Res> {
  __$$PortalProgressImplCopyWithImpl(
      _$PortalProgressImpl _value, $Res Function(_$PortalProgressImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? total = null,
    Object? completed = null,
    Object? percent = null,
  }) {
    return _then(_$PortalProgressImpl(
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      completed: null == completed
          ? _value.completed
          : completed // ignore: cast_nullable_to_non_nullable
              as int,
      percent: null == percent
          ? _value.percent
          : percent // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PortalProgressImpl extends _PortalProgress {
  const _$PortalProgressImpl(
      {required this.total, required this.completed, required this.percent})
      : super._();

  factory _$PortalProgressImpl.fromJson(Map<String, dynamic> json) =>
      _$$PortalProgressImplFromJson(json);

  @override
  final int total;
  @override
  final int completed;
  @override
  final double percent;

  @override
  String toString() {
    return 'PortalProgress(total: $total, completed: $completed, percent: $percent)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PortalProgressImpl &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.completed, completed) ||
                other.completed == completed) &&
            (identical(other.percent, percent) || other.percent == percent));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, total, completed, percent);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PortalProgressImplCopyWith<_$PortalProgressImpl> get copyWith =>
      __$$PortalProgressImplCopyWithImpl<_$PortalProgressImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PortalProgressImplToJson(
      this,
    );
  }
}

abstract class _PortalProgress extends PortalProgress {
  const factory _PortalProgress(
      {required final int total,
      required final int completed,
      required final double percent}) = _$PortalProgressImpl;
  const _PortalProgress._() : super._();

  factory _PortalProgress.fromJson(Map<String, dynamic> json) =
      _$PortalProgressImpl.fromJson;

  @override
  int get total;
  @override
  int get completed;
  @override
  double get percent;
  @override
  @JsonKey(ignore: true)
  _$$PortalProgressImplCopyWith<_$PortalProgressImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PortalOverview _$PortalOverviewFromJson(Map<String, dynamic> json) {
  return _PortalOverview.fromJson(json);
}

/// @nodoc
mixin _$PortalOverview {
  PortalWorkspace get workspace => throw _privateConstructorUsedError;
  PortalProject get project => throw _privateConstructorUsedError;
  List<PortalMilestone> get milestones => throw _privateConstructorUsedError;
  PortalProgress get progress => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PortalOverviewCopyWith<PortalOverview> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PortalOverviewCopyWith<$Res> {
  factory $PortalOverviewCopyWith(
          PortalOverview value, $Res Function(PortalOverview) then) =
      _$PortalOverviewCopyWithImpl<$Res, PortalOverview>;
  @useResult
  $Res call(
      {PortalWorkspace workspace,
      PortalProject project,
      List<PortalMilestone> milestones,
      PortalProgress progress});

  $PortalWorkspaceCopyWith<$Res> get workspace;
  $PortalProjectCopyWith<$Res> get project;
  $PortalProgressCopyWith<$Res> get progress;
}

/// @nodoc
class _$PortalOverviewCopyWithImpl<$Res, $Val extends PortalOverview>
    implements $PortalOverviewCopyWith<$Res> {
  _$PortalOverviewCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? workspace = null,
    Object? project = null,
    Object? milestones = null,
    Object? progress = null,
  }) {
    return _then(_value.copyWith(
      workspace: null == workspace
          ? _value.workspace
          : workspace // ignore: cast_nullable_to_non_nullable
              as PortalWorkspace,
      project: null == project
          ? _value.project
          : project // ignore: cast_nullable_to_non_nullable
              as PortalProject,
      milestones: null == milestones
          ? _value.milestones
          : milestones // ignore: cast_nullable_to_non_nullable
              as List<PortalMilestone>,
      progress: null == progress
          ? _value.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as PortalProgress,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $PortalWorkspaceCopyWith<$Res> get workspace {
    return $PortalWorkspaceCopyWith<$Res>(_value.workspace, (value) {
      return _then(_value.copyWith(workspace: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $PortalProjectCopyWith<$Res> get project {
    return $PortalProjectCopyWith<$Res>(_value.project, (value) {
      return _then(_value.copyWith(project: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $PortalProgressCopyWith<$Res> get progress {
    return $PortalProgressCopyWith<$Res>(_value.progress, (value) {
      return _then(_value.copyWith(progress: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PortalOverviewImplCopyWith<$Res>
    implements $PortalOverviewCopyWith<$Res> {
  factory _$$PortalOverviewImplCopyWith(_$PortalOverviewImpl value,
          $Res Function(_$PortalOverviewImpl) then) =
      __$$PortalOverviewImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {PortalWorkspace workspace,
      PortalProject project,
      List<PortalMilestone> milestones,
      PortalProgress progress});

  @override
  $PortalWorkspaceCopyWith<$Res> get workspace;
  @override
  $PortalProjectCopyWith<$Res> get project;
  @override
  $PortalProgressCopyWith<$Res> get progress;
}

/// @nodoc
class __$$PortalOverviewImplCopyWithImpl<$Res>
    extends _$PortalOverviewCopyWithImpl<$Res, _$PortalOverviewImpl>
    implements _$$PortalOverviewImplCopyWith<$Res> {
  __$$PortalOverviewImplCopyWithImpl(
      _$PortalOverviewImpl _value, $Res Function(_$PortalOverviewImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? workspace = null,
    Object? project = null,
    Object? milestones = null,
    Object? progress = null,
  }) {
    return _then(_$PortalOverviewImpl(
      workspace: null == workspace
          ? _value.workspace
          : workspace // ignore: cast_nullable_to_non_nullable
              as PortalWorkspace,
      project: null == project
          ? _value.project
          : project // ignore: cast_nullable_to_non_nullable
              as PortalProject,
      milestones: null == milestones
          ? _value._milestones
          : milestones // ignore: cast_nullable_to_non_nullable
              as List<PortalMilestone>,
      progress: null == progress
          ? _value.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as PortalProgress,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PortalOverviewImpl extends _PortalOverview {
  const _$PortalOverviewImpl(
      {required this.workspace,
      required this.project,
      required final List<PortalMilestone> milestones,
      required this.progress})
      : _milestones = milestones,
        super._();

  factory _$PortalOverviewImpl.fromJson(Map<String, dynamic> json) =>
      _$$PortalOverviewImplFromJson(json);

  @override
  final PortalWorkspace workspace;
  @override
  final PortalProject project;
  final List<PortalMilestone> _milestones;
  @override
  List<PortalMilestone> get milestones {
    if (_milestones is EqualUnmodifiableListView) return _milestones;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_milestones);
  }

  @override
  final PortalProgress progress;

  @override
  String toString() {
    return 'PortalOverview(workspace: $workspace, project: $project, milestones: $milestones, progress: $progress)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PortalOverviewImpl &&
            (identical(other.workspace, workspace) ||
                other.workspace == workspace) &&
            (identical(other.project, project) || other.project == project) &&
            const DeepCollectionEquality()
                .equals(other._milestones, _milestones) &&
            (identical(other.progress, progress) ||
                other.progress == progress));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, workspace, project,
      const DeepCollectionEquality().hash(_milestones), progress);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PortalOverviewImplCopyWith<_$PortalOverviewImpl> get copyWith =>
      __$$PortalOverviewImplCopyWithImpl<_$PortalOverviewImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PortalOverviewImplToJson(
      this,
    );
  }
}

abstract class _PortalOverview extends PortalOverview {
  const factory _PortalOverview(
      {required final PortalWorkspace workspace,
      required final PortalProject project,
      required final List<PortalMilestone> milestones,
      required final PortalProgress progress}) = _$PortalOverviewImpl;
  const _PortalOverview._() : super._();

  factory _PortalOverview.fromJson(Map<String, dynamic> json) =
      _$PortalOverviewImpl.fromJson;

  @override
  PortalWorkspace get workspace;
  @override
  PortalProject get project;
  @override
  List<PortalMilestone> get milestones;
  @override
  PortalProgress get progress;
  @override
  @JsonKey(ignore: true)
  _$$PortalOverviewImplCopyWith<_$PortalOverviewImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
