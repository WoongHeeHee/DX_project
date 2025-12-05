import 'dart:io';
import 'package:dio/dio.dart';
import '../models/menu_model.dart';
import '../models/shop_model.dart';
import 'api_service.dart';

class SearchService {
  final ApiService _apiService;

  SearchService(this._apiService);

  // 이미지/텍스트 검색
  Future<Map<String, dynamic>> searchMenu({
    File? imageFile,
    String? text,
    double? lat,
    double? lng,
  }) async {
    try {
      final formData = FormData();
      
      if (imageFile != null) {
        formData.files.add(
          MapEntry(
            'image',
            await MultipartFile.fromFile(imageFile.path),
          ),
        );
      }
      
      if (text != null && text.isNotEmpty) {
        formData.fields.add(MapEntry('text', text));
      }

      final response = await _apiService.post(
        '/search/image',
        data: formData,
      );

      final data = response.data as Map<String, dynamic>;
      return {
        'menu': data['menu'] != null
            ? MenuModel.fromJson(data['menu'] as Map<String, dynamic>)
            : null,
        'shops': data['shops'] != null
            ? (data['shops'] as List<dynamic>)
                .map((json) => ShopModel.fromJson(json))
                .toList()
            : <ShopModel>[],
      };
    } catch (e) {
      rethrow;
    }
  }
}

