import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';

class NotificationService {
  final ApiClient _client;

  NotificationService(this._client);

  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final response = await _client.get('/notifications');
      final list = response.data as List;
      return list.map((e) => e as Map<String, dynamic>).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _client.get('/notifications/unread-count');
      return response.data as int;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _client.post('/notifications/$id/read');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _client.post('/notifications/read-all');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
