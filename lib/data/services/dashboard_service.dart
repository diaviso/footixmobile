import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../models/dashboard_model.dart';
import '../../core/constants/api_constants.dart';

class DashboardService {
  final ApiClient _client;

  DashboardService(this._client);

  Future<UserStatsModel> getUserStats() async {
    try {
      final response = await _client.get(ApiConstants.dashboardUserStats);
      return UserStatsModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await _client.get(ApiConstants.dashboardStats);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> getUserProgress() async {
    try {
      final response = await _client.get(ApiConstants.dashboardProgress);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
