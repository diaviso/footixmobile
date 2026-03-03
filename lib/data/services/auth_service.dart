import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../models/user_model.dart';
import '../../core/constants/api_constants.dart';

class AuthService {
  final ApiClient _client;

  AuthService(this._client);

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final response = await _client.post(ApiConstants.register, data: {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<({String token, UserModel user})> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _client.post(ApiConstants.verifyEmail, data: {
        'email': email,
        'code': code,
      });
      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      return (token: token, user: user);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> resendVerification({required String email}) async {
    try {
      await _client.post(ApiConstants.resendVerification, data: {'email': email});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<({String token, UserModel user})> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.post(ApiConstants.login, data: {
        'email': email,
        'password': password,
      });
      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      return (token: token, user: user);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> forgotPassword({required String email}) async {
    try {
      await _client.post(ApiConstants.forgotPassword, data: {'email': email});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    try {
      await _client.post(ApiConstants.resetPassword, data: {
        'token': token,
        'password': password,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _client.put(ApiConstants.changePassword, data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<UserModel> getProfile() async {
    try {
      final response = await _client.get(ApiConstants.profile);
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _client.patch(ApiConstants.profile, data: data);
      final responseData = response.data as Map<String, dynamic>;
      return UserModel.fromJson(responseData['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<UserModel> uploadAvatar(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(filePath, filename: 'avatar.jpg'),
      });
      final response = await _client.uploadFile(ApiConstants.uploadAvatar, formData);
      final data = response.data as Map<String, dynamic>;
      return UserModel.fromJson(data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<UserModel> updateLeaderboardVisibility(bool show) async {
    try {
      final response = await _client.patch(
        ApiConstants.leaderboardVisibility,
        data: {'showInLeaderboard': show},
      );
      final data = response.data as Map<String, dynamic>;
      return UserModel.fromJson(data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<({String token, UserModel user})> googleLogin(String idToken) async {
    try {
      final response = await _client.post(
        ApiConstants.googleMobileLogin,
        data: {'idToken': idToken},
      );
      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      return (token: token, user: user);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteAccount() async {
    try {
      await _client.delete(ApiConstants.deleteAccount);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
