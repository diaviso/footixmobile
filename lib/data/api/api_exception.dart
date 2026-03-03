import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException({required this.message, this.statusCode});

  factory ApiException.fromDioError(DioException error) {
    String message;
    final statusCode = error.response?.statusCode;

    if (error.response?.data is Map) {
      final data = error.response!.data as Map<String, dynamic>;
      message = data['message'] as String? ?? _defaultMessage(error.type);
    } else {
      message = _defaultMessage(error.type);
    }

    return ApiException(message: message, statusCode: statusCode);
  }

  static String _defaultMessage(DioExceptionType type) {
    switch (type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Délai de connexion dépassé. Vérifiez votre connexion internet.';
      case DioExceptionType.connectionError:
        return 'Impossible de se connecter au serveur.';
      case DioExceptionType.cancel:
        return 'Requête annulée.';
      default:
        return 'Une erreur est survenue. Veuillez réessayer.';
    }
  }

  @override
  String toString() => message;
}
