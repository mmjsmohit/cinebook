import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/token_storage.dart';

class ApiException implements Exception {
  final String code;
  final String message;

  ApiException(this.code, this.message);

  @override
  String toString() => 'ApiException: $code - $message';
}

class ApiClient {
  final Dio dio;
  final TokenStorage tokenStorage;
  final String baseUrl;
  final VoidCallback? onUnauthenticated;

  ApiClient({
    required this.tokenStorage,
    this.baseUrl = 'http://localhost:3000',
    this.onUnauthenticated,
  }) : dio = Dio(BaseOptions(baseUrl: baseUrl)) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final accessToken = await tokenStorage.getAccessToken();
        if (accessToken != null) {
          options.headers['Authorization'] = 'Bearer $accessToken';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
           final refreshed = await _refreshToken();
           if (refreshed) {
             try {
                // Retry the original request
                final response = await dio.fetch(e.requestOptions);
                return handler.resolve(response);
             } catch (e2) {
                // Let it fall through
             }
           }
        }
        
        // Parse error envelope: { error: { code, message } }
        if (e.response?.data != null && e.response?.data is Map) {
          final data = e.response?.data as Map;
          if (data.containsKey('error') && data['error'] is Map) {
            final errorData = data['error'] as Map;
            final code = errorData['code']?.toString() ?? 'UNKNOWN';
            final message = errorData['message']?.toString() ?? 'An unknown error occurred';
            
            return handler.reject(
              DioException(
                requestOptions: e.requestOptions,
                response: e.response,
                type: DioExceptionType.badResponse,
                error: ApiException(code, message),
              ),
            );
          }
        }
        return handler.next(e);
      },
    ));
  }

  Future<bool> _refreshToken() async {
    try {
      final refresh = await tokenStorage.getRefreshToken();
      if (refresh == null) return false;
      
      final dioRefresh = Dio(BaseOptions(baseUrl: baseUrl));
      final response = await dioRefresh.post('/auth/refresh', data: {
        'refreshToken': refresh,
      });
      
      final access = response.data['accessToken'];
      final newRefresh = response.data['refreshToken'];
      final role = response.data['role'];
      
      if (access != null && newRefresh != null) {
        await tokenStorage.saveTokens(access: access, refresh: newRefresh, role: role ?? '');
        return true;
      }
      return false;
    } catch (_) {
      await tokenStorage.clear();
      onUnauthenticated?.call();
      return false;
    }
  }
}
