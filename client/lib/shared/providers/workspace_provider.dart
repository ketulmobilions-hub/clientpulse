import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/workspace.dart';
import '../services/workspace_service.dart';
import 'workspace_service_provider.dart';

part 'workspace_provider.g.dart';

@Riverpod(keepAlive: true)
class WorkspaceNotifier extends _$WorkspaceNotifier {
  @override
  Future<Workspace?> build() async => null;

  Future<void> load() async {
    state = const AsyncLoading();
    try {
      final svc = await ref.read(workspaceServiceProvider.future);
      state = AsyncData(await svc.getWorkspace());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> patchWorkspace({String? name, String? logoUrl}) async {
    final prev = state.valueOrNull;
    try {
      final svc = await ref.read(workspaceServiceProvider.future);
      final updated = await svc.updateWorkspace(name: name, logoUrl: logoUrl);
      state = AsyncData(updated);
    } catch (e, st) {
      // Restore previous state on failure so the UI doesn't go blank.
      if (prev != null) {
        state = AsyncData(prev);
      } else {
        // prev was null (workspace never loaded) — leave error state so
        // the screen shows the retry button rather than an empty form.
        state = AsyncError(e, st);
      }
      Error.throwWithStackTrace(e, st);
    }
  }

  /// Uploads [bytes] directly to Supabase Storage via a backend-issued signed URL.
  /// Returns the public URL of the uploaded file.
  ///
  /// Uses `package:http` instead of Dio because Dio's web adapter can
  /// mishandle raw `Uint8List` bodies (JSON-encodes or corrupts them).
  Future<String> uploadLogo(String fileName, Uint8List bytes) async {
    final svc = await ref.read(workspaceServiceProvider.future);
    final (:signedUrl, :publicUrl, path: _) =
        await svc.getUploadSignedUrl(fileName);

    final ext = fileName.split('.').last.toLowerCase();
    final mimeType = switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      _ => 'application/octet-stream',
    };

    try {
      final response = await http.put(
        Uri.parse(signedUrl),
        headers: {
          'Content-Type': mimeType,
          'Content-Length': bytes.length.toString(),
        },
        body: bytes,
      );
      if (response.statusCode >= 400) {
        throw WorkspaceServiceException(
          'Storage upload failed (${response.statusCode})',
        );
      }
    } on WorkspaceServiceException {
      rethrow;
    } catch (e) {
      throw WorkspaceServiceException('Storage upload failed: $e');
    }

    return publicUrl;
  }

  /// Best-effort deletion of an orphaned pending upload.
  /// Swallows all errors — callers fire-and-forget with `.ignore()`.
  Future<void> cleanupLogo(String logoUrl) async {
    try {
      final svc = await ref.read(workspaceServiceProvider.future);
      await svc.deletePendingLogo(logoUrl);
    } catch (_) {
      // Non-fatal: storage object may be cleaned up by a background job later.
    }
  }
}
