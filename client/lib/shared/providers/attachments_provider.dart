import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/attachment.dart';
import 'update_service_provider.dart';

final attachmentsProvider = FutureProvider.family
    .autoDispose<List<Attachment>, String>((ref, updateId) async {
  final svc = await ref.read(updateServiceProvider.future);
  final result = await svc.getUpdate(updateId);
  return result.attachments;
});
