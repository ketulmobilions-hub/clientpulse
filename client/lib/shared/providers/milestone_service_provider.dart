import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/milestone_service.dart';
import 'api_service_provider.dart';

part 'milestone_service_provider.g.dart';

@riverpod
Future<MilestoneService> milestoneService(MilestoneServiceRef ref) async {
  final api = await ref.watch(apiServiceProvider.future);
  return MilestoneService(api);
}
