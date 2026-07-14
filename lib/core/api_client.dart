import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiResult {
  final bool success;
  final dynamic data;
  final Map<String, dynamic>? meta;
  final String? error;

  ApiResult({required this.success, this.data, this.meta, this.error});

  factory ApiResult.fromResponse(Map<String, dynamic> json) {
    return ApiResult(
      success: json['success'] == true,
      data: json['data'],
      meta: json['meta'] is Map<String, dynamic> ? json['meta'] : null,
      error: json['error']?.toString(),
    );
  }
}

class ApiClient {
  static const baseUrl = 'http://86.48.3.78';

  static final _storage = const FlutterSecureStorage();
  static late Dio dio;

  static void init() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      },
      validateStatus: (status) => status != null && status < 500,
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  static Future<ApiResult> call(Future<Response> Function() request) async {
    try {
      final response = await request();
      
      final options = response.requestOptions;
      final auth = options.headers['Authorization']?.toString() ?? 'NONE';
      final maskedAuth = auth.length > 17 ? '${auth.substring(0, 17)}...' : auth;
      
      print('--- API DEBUG SUCCESS ---');
      print('URL: ${options.uri}');
      print('Method: ${options.method}');
      print('Request Headers: ${options.headers}');
      print('Request Body: ${options.data}');
      print('Auth Header: $maskedAuth');
      print('Status Code: ${response.statusCode}');
      print('Raw Body: ${response.data}');

      ApiResult result;
      if (response.data is Map<String, dynamic>) {
        result = ApiResult.fromResponse(response.data);
      } else {
        result = ApiResult(success: false, error: 'Unexpected response from server');
      }

      print('Parsed Success: ${result.success}');
      print('Parsed Error: ${result.error}');
      print('Data Type: ${result.data.runtimeType}');
      print('--- DEBUG END ---');

      return result;
    } on DioException catch (e) {
      final options = e.requestOptions;
      final auth = options.headers['Authorization']?.toString() ?? 'NONE';
      final maskedAuth = auth.length > 17 ? '${auth.substring(0, 17)}...' : auth;

      print('--- API DEBUG DIO_ERROR ---');
      print('URL: ${options.uri}');
      print('Method: ${options.method}');
      print('Request Headers: ${options.headers}');
      print('Request Body: ${options.data}');
      print('Auth Header: $maskedAuth');
      print('Status Code: ${e.response?.statusCode}');
      print('Raw Body: ${e.response?.data}');

      ApiResult result;
      if (e.response?.data is Map<String, dynamic>) {
        result = ApiResult.fromResponse(e.response!.data);
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError) {
        result = ApiResult(success: false, error: 'Cannot reach server. Check it is running.');
      } else {
        result = ApiResult(success: false, error: 'Network error: ${e.message}');
      }

      print('Parsed Success: ${result.success}');
      print('Parsed Error: ${result.error}');
      print('Data Type: ${result.data?.runtimeType}');
      print('--- DEBUG END ---');

      return result;
    } catch (e) {
      print('--- API DEBUG UNEXPECTED_ERROR ---');
      print('Error: $e');
      return ApiResult(success: false, error: 'Unexpected error: $e');
    }
  }

  static Future<ApiResult> createManualLead(Map<String, dynamic> data) async {
    return call(() => dio.post('/api/v1/stall_owner/manual_create_lead', data: data));
  }

  static Future<void> saveToken(String token) async =>
      _storage.write(key: 'jwt_token', value: token);

  static Future<String?> getToken() async =>
      _storage.read(key: 'jwt_token');

  static Future<void> deleteToken() async =>
      _storage.delete(key: 'jwt_token');

  static Future<void> saveStallOwnerJson(String json) async =>
      _storage.write(key: 'stall_owner_json', value: json);

  static Future<String?> getStallOwnerJson() async =>
      _storage.read(key: 'stall_owner_json');

  static Future<void> saveEventJson(String json) async =>
      _storage.write(key: 'event_json', value: json);

  static Future<String?> getEventJson() async =>
      _storage.read(key: 'event_json');
}