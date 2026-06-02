import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/network/socket_service.dart';
import '../../../shared/models/user_model.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  bool _loading = false;
  String? _error;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> initialize() async {
    try {
      final userData = await SecureStorage.getUser();
      final token = await SecureStorage.getAccessToken();
      if (userData != null && token != null) {
        _user = UserModel.fromJson(userData);
        _status = AuthStatus.authenticated;
        await SocketService.connect();
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (_) {
      // Storage failure on first install — treat as unauthenticated
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> sendOtp(String phone, {String purpose = 'REGISTRATION'}) async {
    _setLoading(true);
    try {
      await ApiClient.post('/api/auth/send-otp', {'phone': phone, 'purpose': purpose});
      _error = null;
      return true;
    } on DioException catch (e) {
      _error = _extractError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String phone,
    required String otp,
    required String password,
    required String fullName,
    required String role,
  }) async {
    _setLoading(true);
    try {
      final res = await ApiClient.post('/api/auth/register', {
        'phone': phone, 'otp': otp, 'password': password,
        'fullName': fullName, 'role': role,
      });
      await _handleAuthResponse(res.data['data']);
      return true;
    } on DioException catch (e) {
      _error = _extractError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login({required String phone, required String password}) async {
    _setLoading(true);
    try {
      final res = await ApiClient.post('/api/auth/login', {
        'phone': phone, 'password': password,
      });
      await _handleAuthResponse(res.data['data']);
      return true;
    } on DioException catch (e) {
      _error = _extractError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> forgotPassword(String phone) async {
    _setLoading(true);
    try {
      await ApiClient.post('/api/auth/forgot-password', {'phone': phone});
      _error = null;
      return true;
    } on DioException catch (e) {
      _error = _extractError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword({
    required String phone,
    required String otp,
    required String newPassword,
  }) async {
    _setLoading(true);
    try {
      await ApiClient.post('/api/auth/reset-password', {
        'phone': phone, 'otp': otp, 'newPassword': newPassword,
      });
      _error = null;
      return true;
    } on DioException catch (e) {
      _error = _extractError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    final refreshToken = await SecureStorage.getRefreshToken();
    if (refreshToken != null) {
      try {
        await ApiClient.post('/api/auth/logout', {'refreshToken': refreshToken});
      } catch (_) {}
    }
    SocketService.disconnect();
    await SecureStorage.clearAll();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    try {
      final res = await ApiClient.get('/api/profile');
      _user = UserModel.fromJson(res.data['data']);
      await SecureStorage.saveUser(_user!.toJson());
      notifyListeners();
    } catch (_) {}
  }

  void updateUser(UserModel updated) {
    _user = updated;
    SecureStorage.saveUser(updated.toJson());
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> _handleAuthResponse(Map<String, dynamic> data) async {
    await SecureStorage.saveTokens(
      accessToken:  data['accessToken'],
      refreshToken: data['refreshToken'],
    );
    final userMap = Map<String, dynamic>.from(data['user'] as Map);
    _user = UserModel.fromJson(userMap);
    await SecureStorage.saveUser(userMap);
    _status = AuthStatus.authenticated;
    _error = null;
    await SocketService.connect();
    notifyListeners();
  }

  void _setLoading(bool val) {
    _loading = val;
    notifyListeners();
  }

  String _extractError(DioException e) {
    return e.response?.data?['error'] as String? ?? 'Something went wrong. Please try again.';
  }
}
