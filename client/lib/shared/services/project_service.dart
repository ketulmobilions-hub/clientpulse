import 'package:dio/dio.dart';
import '../models/project.dart';
import 'api_service.dart';

class ProjectServiceException implements Exception {
  const ProjectServiceException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ProjectService {
  const ProjectService(this._api);
  final ApiService _api;

  Future<List<Project>> listProjects({bool includeArchived = false}) async {
    try {
      final res = await _api.get<Map<String, dynamic>>(
        '/projects',
        params: includeArchived ? {'include_archived': 'true'} : null,
      );
      final data = _unwrapData(res.data);
      final list = data['projects'];
      if (list is! List) throw const ProjectServiceException('Unexpected response format');
      return list.map((e) {
        if (e is! Map<String, dynamic>) {
          throw const ProjectServiceException('Unexpected response format');
        }
        return Project.fromJson(e);
      }).toList();
    } on DioException catch (e) {
      throw ProjectServiceException(_extractMessage(e));
    } on ProjectServiceException {
      rethrow;
    } catch (e) {
      throw ProjectServiceException('Unexpected error: $e');
    }
  }

  Future<Project> getProject(String id) async {
    try {
      final res = await _api.get<Map<String, dynamic>>('/projects/$id');
      final data = _unwrapData(res.data);
      final project = data['project'];
      if (project is! Map<String, dynamic>) {
        throw const ProjectServiceException('Unexpected response format');
      }
      return Project.fromJson(project);
    } on DioException catch (e) {
      throw ProjectServiceException(_extractMessage(e));
    } on ProjectServiceException {
      rethrow;
    } catch (e) {
      throw ProjectServiceException('Unexpected error: $e');
    }
  }

  Future<Project> updateProject(
    String id, {
    String? name,
    String? clientName,
    String? clientEmail,
    String? description,
    bool clearDescription = false,
    ProjectStatus? status,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? expectedEndDate,
    bool clearExpectedEndDate = false,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (clientName != null) body['client_name'] = clientName;
      if (clientEmail != null) body['client_email'] = clientEmail;
      if (clearDescription) {
        body['description'] = null;
      } else if (description != null) {
        body['description'] = description;
      }
      if (status != null) body['status'] = status.name;
      if (clearStartDate) {
        body['start_date'] = null;
      } else if (startDate != null) {
        body['start_date'] = _formatDate(startDate);
      }
      if (clearExpectedEndDate) {
        body['expected_end_date'] = null;
      } else if (expectedEndDate != null) {
        body['expected_end_date'] = _formatDate(expectedEndDate);
      }

      if (body.isEmpty) throw const ProjectServiceException('No fields to update');
      final res = await _api.patch<Map<String, dynamic>>('/projects/$id', data: body);
      final data = _unwrapData(res.data);
      final project = data['project'];
      if (project is! Map<String, dynamic>) {
        throw const ProjectServiceException('Unexpected response format');
      }
      return Project.fromJson(project);
    } on DioException catch (e) {
      throw ProjectServiceException(_extractMessage(e));
    } on ProjectServiceException {
      rethrow;
    } catch (e) {
      throw ProjectServiceException('Unexpected error: $e');
    }
  }

  static String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<Project> createProject({
    required String name,
    required String clientName,
    required String clientEmail,
    String? description,
    DateTime? startDate,
    DateTime? expectedEndDate,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        'client_name': clientName,
        'client_email': clientEmail,
        if (description != null && description.isNotEmpty) 'description': description,
        if (startDate != null) 'start_date': _formatDate(startDate),
        if (expectedEndDate != null) 'expected_end_date': _formatDate(expectedEndDate),
      };
      final res = await _api.post<Map<String, dynamic>>('/projects', data: body);
      final data = _unwrapData(res.data);
      final project = data['project'];
      if (project is! Map<String, dynamic>) {
        throw const ProjectServiceException('Unexpected response format');
      }
      return Project.fromJson(project);
    } on DioException catch (e) {
      throw ProjectServiceException(_extractMessage(e));
    } on ProjectServiceException {
      rethrow;
    } catch (e) {
      throw ProjectServiceException('Unexpected error: $e');
    }
  }

  Future<Project> archiveProject(String id) async {
    try {
      final res = await _api.post<Map<String, dynamic>>('/projects/$id/archive');
      final data = _unwrapData(res.data);
      final project = data['project'];
      if (project is! Map<String, dynamic>) {
        throw const ProjectServiceException('Unexpected response format');
      }
      return Project.fromJson(project);
    } on DioException catch (e) {
      throw ProjectServiceException(_extractMessage(e));
    } on ProjectServiceException {
      rethrow;
    } catch (e) {
      throw ProjectServiceException('Unexpected error: $e');
    }
  }

  Future<Project> unarchiveProject(String id) async {
    try {
      final res = await _api.post<Map<String, dynamic>>('/projects/$id/unarchive');
      final data = _unwrapData(res.data);
      final project = data['project'];
      if (project is! Map<String, dynamic>) {
        throw const ProjectServiceException('Unexpected response format');
      }
      return Project.fromJson(project);
    } on DioException catch (e) {
      throw ProjectServiceException(_extractMessage(e));
    } on ProjectServiceException {
      rethrow;
    } catch (e) {
      throw ProjectServiceException('Unexpected error: $e');
    }
  }

  Future<void> deleteProject(String id) async {
    try {
      await _api.delete<Map<String, dynamic>>('/projects/$id');
    } on DioException catch (e) {
      throw ProjectServiceException(_extractMessage(e));
    } catch (e) {
      throw ProjectServiceException('Unexpected error: $e');
    }
  }

  static Map<String, dynamic> _unwrapData(dynamic responseData) {
    if (responseData is! Map<String, dynamic>) {
      throw const ProjectServiceException('Unexpected response format');
    }
    final data = responseData['data'];
    if (data is! Map<String, dynamic>) {
      throw const ProjectServiceException('Unexpected response format');
    }
    return data;
  }

  static String _extractMessage(DioException e) {
    final body = e.response?.data;
    if (body is Map<String, dynamic>) {
      final err = body['error'];
      if (err is Map<String, dynamic>) {
        return err['message']?.toString() ?? 'Request failed';
      }
    }
    return 'Request failed';
  }
}
