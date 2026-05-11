import 'package:dio/dio.dart';
import 'package:fieldpulse/src/app/providers/secure_storage_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://localhost:8000/api/',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final storage = ref.read(secureStorageProvider);
        final token = await storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Token expired – attempt refresh
          final storage = ref.read(secureStorageProvider);
          final refreshToken = await storage.read(key: 'refresh_token');
          if (refreshToken != null) {
            try {
              final refreshDio = Dio();
              final response = await refreshDio.post(
                'http://localhost:8000/api/auth/refresh/',
                data: {'refresh': refreshToken},
              );
              final newAccess = response.data['access'];
              await storage.write(key: 'access_token', value: newAccess);
              // Retry original request
              error.requestOptions.headers['Authorization'] =
                  'Bearer $newAccess';
              final retryResponse = await dio.fetch(error.requestOptions);
              return handler.resolve(retryResponse);
            } catch (e) {
              // Refresh failed – logout
              // await storage.deleteAll();
              await storage.delete(key: 'access_token');
              await storage.delete(key: 'refresh_token');
              await storage.delete(key: 'user');
              return handler.reject(error);
            }
          }
        }
        return handler.next(error);
      },
    ),
  );
  return dio;
});
