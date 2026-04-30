import 'package:freezed_annotation/freezed_annotation.dart';

part 'attachment.freezed.dart';
part 'attachment.g.dart';

@freezed
class Attachment with _$Attachment {
  const factory Attachment({
    required String id,
    @JsonKey(name: 'update_id') required String updateId,
    @JsonKey(name: 'file_name') required String fileName,
    @JsonKey(name: 'file_url') required String fileUrl,
    @JsonKey(name: 'file_size') int? fileSize,
    @JsonKey(name: 'mime_type') String? mimeType,
    @JsonKey(name: 'uploaded_by') String? uploadedBy,
    @JsonKey(name: 'created_at') required String createdAt,
  }) = _Attachment;

  factory Attachment.fromJson(Map<String, dynamic> json) =>
      _$AttachmentFromJson(json);
}
