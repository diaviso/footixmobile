import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../models/quiz_model.dart';
import '../../core/constants/api_constants.dart';

class QuizzesService {
  final ApiClient _client;

  QuizzesService(this._client);

  Future<List<QuizModel>> getQuizzes() async {
    try {
      final response = await _client.get(ApiConstants.quizzes);
      // Handle both paginated response { data: [...] } and direct array response
      final List list;
      if (response.data is List) {
        list = response.data as List;
      } else if (response.data is Map && response.data['data'] is List) {
        list = response.data['data'] as List;
      } else {
        list = [];
      }
      return list.map((e) => QuizModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<QuizModel>> getQuizzesWithStatus() async {
    try {
      final response = await _client.get(ApiConstants.quizzesWithStatus);
      final list = response.data as List;
      return list.map((e) => QuizModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<QuizModel> getQuiz(String id) async {
    try {
      final response = await _client.get('${ApiConstants.quizzes}/$id');
      return QuizModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> getQuizAttempts(String quizId) async {
    try {
      final response = await _client.get('${ApiConstants.quizzes}/$quizId/attempts');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<QuizAttemptModel>> getUserAttempts() async {
    try {
      final response = await _client.get(ApiConstants.quizAttempts);
      final list = response.data as List;
      return list.map((e) => QuizAttemptModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<QuizSubmitResult> submitQuiz({
    required String quizId,
    required List<Map<String, dynamic>> answers,
  }) async {
    try {
      final response = await _client.post(ApiConstants.submitQuiz, data: {
        'quizId': quizId,
        'answers': answers,
      });
      return QuizSubmitResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<QuizModel> getQuizCorrection(String quizId) async {
    try {
      final response = await _client.get('${ApiConstants.quizzes}/$quizId/correction');
      return QuizModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> checkQuizAccess(String quizId) async {
    try {
      final response = await _client.get('${ApiConstants.quizzes}/$quizId/access');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> purchaseExtraAttempt(String quizId) async {
    try {
      final response = await _client.post(
        ApiConstants.purchaseAttempt,
        data: {'quizId': quizId},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
