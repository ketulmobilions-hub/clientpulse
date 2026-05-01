// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Comment _$CommentFromJson(Map<String, dynamic> json) {
  return _Comment.fromJson(json);
}

/// @nodoc
mixin _$Comment {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'update_id')
  String get updateId => throw _privateConstructorUsedError;
  @JsonKey(name: 'parent_id')
  String? get parentId => throw _privateConstructorUsedError;
  @JsonKey(name: 'author_id')
  String? get authorId => throw _privateConstructorUsedError;
  @JsonKey(
      name: 'author_type',
      fromJson: _authorTypeFromJson,
      toJson: _authorTypeToJson)
  CommentAuthorType get authorType => throw _privateConstructorUsedError;
  @JsonKey(name: 'author_name')
  String get authorName => throw _privateConstructorUsedError;
  String get body => throw _privateConstructorUsedError;
  @JsonKey(
      name: 'created_at',
      fromJson: _timestampFromJson,
      toJson: _timestampToJson)
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(
      name: 'updated_at',
      fromJson: _timestampFromJson,
      toJson: _timestampToJson)
  DateTime get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CommentCopyWith<Comment> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CommentCopyWith<$Res> {
  factory $CommentCopyWith(Comment value, $Res Function(Comment) then) =
      _$CommentCopyWithImpl<$Res, Comment>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'update_id') String updateId,
      @JsonKey(name: 'parent_id') String? parentId,
      @JsonKey(name: 'author_id') String? authorId,
      @JsonKey(
          name: 'author_type',
          fromJson: _authorTypeFromJson,
          toJson: _authorTypeToJson)
      CommentAuthorType authorType,
      @JsonKey(name: 'author_name') String authorName,
      String body,
      @JsonKey(
          name: 'created_at',
          fromJson: _timestampFromJson,
          toJson: _timestampToJson)
      DateTime createdAt,
      @JsonKey(
          name: 'updated_at',
          fromJson: _timestampFromJson,
          toJson: _timestampToJson)
      DateTime updatedAt});
}

/// @nodoc
class _$CommentCopyWithImpl<$Res, $Val extends Comment>
    implements $CommentCopyWith<$Res> {
  _$CommentCopyWithImpl(this._value, this._then);

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
    Object? authorId = freezed,
    Object? authorType = null,
    Object? authorName = null,
    Object? body = null,
    Object? createdAt = null,
    Object? updatedAt = null,
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
      authorId: freezed == authorId
          ? _value.authorId
          : authorId // ignore: cast_nullable_to_non_nullable
              as String?,
      authorType: null == authorType
          ? _value.authorType
          : authorType // ignore: cast_nullable_to_non_nullable
              as CommentAuthorType,
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
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CommentImplCopyWith<$Res> implements $CommentCopyWith<$Res> {
  factory _$$CommentImplCopyWith(
          _$CommentImpl value, $Res Function(_$CommentImpl) then) =
      __$$CommentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'update_id') String updateId,
      @JsonKey(name: 'parent_id') String? parentId,
      @JsonKey(name: 'author_id') String? authorId,
      @JsonKey(
          name: 'author_type',
          fromJson: _authorTypeFromJson,
          toJson: _authorTypeToJson)
      CommentAuthorType authorType,
      @JsonKey(name: 'author_name') String authorName,
      String body,
      @JsonKey(
          name: 'created_at',
          fromJson: _timestampFromJson,
          toJson: _timestampToJson)
      DateTime createdAt,
      @JsonKey(
          name: 'updated_at',
          fromJson: _timestampFromJson,
          toJson: _timestampToJson)
      DateTime updatedAt});
}

/// @nodoc
class __$$CommentImplCopyWithImpl<$Res>
    extends _$CommentCopyWithImpl<$Res, _$CommentImpl>
    implements _$$CommentImplCopyWith<$Res> {
  __$$CommentImplCopyWithImpl(
      _$CommentImpl _value, $Res Function(_$CommentImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? updateId = null,
    Object? parentId = freezed,
    Object? authorId = freezed,
    Object? authorType = null,
    Object? authorName = null,
    Object? body = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$CommentImpl(
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
      authorId: freezed == authorId
          ? _value.authorId
          : authorId // ignore: cast_nullable_to_non_nullable
              as String?,
      authorType: null == authorType
          ? _value.authorType
          : authorType // ignore: cast_nullable_to_non_nullable
              as CommentAuthorType,
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
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CommentImpl implements _Comment {
  const _$CommentImpl(
      {required this.id,
      @JsonKey(name: 'update_id') required this.updateId,
      @JsonKey(name: 'parent_id') this.parentId,
      @JsonKey(name: 'author_id') this.authorId,
      @JsonKey(
          name: 'author_type',
          fromJson: _authorTypeFromJson,
          toJson: _authorTypeToJson)
      required this.authorType,
      @JsonKey(name: 'author_name') required this.authorName,
      required this.body,
      @JsonKey(
          name: 'created_at',
          fromJson: _timestampFromJson,
          toJson: _timestampToJson)
      required this.createdAt,
      @JsonKey(
          name: 'updated_at',
          fromJson: _timestampFromJson,
          toJson: _timestampToJson)
      required this.updatedAt});

  factory _$CommentImpl.fromJson(Map<String, dynamic> json) =>
      _$$CommentImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'update_id')
  final String updateId;
  @override
  @JsonKey(name: 'parent_id')
  final String? parentId;
  @override
  @JsonKey(name: 'author_id')
  final String? authorId;
  @override
  @JsonKey(
      name: 'author_type',
      fromJson: _authorTypeFromJson,
      toJson: _authorTypeToJson)
  final CommentAuthorType authorType;
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
  @JsonKey(
      name: 'updated_at',
      fromJson: _timestampFromJson,
      toJson: _timestampToJson)
  final DateTime updatedAt;

  @override
  String toString() {
    return 'Comment(id: $id, updateId: $updateId, parentId: $parentId, authorId: $authorId, authorType: $authorType, authorName: $authorName, body: $body, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CommentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.updateId, updateId) ||
                other.updateId == updateId) &&
            (identical(other.parentId, parentId) ||
                other.parentId == parentId) &&
            (identical(other.authorId, authorId) ||
                other.authorId == authorId) &&
            (identical(other.authorType, authorType) ||
                other.authorType == authorType) &&
            (identical(other.authorName, authorName) ||
                other.authorName == authorName) &&
            (identical(other.body, body) || other.body == body) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, updateId, parentId, authorId,
      authorType, authorName, body, createdAt, updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CommentImplCopyWith<_$CommentImpl> get copyWith =>
      __$$CommentImplCopyWithImpl<_$CommentImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CommentImplToJson(
      this,
    );
  }
}

abstract class _Comment implements Comment {
  const factory _Comment(
      {required final String id,
      @JsonKey(name: 'update_id') required final String updateId,
      @JsonKey(name: 'parent_id') final String? parentId,
      @JsonKey(name: 'author_id') final String? authorId,
      @JsonKey(
          name: 'author_type',
          fromJson: _authorTypeFromJson,
          toJson: _authorTypeToJson)
      required final CommentAuthorType authorType,
      @JsonKey(name: 'author_name') required final String authorName,
      required final String body,
      @JsonKey(
          name: 'created_at',
          fromJson: _timestampFromJson,
          toJson: _timestampToJson)
      required final DateTime createdAt,
      @JsonKey(
          name: 'updated_at',
          fromJson: _timestampFromJson,
          toJson: _timestampToJson)
      required final DateTime updatedAt}) = _$CommentImpl;

  factory _Comment.fromJson(Map<String, dynamic> json) = _$CommentImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'update_id')
  String get updateId;
  @override
  @JsonKey(name: 'parent_id')
  String? get parentId;
  @override
  @JsonKey(name: 'author_id')
  String? get authorId;
  @override
  @JsonKey(
      name: 'author_type',
      fromJson: _authorTypeFromJson,
      toJson: _authorTypeToJson)
  CommentAuthorType get authorType;
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
  @JsonKey(
      name: 'updated_at',
      fromJson: _timestampFromJson,
      toJson: _timestampToJson)
  DateTime get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$CommentImplCopyWith<_$CommentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
