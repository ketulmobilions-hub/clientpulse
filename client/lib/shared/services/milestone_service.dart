import 'package:dio/dio.dart';
import '../models/milestone.dart';
import '../utils/api_utils.dart';
import 'api_service.dart';

class MilestoneServiceException implements Exception {
  const MilestoneServiceException(this.message);
  final String message;

  @override
  String toString() => message;
}

class MilestoneService {
  const MilestoneService(this._api);
  final ApiService _api;

  Future<List<Milestone>> listMilestones(String projectId) async {
    try {
      final res =
          await _api.get<Map<String, dynamic>>('/projects/$projectId/milestones');
      final data = tryUnwrapApiData(res.data);
      if (data == null) {
        throw const MilestoneServiceException('Unexpected response format');
      }
      final milestones = data['milestones'];
      if (milestones is! List) {
        throw const MilestoneServiceException('Unexpected response format');
      }
      return milestones.map((m) {
        if (m is! Map<String, dynamic>) {
          throw const MilestoneServiceException(
              'Unexpected element in milestones list');
        }
        return Milestone.fromJson(m);
      }).toList();
    } on DioException catch (e) {
      throw MilestoneServiceException(extractDioErrorMessage(e));
    } on MilestoneServiceException {
      rethrow;
    } catch (e) {
      throw MilestoneServiceException('Unexpected error: $e');
    }
  }

  Future<Milestone> createMilestone(
    String projectId, {
    required String title,
    String? dueDate,
    int position = 0,
  }) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/projects/$projectId/milestones',
        data: {
          'title': title,
          if (dueDate != null) 'due_date': dueDate,
          'position': position,
        },
      );
      final data = tryUnwrapApiData(res.data);
      if (data == null) {
        throw const MilestoneServiceException('Unexpected response format');
      }
      final milestone = data['milestone'];
      if (milestone is! Map<String, dynamic>) {
        throw const MilestoneServiceException('Unexpected response format');
      }
      return Milestone.fromJson(milestone);
    } on DioException catch (e) {
      throw MilestoneServiceException(extractDioErrorMessage(e));
    } on MilestoneServiceException {
      rethrow;
    } catch (e) {
      throw MilestoneServiceException('Unexpected error: $e');
    }
  }

  Future<Milestone> updateMilestone(
    String id, {
    String? title,
    String? dueDate,
    bool clearDueDate = false,
    bool? completed,
    int? position,
  }) async {
    if (title == null && dueDate == null && !clearDueDate && completed == null && position == null) {
      throw const MilestoneServiceException('No fields to update');
    }
    try {
      final body = <String, dynamic>{
        if (title != null) 'title': title,
        if (clearDueDate) 'due_date': null,
        if (!clearDueDate && dueDate != null) 'due_date': dueDate,
        if (completed != null) 'completed': completed,
        if (position != null) 'position': position,
      };
      final res =
          await _api.patch<Map<String, dynamic>>('/milestones/$id', data: body);
      final data = tryUnwrapApiData(res.data);
      if (data == null) {
        throw const MilestoneServiceException('Unexpected response format');
      }
      final milestone = data['milestone'];
      if (milestone is! Map<String, dynamic>) {
        throw const MilestoneServiceException('Unexpected response format');
      }
      return Milestone.fromJson(milestone);
    } on DioException catch (e) {
      throw MilestoneServiceException(extractDioErrorMessage(e));
    } on MilestoneServiceException {
      rethrow;
    } catch (e) {
      throw MilestoneServiceException('Unexpected error: $e');
    }
  }

  Future<void> deleteMilestone(String id) async {
    try {
      await _api.delete<void>('/milestones/$id');
    } on DioException catch (e) {
      throw MilestoneServiceException(extractDioErrorMessage(e));
    } on MilestoneServiceException {
      rethrow;
    } catch (e) {
      throw MilestoneServiceException('Unexpected error: $e');
    }
  }
}
