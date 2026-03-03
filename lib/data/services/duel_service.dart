import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../models/duel_model.dart';

class DuelService {
  final ApiClient _client;

  DuelService(this._client);

  Future<DuelModel> create({
    required int maxParticipants,
    required String difficulty,
  }) async {
    try {
      final response = await _client.post('/duels', data: {
        'maxParticipants': maxParticipants,
        'difficulty': difficulty,
      });
      return DuelModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<DuelModel> join(String code) async {
    try {
      final response = await _client.post('/duels/join', data: {
        'code': code.toUpperCase(),
      });
      return DuelModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<DuelListItem>> getMyDuels() async {
    try {
      final response = await _client.get('/duels/my');
      final list = response.data as List;
      return list
          .map((e) => DuelListItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<DuelModel> getDuel(String id) async {
    try {
      final response = await _client.get('/duels/$id');
      return DuelModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<DuelQuestionsResponse> getQuestions(String id) async {
    try {
      final response = await _client.get('/duels/$id/questions');
      return DuelQuestionsResponse.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> launch(String id) async {
    try {
      final response = await _client.post('/duels/$id/launch');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> submit({
    required String duelId,
    required Map<String, List<String>> answers,
  }) async {
    try {
      final response = await _client.post('/duels/submit', data: {
        'duelId': duelId,
        'answers': answers,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> leave(String id) async {
    try {
      final response = await _client.delete('/duels/$id/leave');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
