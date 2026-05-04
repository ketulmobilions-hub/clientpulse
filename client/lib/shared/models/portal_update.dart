import 'package:freezed_annotation/freezed_annotation.dart';

import 'update.dart';

part 'portal_update.freezed.dart';
part 'portal_update.g.dart';

DateTime _timestampFromJson(String v) => DateTime.parse(v).toLocal();
String _timestampToJson(DateTime dt) => dt.toUtc().toIso8601String();

UpdateCategory _categoryFromJson(String v) => UpdateCategory.fromApi(v);
String _categoryToJson(UpdateCategory c) => c.apiValue;

@freezed
class PortalAttachment with _$PortalAttachment {
  const PortalAttachment._();

  const factory PortalAttachment({
    required String id,
    @JsonKey(name: 'file_name') required String fileName,
    @JsonKey(name: 'file_url') required String fileUrl,
    @JsonKey(name: 'file_size') int? fileSize,
    @JsonKey(name: 'mime_type') String? mimeType,
    @JsonKey(name: 'created_at', fromJson: _timestampFromJson, toJson: _timestampToJson)
    required DateTime createdAt,
  }) = _PortalAttachment;

  factory PortalAttachment.fromJson(Map<String, dynamic> json) =>
      _$PortalAttachmentFromJson(json);
}

@freezed
class PortalUpdate with _$PortalUpdate {
  const PortalUpdate._();

  const factory PortalUpdate({
    required String id,
    required String title,
    required String body,
    @JsonKey(fromJson: _categoryFromJson, toJson: _categoryToJson)
    required UpdateCategory category,
    required int position,
    @JsonKey(name: 'created_at', fromJson: _timestampFromJson, toJson: _timestampToJson)
    required DateTime createdAt,
    @JsonKey(name: 'updated_at', fromJson: _timestampFromJson, toJson: _timestampToJson)
    required DateTime updatedAt,
    @Default([]) List<PortalAttachment> attachments,
  }) = _PortalUpdate;

  factory PortalUpdate.fromJson(Map<String, dynamic> json) =>
      _$PortalUpdateFromJson(json);
}
