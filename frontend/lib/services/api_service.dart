/// VisionMate AI - API Service

import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/detection_result.dart';
import '../utils/constants.dart';

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  Future<Dio> get _dio async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString(AppConstants.keyApiBaseUrl) ?? AppConstants.defaultApiUrl;
    return Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ));
  }

  Future<DetectApiResponse> detectObjects({
    required String imageB64,
    String lang = 'en',
    bool includeAnnotated = false,
  }) async {
    final dio = await _dio;
    final response = await dio.post('/detect/', data: {
      'image': imageB64,
      'lang': lang,
      'include_annotated': includeAnnotated,
    });
    return DetectApiResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getSceneSummary({
    required List<Map<String, dynamic>> detections,
    String lang = 'en',
  }) async {
    final dio = await _dio;
    final response = await dio.post('/scene-summary/', data: {
      'detections': detections,
      'lang': lang,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> readText({
    required String imageB64,
    String mode = 'auto',
    List<String> languages = const ['en'],
    String lang = 'en',
  }) async {
    final dio = await _dio;
    final response = await dio.post('/ocr/', data: {
      'image': imageB64,
      'mode': mode,
      'languages': languages,
      'lang': lang,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> sendSpeechCommand({
    required Uint8List audioBytes,
    String language = 'en',
    String lang = 'en',
  }) async {
    final dio = await _dio;
    final formData = FormData.fromMap({
      'audio': MultipartFile.fromBytes(audioBytes, filename: 'command.wav'),
      'language': language,
      'lang': lang,
    });
    final response = await dio.post(
      '/speech-command/',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getNavigation({
    required double lat,
    required double lng,
    required String destination,
    String mode = 'walking',
    String lang = 'en',
  }) async {
    final dio = await _dio;
    final response = await dio.post('/navigation/', data: {
      'origin_lat': lat,
      'origin_lng': lng,
      'destination': destination,
      'mode': mode,
      'lang': lang,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> sendSOS({
    required double lat,
    required double lng,
    String? contactNumber,
    String lang = 'en',
  }) async {
    final dio = await _dio;
    final response = await dio.post('/sos/', data: {
      'latitude': lat,
      'longitude': lng,
      if (contactNumber != null) 'contact_number': contactNumber,
      'lang': lang,
    });
    return response.data as Map<String, dynamic>;
  }
}
