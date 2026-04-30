// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'portal_update.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PortalAttachment _$PortalAttachmentFromJson(Map<String, dynamic> json) {
  return _PortalAttachment.fromJson(json);
}

/// @nodoc
mixin _$PortalAttachment {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'file_name')
  String get fileName => throw _privateConstructorUsedError;
  @JsonKey(name: 'file_url')
  String get fileUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'file_size')
  int? get fileSize => throw _privateConstructorUsedError;
  @JsonKey(name: 'mime_type')
  String? get mimeType => throw _privateConstructorUsedError;
  @JsonKey(
      name: 'created_at',
      fromJson: _timestampFromJson,
      toJson: _timestampToJson)
  DateTime get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PortalAttachmentCopyWith<PortalAttachment> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PortalAttachmentCopyWith<$Res> {
  factory $PortalAttachmentCopyWith(
          PortalAttachment value, $Res Function(PortalAttachment) then) =
      _$PortalAttachmentCopyWithImpl<$Res, PortalAttachment>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'file_name') String fileName,
      @JsonKey(name: 'file_url') String fileUrl,
      @JsonKey(name: 'file_size') int? fileSize,
      @JsonKey(name: 'mime_type') String? mimeType,
      @JsonKey(
          name: 'created_at',
          fromJson: _timestampFromJson,
          toJson: _timestampToJson)
      DateTime createdAt});
}

/// @nodoc
class _$PortalAttachmentCopyWithImpl<$Res, $Val extends PortalAttachment>
    implements $PortalAttachmentCopyWith<$Res> {
  _$PortalAttachmentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fileName = null,
    Object? fileUrl = null,
    Object? fileSize = freezed,
    Object? mimeType = freezed,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      fileName: null == fileName
          ? _value.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String,
      fileUrl: null == fileUrl
          ? _value.fileUrl
          : fileUrl // ignore: cast_nullable_to_non_nullable
              as String,
      fileSize: freezed == fileSize
          ? _value.fileSize
          : fileSize // ignore: cast_nullable_to_non_nullable
              as int?,
      mimeType: freezed == mimeType
          ? _value.mimeType
          : mimeType // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PortalAttachmentImplCopyWith<$Res>
    implements $PortalAttachmentCopyWith<$Res> {
  factory _$$PortalAttachmentImplCopyWith(_$PortalAttachmentImpl value,
          $Res Function(_$PortalAttachmentImpl) then) =
      __$$PortalAttachmentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'file_name') String fileName,
      @JsonKey(name: 'file_url') String fileUrl,
      @JsonKey(name: 'file_size') int? fileSize,
      @JsonKey(name: 'mime_type') String? mimeType,
      @JsonKey(
          name: 'created_at',
          fromJson: _timestampFromJson,
          toJson: _timestampToJson)
      DateTime createdAt});
}

/// @nodoc
class __$$PortalAttachmentImplCopyWithImpl<$Res>
    extends _$PortalAttachmentCopyWithImpl<$Res, _$PortalAttachmentImpl>
    implements _$$PortalAttachmentImplCopyWith<$Res> {
  __$$PortalAttachmentImplCopyWithImpl(_$PortalAttachmentImpl _value,
      $Res Function(_$PortalAttachmentImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fileName = null,
    Object? fileUrl = null,
    Object? fileSize = freezed,
    Object? mimeType = freezed,
    Object? createdAt = null,
  }) {
    return _then(_$PortalAttachmentImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      fileName: null == fileName
          ? _value.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String,
      fileUrl: null == fileUrl
          ? _value.fileUrl
          : fileUrl // ignore: cast_nullable_to_non_nullable
              as String,
      fileSize: freezed == fileSize
          ? _value.fileSize
          : fileSize // ignore: cast_nullable_to_non_nullable
              as int?,
      mimeType: freezed == mimeType
          ? _value.mimeType
          : mimeType // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PortalAttachmentImpl extends _PortalAttachment {
  const _$PortalAttachmentImpl(
      {required this.id,
      @JsonKey(name: 'file_name') required this.fileName,
      @JsonKey(name: 'file_url') required this.fileUrl,
      @JsonKey(name: 'file_size') this.fileSize,
      @JsonKey(name: 'mime_type') this.mimeType,
      @JsonKey(
          name: 'created_at',
          fromJson: _timestampFromJson,
          toJson: _timestampToJson)
      required this.createdAt})
      : super._();

  factory _$PortalAttachmentImpl.fromJson(Map<String, dynamic> json) =>
      _$$PortalAttachmentImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'file_name')
  final String fileName;
  @override
  @JsonKey(name: 'file_url')
  final String fileUrl;
  @override
  @JsonKey(name: 'file_size')
  final int? fileSize;
  @override
  @JsonKey(name: 'mime_type')
  final String? mimeType;
  @override
  @JsonKey(
      name: 'created_at',
      fromJson: _timestampFromJson,
      toJson: _timestampToJson)
  final DateTime createdAt;

  @override
  String toString() {
    return 'PortalAttachment(id: $id, fileName: $fileName, fileUrl: $fileUrl, fileSize: $fileSize, mimeType: $mimeType, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PortalAttachmentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.fileName, fileName) ||
                other.fileName == fileName) &&
            (identical(other.fileUrl, fileUrl) || other.fileUrl == fileUrl) &&
            (identical(other.fileSize, fileSize) ||
                other.fileSize == fileSize) &&
            (identical(other.mimeType, mimeType) ||
                other.mimeType == mimeType) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, fileName, fileUrl, fileSize, mimeType, createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PortalAttachmentImplCopyWith<_$PortalAttachmentImpl> get copyWith =>
      __$$PortalAttachmentImplCopyWithImpl<_$PortalAttachmentImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PortalAttachmentImplToJson(
      this,
    );
  }
}

abstract class _PortalAttachment extends PortalAttachment {
  const factory _PortalAttachment(
      {required final String id,
      @JsonKey(name: 'file_name') required final String fileName,
      @JsonKey(name: 'file_url') required final String fileUrl,
      @JsonKey(name: 'file_size') final int? fileSize,
      @JsonKey(name: 'mime_type') final String? mimeType,
      @JsonKey(
          name: 'created_at',
          fromJson: _timestampFromJson,
          toJson: _timestampToJson)
      required final DateTime createdAt}) = _$PortalAttachmentImpl;
  const _PortalAttachment._() : super._();

  factory _PortalAttachment.fromJson(Map<String, dynamic> json) =
      _$PortalAttachmentImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'file_name')
  String get fileName;
  @override
  @JsonKey(name: 'file_url')
  String get fileUrl;
  @override
  @JsonKey(name: 'file_size')
  int? get fileSize;
  @override
  @JsonKey(name: 'mime_type')
  String? get mimeType;
  @override
  @JsonKey(
      name: 'created_at',
      fromJson: _timestampFromJson,
      toJson: _timestampToJson)
  DateTime get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$PortalAttachmentImplCopyWith<_$PortalAttachmentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PortalUpdate _$PortalUpdateFromJson(Map<String, dynamic> json) {
  return _PortalUpdate.fromJson(json);
}

/// @nodoc
mixin _$PortalUpdate {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get body => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _categoryFromJson, toJson: _categoryToJson)
  UpdateCategory get category => throw _privateConstructorUsedError;
  int get position => throw _privateConstructorUsedError;
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
  List<PortalAttachment> get attachments => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PortalUpdateCopyWith<PortalUpdate> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PortalUpdateCopyWith<$Res> {
  factory $PortalUpdateCopyWith(
          PortalUpdate value, $Res Function(PortalUpdate) then) =
      _$PortalUpdateCopyWithImpl<$Res, PortalUpdate>;
  @useResult
  $Res call(
      {String id,
      String title,
      String body,
      @JsonKey(fromJson: _categoryFromJson, toJson: _categoryToJson)
      UpdateCategory category,
      int position,
      @JsonKey(
          name: 'created_at',
          fromJson: _timestampFromJson,
          toJson: _timestampToJson)
      DateTime createdAt,
      @JsonKey(
          name: 'updated_at',
          fromJson: _timestampFromJson,
          toJson: _timestampToJson)
      DateTime updatedAt,
      List<PortalAttachment> attachments});
}

/// @nodoc
class _$PortalUpdateCopyWithImpl<$Res, $Val extends PortalUpdate>
    implements $PortalUpdateCopyWith<$Res> {
  _$PortalUpdateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? body = null,
    Object? category = null,
    Object? position = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? attachments = null,
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
      body: null == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as UpdateCategory,
      position: null == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      attachments: null == attachments
          ? _value.attachments
          : attachments // ignore: cast_nullable_to_non_nullable
              as List<PortalAttachment>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PortalUpdateImplCopyWith<$Res>
    implements $PortalUpdateCopyWith<$Res> {
  factory _$$PortalUpdateImplCopyWith(
          _$PortalUpdateImpl value, $Res Function(_$PortalUpdateImpl) then) =
      __$$PortalUpdateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      String body,
      @JsonKey(fromJson: _categoryFromJson, toJson: _categoryToJson)
      UpdateCategory category,
      int position,
      @JsonKey(
          name: 'created_at',
          fromJson: _timestampFromJson,
          toJson: _timestampToJson)
      DateTime createdAt,
      @JsonKey(
          name: 'updated_at',
          fromJson: _timestampFromJson,
          toJson: _timestampToJson)
      DateTime updatedAt,
      List<PortalAttachment> attachments});
}

/// @nodoc
class __$$PortalUpdateImplCopyWithImpl<$Res>
    extends _$PortalUpdateCopyWithImpl<$Res, _$PortalUpdateImpl>
    implements _$$PortalUpdateImplCopyWith<$Res> {
  __$$PortalUpdateImplCopyWithImpl(
      _$PortalUpdateImpl _value, $Res Function(_$PortalUpdateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? body = null,
    Object? category = null,
    Object? position = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? attachments = null,
  }) {
    return _then(_$PortalUpdateImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      body: null == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as UpdateCategory,
      position: null == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      attachments: null == attachments
          ? _value._attachments
          : attachments // ignore: cast_nullable_to_non_nullable
              as List<PortalAttachment>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PortalUpdateImpl extends _PortalUpdate {
  const _$PortalUpdateImpl(
      {required this.id,
      required this.title,
      required this.body,
      @JsonKey(fromJson: _categoryFromJson, toJson: _categoryToJson)
      required this.category,
      required this.position,
      @JsonKey(
          name: 'created_at',
          fromJson: _timestampFromJson,
          toJson: _timestampToJson)
      required this.createdAt,
      @JsonKey(
          name: 'updated_at',
          fromJson: _timestampFromJson,
          toJson: _timestampToJson)
      required this.updatedAt,
      final List<PortalAttachment> attachments = const []})
      : _attachments = attachments,
        super._();

  factory _$PortalUpdateImpl.fromJson(Map<String, dynamic> json) =>
      _$$PortalUpdateImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String body;
  @override
  @JsonKey(fromJson: _categoryFromJson, toJson: _categoryToJson)
  final UpdateCategory category;
  @override
  final int position;
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
  final List<PortalAttachment> _attachments;
  @override
  @JsonKey()
  List<PortalAttachment> get attachments {
    if (_attachments is EqualUnmodifiableListView) return _attachments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_attachments);
  }

  @override
  String toString() {
    return 'PortalUpdate(id: $id, title: $title, body: $body, category: $category, position: $position, createdAt: $createdAt, updatedAt: $updatedAt, attachments: $attachments)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PortalUpdateImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.body, body) || other.body == body) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            const DeepCollectionEquality()
                .equals(other._attachments, _attachments));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      body,
      category,
      position,
      createdAt,
      updatedAt,
      const DeepCollectionEquality().hash(_attachments));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PortalUpdateImplCopyWith<_$PortalUpdateImpl> get copyWith =>
      __$$PortalUpdateImplCopyWithImpl<_$PortalUpdateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PortalUpdateImplToJson(
      this,
    );
  }
}

abstract class _PortalUpdate extends PortalUpdate {
  const factory _PortalUpdate(
      {required final String id,
      required final String title,
      required final String body,
      @JsonKey(fromJson: _categoryFromJson, toJson: _categoryToJson)
      required final UpdateCategory category,
      required final int position,
      @JsonKey(
          name: 'created_at',
          fromJson: _timestampFromJson,
          toJson: _timestampToJson)
      required final DateTime createdAt,
      @JsonKey(
          name: 'updated_at',
          fromJson: _timestampFromJson,
          toJson: _timestampToJson)
      required final DateTime updatedAt,
      final List<PortalAttachment> attachments}) = _$PortalUpdateImpl;
  const _PortalUpdate._() : super._();

  factory _PortalUpdate.fromJson(Map<String, dynamic> json) =
      _$PortalUpdateImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get body;
  @override
  @JsonKey(fromJson: _categoryFromJson, toJson: _categoryToJson)
  UpdateCategory get category;
  @override
  int get position;
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
  List<PortalAttachment> get attachments;
  @override
  @JsonKey(ignore: true)
  _$$PortalUpdateImplCopyWith<_$PortalUpdateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
