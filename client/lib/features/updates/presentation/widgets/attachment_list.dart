import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clientpulse/core/theme/app_colors.dart';
import 'package:clientpulse/core/theme/radii.dart';
import 'package:clientpulse/core/theme/spacing.dart';
import 'package:clientpulse/shared/models/attachment.dart';
import 'package:clientpulse/shared/providers/attachments_provider.dart';
import 'package:clientpulse/shared/utils/file_utils.dart';
import 'package:clientpulse/shared/utils/open_url_stub.dart'
    if (dart.library.html) 'package:clientpulse/shared/utils/open_url_web.dart';

class AttachmentList extends ConsumerWidget {
  const AttachmentList({super.key, required this.updateId});

  final String updateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(attachmentsProvider(updateId));

    return async.when(
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.s16, horizontal: AppSpacing.s4),
        child: Row(
          children: [
            const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: AppSpacing.s12),
            Text(
              'Loading attachments…',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
        child: Row(
          children: [
            const Icon(Icons.error_outline,
                size: 16, color: AppColors.danger),
            const SizedBox(width: AppSpacing.s8),
            Expanded(
              child: Text(
                'Could not load attachments.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.danger),
              ),
            ),
            TextButton(
              onPressed: () => ref.invalidate(attachmentsProvider(updateId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (attachments) {
        if (attachments.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
            child: Text(
              'No attachments.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textMuted),
            ),
          );
        }
        return Column(
          children: [
            for (var i = 0; i < attachments.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.s8),
              _AttachmentCard(attachment: attachments[i]),
            ],
          ],
        );
      },
    );
  }
}

class _AttachmentCard extends StatefulWidget {
  const _AttachmentCard({required this.attachment});

  final Attachment attachment;

  @override
  State<_AttachmentCard> createState() => _AttachmentCardState();
}

class _AttachmentCardState extends State<_AttachmentCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = widget.attachment;
    final ext = _extensionOf(a.fileName);
    final (icon, accent) = _typeStyle(ext, a.mimeType);
    final size = formatFileSize(a.fileSize);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: _hovered ? AppColors.surfaceHover : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          onTap: () => openUrl(a.fileUrl),
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Semantics(
            button: true,
            label: 'Open ${a.fileName}',
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.s12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(
                  color: _hovered
                      ? AppColors.borderHover
                      : AppColors.borderSubtle,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Icon(icon, color: accent, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          a.fileName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (ext.isNotEmpty) ext.toUpperCase(),
                            if (size.isNotEmpty) size,
                          ].join(' · '),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  const Icon(Icons.open_in_new,
                      size: 16, color: AppColors.textFaint),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _extensionOf(String fileName) {
  final dot = fileName.lastIndexOf('.');
  if (dot < 0 || dot == fileName.length - 1) return '';
  return fileName.substring(dot + 1).toLowerCase();
}

(IconData, Color) _typeStyle(String ext, String? mime) {
  const image = {'png', 'jpg', 'jpeg', 'gif', 'webp', 'svg'};
  const video = {'mp4', 'mov', 'webm', 'avi', 'mkv'};
  const audio = {'mp3', 'wav', 'ogg', 'm4a'};
  const archive = {'zip', 'rar', '7z', 'tar', 'gz'};
  const sheet = {'csv', 'xls', 'xlsx', 'numbers'};
  const doc = {'doc', 'docx', 'pages', 'rtf', 'txt', 'md'};
  if (ext == 'pdf') return (Icons.picture_as_pdf, AppColors.categoryRedFg);
  if (image.contains(ext) || (mime?.startsWith('image/') ?? false)) {
    return (Icons.image_outlined, AppColors.categoryVioletFg);
  }
  if (video.contains(ext) || (mime?.startsWith('video/') ?? false)) {
    return (Icons.movie_outlined, AppColors.categoryAmberFg);
  }
  if (audio.contains(ext) || (mime?.startsWith('audio/') ?? false)) {
    return (Icons.audiotrack_outlined, AppColors.categoryBlueFg);
  }
  if (archive.contains(ext)) {
    return (Icons.folder_zip_outlined, AppColors.categoryAmberFg);
  }
  if (sheet.contains(ext)) {
    return (Icons.table_chart_outlined, AppColors.categoryEmeraldFg);
  }
  if (doc.contains(ext)) {
    return (Icons.description_outlined, AppColors.categoryBlueFg);
  }
  return (Icons.insert_drive_file_outlined, AppColors.textFaint);
}
