import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../models/leaderboard_model.dart';
import '../../core/constants/api_constants.dart';

class LeaderboardService {
  final ApiClient _client;

  LeaderboardService(this._client);

  Future<List<LeaderboardEntryModel>> getLeaderboard() async {
    try {
      final response = await _client.get(ApiConstants.leaderboard);
      final list = response.data as List;
      return list.map((e) => LeaderboardEntryModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<UserPositionModel> getMyPosition() async {
    try {
      final response = await _client.get(ApiConstants.leaderboardMe);
      return UserPositionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
