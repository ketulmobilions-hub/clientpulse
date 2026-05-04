// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'update.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Update _$UpdateFromJson(Map<String, dynamic> json) {
  return _Update.fromJson(json);
}

/// @nodoc
mixin _$Update {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'project_id')
  String get projectId => throw _privateConstructorUsedError;
  @JsonKey(name: 'author_id')
  String get authorId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get body => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson)
  UpdateStatus get status => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _categoryFromJson, toJson: _categoryToJson)
  UpdateCategory get category => throw _privateConstructorUsedError;
  int get position => throw _privateConstructorUsedError;
  @JsonKey(name: 'notification_sent_at')
  String? get notificationSentAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  String get updatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'attachment_count')
  int? get attachmentCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'comment_count')
  int? get commentCount => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UpdateCopyWith<Update> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UpdateCopyWith<$Res> {
  factory $UpdateCopyWith(Update value, $Res Function(Update) then) =
      _$UpdateCopyWithImpl<$Res, Update>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'project_id') String projectId,
      @JsonKey(name: 'author_id') String authorId,
      String title,
      String body,
      @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson)
      UpdateStatus status,
      @JsonKey(fromJson: _categoryFromJson, toJson: _categoryToJson)
      UpdateCategory category,
      int position,
      @JsonKey(name: 'notification_sent_at') String? notificationSentAt,
      @JsonKey(name: 'created_at') String createdAt,
      @JsonKey(name: 'updated_at') String updatedAt,
      @JsonKey(name: 'attachment_count') int? attachmentCount,
      @JsonKey(name: 'comment_count') int? commentCount});
}

/// @nodoc
class _$UpdateCopyWithImpl<$Res, $Val extends Update>
    implements $UpdateCopyWith<$Res> {
  _$UpdateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? projectId = null,
    Object? authorId = null,
    Object? title = null,
    Object? body = null,
    Object? status = null,
    Object? category = null,
    Object? position = null,
    Object? notificationSentAt = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? attachmentCount = freezed,
    Object? commentCount = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      projectId: null == projectId
          ? _value.projectId
          : projectId // ignore: cast_nullable_to_non_nullable
              as String,
      authorId: null == authorId
          ? _value.authorId
          : authorId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      body: null == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as UpdateStatus,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as UpdateCategory,
      position: null == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as int,
      notificationSentAt: freezed == notificationSentAt
          ? _value.notificationSentAt
          : notificationSentAt // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as String,
      attachmentCount: freezed == attachmentCount
          ? _value.attachmentCount
          : attachmentCount // ignore: cast_nullable_to_non_nullable
              as int?,
      commentCount: freezed == commentCount
          ? _value.commentCount
          : commentCount // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UpdateImplCopyWith<$Res> implements $UpdateCopyWith<$Res> {
  factory _$$UpdateImplCopyWith(
          _$UpdateImpl value, $Res Function(_$UpdateImpl) then) =
      __$$UpdateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'project_id') String projectId,
      @JsonKey(name: 'author_id') String authorId,
      String title,
      String body,
      @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson)
      UpdateStatus status,
      @JsonKey(fromJson: _categoryFromJson, toJson: _categoryToJson)
      UpdateCategory category,
      int position,
      @JsonKey(name: 'notification_sent_at') String? notificationSentAt,
      @JsonKey(name: 'created_at') String createdAt,
      @JsonKey(name: 'updated_at') String updatedAt,
      @JsonKey(name: 'attachment_count') int? attachmentCount,
      @JsonKey(name: 'comment_count') int? commentCount});
}

/// @nodoc
class __$$UpdateImplCopyWithImpl<$Res>
    extends _$UpdateCopyWithImpl<$Res, _$UpdateImpl>
    implements _$$UpdateImplCopyWith<$Res> {
  __$$UpdateImplCopyWithImpl(
      _$UpdateImpl _value, $Res Function(_$UpdateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? projectId = null,
    Object? authorId = null,
    Object? title = null,
    Object? body = null,
    Object? status = null,
    Object? category = null,
    Object? position = null,
    Object? notificationSentAt = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? attachmentCount = freezed,
    Object? commentCount = freezed,
  }) {
    return _then(_$UpdateImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      projectId: null == projectId
          ? _value.projectId
          : projectId // ignore: cast_nullable_to_non_nullable
              as String,
      authorId: null == authorId
          ? _value.authorId
          : authorId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      body: null == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as UpdateStatus,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as UpdateCategory,
      position: null == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as int,
      notificationSentAt: freezed == notificationSentAt
          ? _value.notificationSentAt
          : notificationSentAt // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as String,
      attachmentCount: freezed == attachmentCount
          ? _value.attachmentCount
          : attachmentCount // ignore: cast_nullable_to_non_nullable
              as int?,
      commentCount: freezed == commentCount
          ? _value.commentCount
          : commentCount // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UpdateImpl implements _Update {
  const _$UpdateImpl(
      {required this.id,
      @JsonKey(name: 'project_id') required this.projectId,
      @JsonKey(name: 'author_id') required this.authorId,
      required this.title,
      required this.body,
      @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson)
      required this.status,
      @JsonKey(fromJson: _categoryFromJson, toJson: _categoryToJson)
      required this.category,
      required this.position,
      @JsonKey(name: 'notification_sent_at') this.notificationSentAt,
      @JsonKey(name: 'created_at') required this.createdAt,
      @JsonKey(name: 'updated_at') required this.updatedAt,
      @JsonKey(name: 'attachment_count') this.attachmentCount,
      @JsonKey(name: 'comment_count') this.commentCount});

  factory _$UpdateImpl.fromJson(Map<String, dynamic> json) =>
      _$$UpdateImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'project_id')
  final String projectId;
  @override
  @JsonKey(name: 'author_id')
  final String authorId;
  @override
  final String title;
  @override
  final String body;
  @override
  @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson)
  final UpdateStatus status;
  @override
  @JsonKey(fromJson: _categoryFromJson, toJson: _categoryToJson)
  final UpdateCategory category;
  @override
  final int position;
  @override
  @JsonKey(name: 'notification_sent_at')
  final String? notificationSentAt;
  @override
  @JsonKey(name: 'created_at')
  final String createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final String updatedAt;
  @override
  @JsonKey(name: 'attachment_count')
  final int? attachmentCount;
  @override
  @JsonKey(name: 'comment_count')
  final int? commentCount;

  @override
  String toString() {
    return 'Update(id: $id, projectId: $projectId, authorId: $authorId, title: $title, body: $body, status: $status, category: $category, position: $position, notificationSentAt: $notificationSentAt, createdAt: $createdAt, updatedAt: $updatedAt, attachmentCount: $attachmentCount, commentCount: $commentCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UpdateImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            (identical(other.authorId, authorId) ||
                other.authorId == authorId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.body, body) || other.body == body) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.notificationSentAt, notificationSentAt) ||
                other.notificationSentAt == notificationSentAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.attachmentCount, attachmentCount) ||
                other.attachmentCount == attachmentCount) &&
            (identical(other.commentCount, commentCount) ||
                other.commentCount == commentCount));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      projectId,
      authorId,
      title,
      body,
      status,
      category,
      position,
      notificationSentAt,
      createdAt,
      updatedAt,
      attachmentCount,
      commentCount);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UpdateImplCopyWith<_$UpdateImpl> get copyWith =>
      __$$UpdateImplCopyWithImpl<_$UpdateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UpdateImplToJson(
      this,
    );
  }
}

abstract class _Update implements Update {
  const factory _Update(
      {required final String id,
      @JsonKey(name: 'project_id') required final String projectId,
      @JsonKey(name: 'author_id') required final String authorId,
      required final String title,
      required final String body,
      @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson)
      required final UpdateStatus status,
      @JsonKey(fromJson: _categoryFromJson, toJson: _categoryToJson)
      required final UpdateCategory category,
      required final int position,
      @JsonKey(name: 'notification_sent_at') final String? notificationSentAt,
      @JsonKey(name: 'created_at') required final String createdAt,
      @JsonKey(name: 'updated_at') required final String updatedAt,
      @JsonKey(name: 'attachment_count') final int? attachmentCount,
      @JsonKey(name: 'comment_count') final int? commentCount}) = _$UpdateImpl;

  factory _Update.fromJson(Map<String, dynamic> json) = _$UpdateImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'project_id')
  String get projectId;
  @override
  @JsonKey(name: 'author_id')
  String get authorId;
  @override
  String get title;
  @override
  String get body;
  @override
  @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson)
  UpdateStatus get status;
  @override
  @JsonKey(fromJson: _categoryFromJson, toJson: _categoryToJson)
  UpdateCategory get category;
  @override
  int get position;
  @override
  @JsonKey(name: 'notification_sent_at')
  String? get notificationSentAt;
  @override
  @JsonKey(name: 'created_at')
  String get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  String get updatedAt;
  @override
  @JsonKey(name: 'attachment_count')
  int? get attachmentCount;
  @override
  @JsonKey(name: 'comment_count')
  int? get commentCount;
  @override
  @JsonKey(ignore: true)
  _$$UpdateImplCopyWith<_$UpdateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
