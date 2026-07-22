import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../screens/login_screen.dart';

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
  static const String devBaseUrl  = 'https://stallconnect.com';
  static const String prodBaseUrl = 'https://stallconnect.com';
  static String get baseUrl => kDebugMode ? devBaseUrl : prodBaseUrl;

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
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
        // ── 1. Attach JWT token ───────────────────────────────────────
        final token = await _storage.read(key: 'jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        // ── 2. Auto-attach event_id to all stall_owner API calls ──────
        // Debug: always print the path so we can confirm interceptor runs
        if (kDebugMode) {
          print('[INTERCEPTOR] path=${options.path} | existing_qp=${options.queryParameters}');
        }

        final path = options.path;
        final isStallOwnerCall = path.contains('stall_owner');

        if (isStallOwnerCall) {
          final alreadyHasEventId = options.queryParameters.containsKey('event_id');
          if (!alreadyHasEventId) {
            final eventJson = await _storage.read(key: 'event_json');

            if (kDebugMode) {
              print('[INTERCEPTOR] event_json from storage: $eventJson');
            }

            if (eventJson != null && eventJson.isNotEmpty) {
              try {
                final event = jsonDecode(eventJson) as Map<String, dynamic>;
                final eventId = event['id']?.toString();
                if (kDebugMode) {
                  print('[INTERCEPTOR] parsed event_id: $eventId');
                }
                if (eventId != null && eventId.isNotEmpty) {
                  options.queryParameters['event_id'] = eventId;
                  if (kDebugMode) {
                    print('[INTERCEPTOR] ✅ Attached event_id=$eventId to ${options.path}');
                  }
                }
              } catch (e) {
                if (kDebugMode) {
                  print('[INTERCEPTOR] ❌ Failed to parse event_json: $e');
                }
              }
            } else {
              if (kDebugMode) {
                print('[INTERCEPTOR] ⚠️ event_json is null or empty — event_id NOT attached');
              }
            }
          } else {
            if (kDebugMode) {
              print('[INTERCEPTOR] event_id already present, skipping auto-attach');
            }
          }
        }

        handler.next(options);
      },
    ));
  }

  static void _logDebug(String message) {
    if (kDebugMode) {
      print(message);
    }
  }

  static Future<ApiResult> call(Future<Response> Function() request) async {
    try {
      final response = await request();

      if (kDebugMode) {
        final options = response.requestOptions;
        final auth = options.headers['Authorization']?.toString() ?? 'NONE';
        final maskedAuth = auth.length > 17 ? '${auth.substring(0, 17)}...' : auth;
        _logDebug('--- API DEBUG SUCCESS ---');
        _logDebug('URL: ${options.uri}');
        _logDebug('Method: ${options.method}');
        _logDebug('Request Headers: ${options.headers}');
        _logDebug('Request Body: ${options.data}');
        _logDebug('Auth Header: $maskedAuth');
        _logDebug('Status Code: ${response.statusCode}');
        _logDebug('Raw Body: ${response.data}');
      }

      ApiResult result;
      if (response.statusCode == 401) {
        await deleteToken();
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
        );
        return ApiResult(
            success: false, error: 'Your session has expired. Please log in again.');
      }

      if (response.data is Map<String, dynamic>) {
        result = ApiResult.fromResponse(response.data);
      } else {
        result = ApiResult(success: false, error: 'Unexpected response from server');
      }

      if (kDebugMode) {
        _logDebug('Parsed Success: ${result.success}');
        _logDebug('Parsed Error: ${result.error}');
        _logDebug('Data Type: ${result.data.runtimeType}');
        _logDebug('--- DEBUG END ---');
      }

      return result;
    } on DioException catch (e) {
      if (kDebugMode) {
        final options = e.requestOptions;
        final auth = options.headers['Authorization']?.toString() ?? 'NONE';
        final maskedAuth = auth.length > 17 ? '${auth.substring(0, 17)}...' : auth;
        _logDebug('--- API DEBUG DIO_ERROR ---');
        _logDebug('URL: ${options.uri}');
        _logDebug('Method: ${options.method}');
        _logDebug('Request Headers: ${options.headers}');
        _logDebug('Request Body: ${options.data}');
        _logDebug('Auth Header: $maskedAuth');
        _logDebug('Status Code: ${e.response?.statusCode}');
        _logDebug('Raw Body: ${e.response?.data}');
      }

      ApiResult result;
      if (e.response?.statusCode == 401) {
        await deleteToken();
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
        );
        return ApiResult(
            success: false, error: 'Your session has expired. Please log in again.');
      }

      if (e.response?.data is Map<String, dynamic>) {
        result = ApiResult.fromResponse(e.response!.data);
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError) {
        result = ApiResult(success: false, error: 'Cannot reach server. Check it is running.');
      } else {
        result = ApiResult(success: false, error: 'Network error: ${e.message}');
      }

      if (kDebugMode) {
        _logDebug('Parsed Success: ${result.success}');
        _logDebug('Parsed Error: ${result.error}');
        _logDebug('Data Type: ${result.data?.runtimeType}');
        _logDebug('--- DEBUG END ---');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        _logDebug('--- API DEBUG UNEXPECTED_ERROR ---');
        _logDebug('Error: $e');
      }
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