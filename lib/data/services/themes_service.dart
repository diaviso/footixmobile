import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../models/theme_model.dart';
import '../../core/constants/api_constants.dart';

class ThemesService {
  final ApiClient _client;

  ThemesService(this._client);

  Future<List<ThemeModel>> getThemes() async {
    try {
      final response = await _client.get('${ApiConstants.themes}?active=true');
      final list = response.data as List;
      return list.map((e) => ThemeModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ThemeModel> getTheme(String id) async {
    try {
      final response = await _client.get('${ApiConstants.themes}/$id');
      return ThemeModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
