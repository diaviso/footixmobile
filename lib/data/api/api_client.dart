import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_constants.dart';

class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _token;

  // Callback to trigger logout on 401, with optional message from backend
  void Function(String? message)? onUnauthorized;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // If no in-memory token, try reading from storage once
        if (_token == null) {
          final stored = await _storage.read(key: AppConstants.tokenKey);
          if (stored != null && stored.isNotEmpty) {
            _token = stored;
          }
        }
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        if (kDebugMode) {
          debugPrint('[ApiClient] ${options.method} ${options.path} '
              '| token=${_token != null ? "present(${_token!.substring(0, 10)}...)" : "ABSENT"}');
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 && _token != null) {
          // Only clear & notify if we actually had a token (real session expiry)
          final hadToken = _token;
          // Extract backend error message for session-expired context
          String? backendMessage;
          if (error.response?.data is Map) {
            backendMessage = (error.response!.data as Map<String, dynamic>)['message'] as String?;
          }
          await clearToken();
          if (hadToken != null) {
            onUnauthorized?.call(backendMessage);
          }
        }
        return handler.next(error);
      },
    ));

    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ));
    }
  }

  Future<void> setToken(String token) async {
    _token = token;
    await _storage.write(key: AppConstants.tokenKey, value: token);
  }

  Future<void> clearToken() async {
    _token = null;
    await _storage.delete(key: AppConstants.tokenKey);
  }

  Future<String?> getToken() async {
    _token ??= await _storage.read(key: AppConstants.tokenKey);
    return _token;
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.get<T>(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
  }) {
    return _dio.post<T>(path, data: data);
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
  }) {
    return _dio.put<T>(path, data: data);
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
  }) {
    return _dio.patch<T>(path, data: data);
  }

  Future<Response<T>> delete<T>(String path) {
    return _dio.delete<T>(path);
  }

  Future<Response<T>> uploadFile<T>(
    String path,
    FormData formData,
  ) {
    return _dio.post<T>(
      path,
      data: formData,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );
  }

  String get baseUrl => ApiConstants.baseUrl;

  String get authHeader => _token != null ? 'Bearer $_token' : '';
}
