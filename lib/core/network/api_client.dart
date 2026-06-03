import 'package:dio/dio.dart';
import '../config/env.dart';
import '../storage/secure_storage.dart';

class ApiClient {
  ApiClient._();

  static Dio? _instance;

  static Dio get instance {
    _instance ??= _build();
    return _instance!;
  }

  static Dio _build() {
    final dio = Dio(BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(_AuthInterceptor(dio));
    return dio;
  }

  // Auth helpers
  static Future<Response> post(String path, Map<String, dynamic> data) =>
      instance.post(path, data: data);

  static Future<Response> get(String path, {Map<String, dynamic>? params}) =>
      instance.get(path, queryParameters: params);

  static Future<Response> put(String path, [Map<String, dynamic>? data]) =>
      instance.put(path, data: data);

  static Future<Response> patch(String path, [Map<String, dynamic>? data]) =>
      instance.patch(path, data: data);

  static Future<Response> delete(String path) => instance.delete(path);
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._dio);
  final Dio _dio;
  bool _isRefreshing = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await SecureStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshToken = await SecureStorage.getRefreshToken();
        if (refreshToken == null) {
          await SecureStorage.clearAll();
          handler.next(err);
          return;
        }

        final res = await _dio.post(
          '/api/auth/refresh',
          data: {'refreshToken': refreshToken},
          options: Options(headers: {'Authorization': ''}),
        );

        final data = res.data['data'];
        await SecureStorage.saveTokens(
          accessToken:  data['accessToken'],
          refreshToken: data['refreshToken'],
        );
        await SecureStorage.saveUser(Map<String, dynamic>.from(data['user']));

        // Retry original request
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer ${data['accessToken']}';
        final retried = await _dio.fetch(opts);
        handler.resolve(retried);
      } catch (_) {
        await SecureStorage.clearAll();
        handler.next(err);
      } finally {
        _isRefreshing = false;
      }
    } else {
      handler.next(err);
    }
  }
}
