// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'portal_comment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PortalComment _$PortalCommentFromJson(Map<String, dynamic> json) {
  return _PortalComment.fromJson(json);
}

/// @nodoc
mixin _$PortalComment {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'update_id')
  String get updateId => throw _privateConstructorUsedError;
  @JsonKey(name: 'parent_id')
  String? get parentId => throw _privateConstructorUsedError;
  @JsonKey(name: 'author_name')
  String get authorName => throw _privateConstructorUsedError;
  String get body => throw _privateConstructorUsedError;
  @JsonKey(
      name: 'created_at',
      fromJson: _timestampFromJson,
      toJson: _timestampToJson)
  DateTime get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PortalCommentCopyWith<PortalComment> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PortalCommentCopyWith<$Res> {
  factory $PortalCommentCopyWith(
          PortalComment value, $Res Function(PortalComment) then) =
      _$PortalCommentCopyWithImpl<$Res, PortalComment>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'update_id') String updateId,
      @JsonKey(name: 'parent_id') String? parentId,
      @JsonKey(name: 'author_name') String authorName,
      String body,
      @JsonKey(
          name: 'created_at',
          fromJson: _timestampFromJson,
          toJson: _timestampToJson)
      DateTime createdAt});
}

/// @nodoc
class _$PortalCommentCopyWithImpl<$Res, $Val extends PortalComment>
    implements $PortalCommentCopyWith<$Res> {
  _$PortalCommentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? updateId = null,
    Object? parentId = freezed,
    Object? authorName = null,
    Object? body = null,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      updateId: null == updateId
          ? _value.updateId
          : updateId // ignore: cast_nullable_to_non_nullable
              as String,
      parentId: freezed == parentId
          ? _value.parentId
          : parentId // ignore: cast_nullable_to_non_nullable
              as String?,
      authorName: null == authorName
          ? _value.authorName
          : authorName // ignore: cast_nullable_to_non_nullable
              as String,
      body: null == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PortalCommentImplCopyWith<$Res>
    implements $PortalCommentCopyWith<$Res> {
  factory _$$PortalCommentImplCopyWith(
          _$PortalCommentImpl value, $Res Function(_$PortalCommentImpl) then) =
      __$$PortalCommentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'update_id') String updateId,
      @JsonKey(name: 'parent_id') String? parentId,
      @JsonKey(name: 'author_name') String authorName,
      String body,
      @JsonKey(
          name: 'created_at',
          fromJson: _timestampFromJson,
          toJson: _timestampToJson)
      DateTime createdAt});
}

/// @nodoc
class __$$PortalCommentImplCopyWithImpl<$Res>
    extends _$PortalCommentCopyWithImpl<$Res, _$PortalCommentImpl>
    implements _$$PortalCommentImplCopyWith<$Res> {
  __$$PortalCommentImplCopyWithImpl(
      _$PortalCommentImpl _value, $Res Function(_$PortalCommentImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? updateId = null,
    Object? parentId = freezed,
    Object? authorName = null,
    Object? body = null,
    Object? createdAt = null,
  }) {
    return _then(_$PortalCommentImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      updateId: null == updateId
          ? _value.updateId
          : updateId // ignore: cast_nullable_to_non_nullable
              as String,
      parentId: freezed == parentId
          ? _value.parentId
          : parentId // ignore: cast_nullable_to_non_nullable
              as String?,
      authorName: null == authorName
          ? _value.authorName
          : authorName // ignore: cast_nullable_to_non_nullable
              as String,
      body: null == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PortalCommentImpl implements _PortalComment {
  const _$PortalCommentImpl(
      {required this.id,
      @JsonKey(name: 'update_id') required this.updateId,
      @JsonKey(name: 'parent_id') this.parentId,
      @JsonKey(name: 'author_name') required this.authorName,
      required this.body,
      @JsonKey(
          name: 'created_at',
          fromJson: _timestampFromJson,
          toJson: _timestampToJson)
      required this.createdAt});

  factory _$PortalCommentImpl.fromJson(Map<String, dynamic> json) =>
      _$$PortalCommentImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'update_id')
  final String updateId;
  @override
  @JsonKey(name: 'parent_id')
  final String? parentId;
  @override
  @JsonKey(name: 'author_name')
  final String authorName;
  @override
  final String body;
  @override
  @JsonKey(
      name: 'created_at',
      fromJson: _timestampFromJson,
      toJson: _timestampToJson)
  final DateTime createdAt;

  @override
  String toString() {
    return 'PortalComment(id: $id, updateId: $updateId, parentId: $parentId, authorName: $authorName, body: $body, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PortalCommentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.updateId, updateId) ||
                other.updateId == updateId) &&
            (identical(other.parentId, parentId) ||
                other.parentId == parentId) &&
            (identical(other.authorName, authorName) ||
                other.authorName == authorName) &&
            (identical(other.body, body) || other.body == body) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, updateId, parentId, authorName, body, createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PortalCommentImplCopyWith<_$PortalCommentImpl> get copyWith =>
      __$$PortalCommentImplCopyWithImpl<_$PortalCommentImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PortalCommentImplToJson(
      this,
    );
  }
}

abstract class _PortalComment implements PortalComment {
  const factory _PortalComment(
      {required final String id,
      @JsonKey(name: 'update_id') required final String updateId,
      @JsonKey(name: 'parent_id') final String? parentId,
      @JsonKey(name: 'author_name') required final String authorName,
      required final String body,
      @JsonKey(
          name: 'created_at',
          fromJson: _timestampFromJson,
          toJson: _timestampToJson)
      required final DateTime createdAt}) = _$PortalCommentImpl;

  factory _PortalComment.fromJson(Map<String, dynamic> json) =
      _$PortalCommentImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'update_id')
  String get updateId;
  @override
  @JsonKey(name: 'parent_id')
  String? get parentId;
  @override
  @JsonKey(name: 'author_name')
  String get authorName;
  @override
  String get body;
  @override
  @JsonKey(
      name: 'created_at',
      fromJson: _timestampFromJson,
      toJson: _timestampToJson)
  DateTime get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$PortalCommentImplCopyWith<_$PortalCommentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
