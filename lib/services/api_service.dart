import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

class ApiResponse<T> {
  final int code;
  final bool status;
  final String? message;
  final T? data;

  ApiResponse({
    required this.code,
    required this.status,
    this.message,
    this.data,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse<T>(
      code: json['code'] is int ? json['code'] : int.tryParse(json['code']?.toString() ?? '200') ?? 200,
      status: json['status'] == true,
      message: json['message']?.toString(),
      data: json['data'] != null && fromJsonT != null ? fromJsonT(json['data']) : json['data'] as T?,
    );
  }
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late Dio _dio;
  String? _token;

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiUrl,
        connectTimeout: const Duration(seconds: 25),
        receiveTimeout: const Duration(seconds: 25),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      },
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_token != null && _token!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_token';
            options.headers['token'] = _token;
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            await clearToken();
          }
          return handler.next(error);
        },
      ),
    );
  }

  void updateBaseUrl(String newUrl) {
    AppConfig.apiUrl = newUrl;
    _dio.options.baseUrl = newUrl;
  }

  void setToken(String? token) {
    _token = token;
  }

  String? get token => _token;

  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.accessToken, token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(StorageKeys.accessToken);
    await prefs.remove(StorageKeys.userProfile);
    await prefs.remove(StorageKeys.serverUrl);
  }

  Future<String?> loadSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(StorageKeys.accessToken);
    return _token;
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(path, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put(path, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(path, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException error) {
    if (error.response?.data != null) {
      final data = error.response!.data;
      if (data is Map) {
        final message = data['message'] ?? data['error'];
        final detail = data['data'] != null ? ' (${data['data']})' : '';
        if (message != null) return '$message$detail';
      } else if (data is String && data.isNotEmpty) {
        return data;
      }
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check backend server status.';
      case DioExceptionType.connectionError:
        return 'Cannot connect to server at ${AppConfig.apiUrl}. Ensure backend is running.';
      default:
        return error.message ?? 'Network request failed';
    }
  }
}
