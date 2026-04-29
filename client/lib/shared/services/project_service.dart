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

  Future<List<Project>> listProjects() async {
    try {
      final res = await _api.get<Map<String, dynamic>>('/projects');
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

  Future<Project> createProject({
    required String name,
    required String clientName,
    required String clientEmail,
    String? description,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        'client_name': clientName,
        'client_email': clientEmail,
        if (description != null && description.isNotEmpty) 'description': description,
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
