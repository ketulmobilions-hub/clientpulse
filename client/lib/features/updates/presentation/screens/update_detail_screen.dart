import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clientpulse/shared/providers/update_provider.dart';
import 'package:clientpulse/shared/widgets/shimmer_card.dart';
import '../widgets/agency_comment_section.dart';
import '../widgets/attachment_list.dart';
import '../widgets/category_tag.dart';
import '../widgets/update_card.dart' show formatUpdateDate;

const _kMuted = Color(0xFF71717A);

class UpdateDetailScreen extends ConsumerWidget {
  const UpdateDetailScreen({
    super.key,
    required this.projectId,
    required this.updateId,
  });

  final String projectId;
  final String updateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updatesAsync = ref.watch(updateNotifierProvider(projectId));

    return updatesAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, __) => const ShimmerCard(height: 80),
        ),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Failed to load update'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () =>
                    ref.read(updateNotifierProvider(projectId).notifier).load(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (updates) {
        final update = updates.where((u) => u.id == updateId).firstOrNull;
        if (update == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Update not found')),
            body: const Center(child: Text('This update could not be found.')),
          );
        }

        final attachCount = update.attachmentCount ?? 0;
        final theme = Theme.of(context);

        void onCommentAdded() {
          ref
              .read(updateNotifierProvider(projectId).notifier)
              .incrementCommentCount(updateId);
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              update.title,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Meta row: category badge + date
                    Row(
                      children: [
                        CategoryTag(category: update.category),
                        const Spacer(),
                        Text(
                          formatUpdateDate(update.createdAt),
                          style: const TextStyle(fontSize: 12, color: _kMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Title
                    Text(
                      update.title,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    // Body
                    if (update.body.isNotEmpty)
                      MarkdownBody(
                        data: update.body,
                        styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                          p: theme.textTheme.bodyMedium,
                        ),
                        shrinkWrap: true,
                      ),
                    const SizedBox(height: 24),
                    // Attachments
                    if (attachCount > 0) ...[
                      Text(
                        'Attachments',
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: _kMuted),
                      ),
                      const SizedBox(height: 8),
                      AttachmentList(updateId: updateId),
                      const SizedBox(height: 24),
                    ],
                    // Comments
                    const Divider(),
                    AgencyCommentSection(
                      updateId: updateId,
                      onCommentAdded: onCommentAdded,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
