import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clientpulse/shared/models/attachment.dart';
import 'package:clientpulse/shared/providers/update_service_provider.dart';
import 'package:clientpulse/shared/utils/file_utils.dart';
import 'open_url_stub.dart'
    if (dart.library.html) 'open_url_web.dart';

class AttachmentList extends ConsumerStatefulWidget {
  const AttachmentList({super.key, required this.updateId});

  final String updateId;

  @override
  ConsumerState<AttachmentList> createState() => _AttachmentListState();
}

class _AttachmentListState extends ConsumerState<AttachmentList> {
  List<Attachment>? _attachments;
  bool _loading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      final svc = await ref.read(updateServiceProvider.future);
      final result = await svc.getUpdate(widget.updateId);
      if (!mounted) return;
      setState(() {
        _attachments = result.attachments;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: SizedBox(
          height: 16,
          width: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_hasError) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Row(
          children: [
            Icon(Icons.error_outline, size: 14, color: Colors.red.shade400),
            const SizedBox(width: 6),
            Text(
              'Could not load attachments.',
              style: TextStyle(fontSize: 12, color: Colors.red.shade400),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: _load,
              child: Text(
                'Retry',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final attachments = _attachments;
    if (attachments == null || attachments.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: attachments.map((a) {
        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          leading: const Icon(Icons.attach_file, size: 16),
          title: Text(
            a.fileName,
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: a.fileSize != null
              ? Text(formatFileSize(a.fileSize), style: const TextStyle(fontSize: 11))
              : null,
          trailing: const Icon(Icons.open_in_new, size: 14),
          onTap: () => openUrl(a.fileUrl),
        );
      }).toList(),
    );
  }
}
