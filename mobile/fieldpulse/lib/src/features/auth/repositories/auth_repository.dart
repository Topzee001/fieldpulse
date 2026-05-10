import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:fieldpulse/src/features/auth/models/auth_exception.dart';
import 'package:fieldpulse/src/features/auth/models/auth_response.dart';
import 'package:fieldpulse/src/features/auth/models/user.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  final LocalAuthentication _localAuth = LocalAuthentication();

  AuthRepository(this._dio, this._storage);

  Future<String> _getDeviceId() async {
    String? deviceId = await _storage.read(key: 'device_id');
    if (deviceId == null) {
      deviceId = '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(100000)}';
      await _storage.write(key: 'device_id', value: deviceId);
    }
    return deviceId;
  }

  Future<AuthResponse> login(String email, String password) async {
    try {
      final deviceId = await _getDeviceId();
      final response = await _dio.post(
        'auth/login/',
        data: {
          'email': email, 
          'password': password,
          'device_id': deviceId,
        },
      );
      final dynamic responseData = response.data;
      final Map<String, dynamic> data = responseData is String
          ? jsonDecode(responseData) as Map<String, dynamic>
          : responseData as Map<String, dynamic>;
      final accessToken = data['access'];
      final refreshToken = data['refresh'];
      final user = User.fromJson(data['user'] as Map<String, dynamic>);

      await _storage.write(key: 'access_token', value: accessToken);
      await _storage.write(key: 'refresh_token', value: refreshToken);
      await _storage.write(key: 'user', value: jsonEncode(user.toJson()));
      await _storage.write(key: 'saved_email', value: email);

      try {
        // Automatically enable biometrics on the backend for returning users
        await _dio.post(
          'auth/biometric/toggle/',
          data: {
            'enable': true,
            'password': password,
          },
        );
      } catch (_) {
        // Silently fail if we can't enable biometrics; manual login still succeeds
      }

      return AuthResponse(
        user: user,
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    } on DioException catch (e) {
      String errorMessage = 'Login failed';
      final responseData = e.response?.data;
      if (responseData is Map<String, dynamic> && responseData['detail'] != null) {
        errorMessage = responseData['detail'].toString();
      } else if (responseData is String) {
        errorMessage = responseData.length > 100 ? 'Server Error' : responseData;
      }
      throw AuthException(errorMessage);
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  Future<AuthResponse> biometricLogin() async {
    try {
      final email = await _storage.read(key: 'saved_email');
      if (email == null) {
        throw AuthException('No saved user found. Please login with password first.');
      }

      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      if (!canCheckBiometrics || !isDeviceSupported) {
        throw AuthException('Biometrics not available on this device.');
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to log in',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );

      if (!authenticated) {
        throw AuthException('Biometric authentication failed.');
      }

      final deviceId = await _getDeviceId();
      final response = await _dio.post(
        'auth/biometric/login/',
        data: {
          'email': email,
          'device_id': deviceId,
          'biometric_enabled': true,
        },
      );
      
      final dynamic responseData = response.data;
      final Map<String, dynamic> data = responseData is String
          ? jsonDecode(responseData) as Map<String, dynamic>
          : responseData as Map<String, dynamic>;
          
      final accessToken = data['access'];
      final refreshToken = data['refresh'];
      final user = User.fromJson(data['user'] as Map<String, dynamic>);

      await _storage.write(key: 'access_token', value: accessToken);
      await _storage.write(key: 'refresh_token', value: refreshToken);
      await _storage.write(key: 'user', value: jsonEncode(user.toJson()));

      return AuthResponse(
        user: user,
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    } on DioException catch (e) {
      String errorMessage = 'Biometric login failed';
      final responseData = e.response?.data;
      if (responseData is Map<String, dynamic> && responseData['detail'] != null) {
        errorMessage = responseData['detail'].toString();
      } else if (responseData is String) {
        errorMessage = responseData.length > 100 ? 'Server Error' : responseData;
      }
      throw AuthException(errorMessage);
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  Future<void> logout() async {
    final refreshToken = await _storage.read(key: 'refresh_token');
    if (refreshToken != null) {
      await _dio.post('/auth/logout', data: {'refresh': refreshToken});
    }
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'user');
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: 'refresh_token');
  }

  Future<User?> getCurrentUser() async {
    final userJson = await _storage.read(key: 'user');
    if (userJson == null) return null;
    return User.fromJson(jsonDecode(userJson));
  }

  Future<bool> refreshToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) return false;
    try {
      final response = await _dio.post(
        '/auth/refresh/',
        data: {'refresh': refreshToken},
      );
      final newAccessToken = response.data['access'];
      final newRefreshToken = response.data['refresh'];
      await _storage.write(key: 'access_token', value: newAccessToken);
      if (newRefreshToken != null) {
        await _storage.write(key: 'refresh_token', value: newRefreshToken);
      }
      return true;
    } on DioException catch (e) {
      return false;
    }
  }
}
