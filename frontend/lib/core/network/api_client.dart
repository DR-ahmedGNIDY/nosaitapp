import 'package:basketball_academy/core/constants/app_constants.dart';
import 'package:basketball_academy/core/errors/exceptions.dart';
import 'package:basketball_academy/core/navigation/app_navigator.dart';
import 'package:basketball_academy/core/network/token_manager.dart';
import 'package:basketball_academy/core/widgets/platform_blocked_dialog.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class ApiClient {
  late final Dio _dio;
  final TokenManager _tokenManager;

  ApiClient(this._tokenManager) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout:
            const Duration(milliseconds: AppConstants.connectTimeout),
        receiveTimeout:
            const Duration(milliseconds: AppConstants.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(_AuthInterceptor(_tokenManager, _dio));
    _dio.interceptors.add(_SaasBlockInterceptor());

    if (kDebugMode) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: false,
          requestBody: true,
          responseBody: true,
          error: true,
          compact: true,
        ),
      );
    }
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(path,
          queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(path,
          data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(path,
          data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(path,
          data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch<T>(path,
          data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<Response<T>> postMultipart<T>(
    String path, {
    required FormData data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options ?? Options(contentType: 'multipart/form-data'),
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<Response<T>> putMultipart<T>(
    String path, {
    required FormData data,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        options: options ?? Options(contentType: 'multipart/form-data'),
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  AppException _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const TimeoutException();
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = (e.response?.data is Map)
            ? (e.response?.data['message'] as String? ?? 'خطأ في الخادم')
            : 'خطأ في الخادم';
        if (statusCode == 401) return UnauthorizedException(message: message);
        if (statusCode == 403) return UnauthorizedException(message: message);
        if (statusCode == 404) return const NotFoundException();
        if (statusCode == 422) return ValidationException(message: message);
        return ServerException(message: message, statusCode: statusCode);
      default:
        return AppException(message: e.message ?? 'حدث خطأ غير متوقع');
    }
  }
}

class _AuthInterceptor extends Interceptor {
  final TokenManager _tokenManager;
  final Dio _dio;
  _AuthInterceptor(this._tokenManager, this._dio);

  static const _retriedKey = 'auth_retried';

  /// تجديد واحد مشترك: لو انتهت الجلسة وأُرسلت عدة طلبات معاً، كلها تنتظر نفس
  /// نداء /auth/refresh بدل أن يرسل كل طلب تجديداً خاصاً به.
  Future<bool>? _refreshing;

  /// يجدّد توكن جلسة المدير بالـ refresh token. يعيد true عند النجاح.
  Future<bool> _refresh() {
    return _refreshing ??= () async {
      try {
        final refreshToken = await _tokenManager.getRefreshToken();
        if (refreshToken == null || refreshToken.isEmpty) return false;
        // Dio مستقل بلا interceptors حتى لا يدخل التجديد في حلقة.
        final plain = Dio(BaseOptions(
          baseUrl: _dio.options.baseUrl,
          connectTimeout: _dio.options.connectTimeout,
          receiveTimeout: _dio.options.receiveTimeout,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
          },
        ));
        final res = await plain.post<Map<String, dynamic>>(
          '/auth/refresh',
          data: {'refreshToken': refreshToken},
        );
        final token = res.data?['token'] as String?;
        final newRefresh = res.data?['refreshToken'] as String?;
        if (token == null || token.isEmpty) return false;
        await _tokenManager.saveToken(token);
        if (newRefresh != null && newRefresh.isNotEmpty) {
          await _tokenManager.saveRefreshToken(newRefresh);
        }
        if (kDebugMode) debugPrint('[AUTH] session refreshed ✓');
        return true;
      } catch (e) {
        if (kDebugMode) debugPrint('[AUTH] refresh failed: $e');
        return false;
      } finally {
        _refreshing = null;
      }
    }();
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenManager.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // ⚠️ مسح التوكن عند أي 401 كان يُسقط الجلسة صامتاً: نداء واحد إلى مسار
      // لا يخصّ نوع الجلسة (مثل مسار مدراء بتوكن لاعب) كان يمحو توكن اللاعب
      // فيفشل كل ما بعده. نمسح فقط إذا كان الرفض من مسار يخصّ هذه الجلسة —
      // أي أن التوكن نفسه هو المرفوض حقاً.
      final path = err.requestOptions.path;
      final sessionType = await _tokenManager.getSessionType();
      final isPlayerSession = sessionType == 'player';
      final belongsToSession = isPlayerSession
          ? (path.startsWith('/player') || path.startsWith('/auth/player'))
          : !(path.startsWith('/player') || path.startsWith('/auth/player'));

      // جلسة مدير انتهى توكنها: نجدّدها مرة واحدة ثم نعيد نفس الطلب.
      final canRefresh = belongsToSession &&
          !isPlayerSession &&
          !path.startsWith('/auth/login') &&
          !path.startsWith('/auth/refresh') &&
          err.requestOptions.extra[_retriedKey] != true;
      if (canRefresh && await _refresh()) {
        try {
          final opts = err.requestOptions..extra[_retriedKey] = true;
          final token = await _tokenManager.getToken();
          opts.headers['Authorization'] = 'Bearer $token';
          return handler.resolve(await _dio.fetch(opts));
        } on DioException catch (e) {
          return handler.next(e);
        }
      }

      if (belongsToSession) {
        await _tokenManager.clearToken();
      }
    }
    handler.next(err);
  }
}

/// يلتقط ردود حظر منصة Nosait (403 مع code) ويعرض حواراً موحّداً فيه زر واتساب،
/// ثم يترك الخطأ يمرّ كالمعتاد حتى توقف الشاشة العملية. إضافي وغير كاسر.
class _SaasBlockInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final data = err.response?.data;
    if (err.response?.statusCode == 403 && data is Map) {
      final code = data['code'];
      final message = (data['message'] as String?) ?? '';
      final ctx = rootNavigatorKey.currentContext;
      if (ctx != null) {
        if (code == 'SUBSCRIPTION_EXPIRED') {
          PlatformBlockedDialog.show(
            ctx,
            title: 'انتهى اشتراك الأكاديمية',
            message: message.isNotEmpty
                ? message
                : 'انتهى اشتراك الأكاديمية. يرجى التواصل مع إدارة Nosait لتفعيل الاشتراك.',
          );
        } else if (code == 'PLAYER_LIMIT_REACHED') {
          PlatformBlockedDialog.show(
            ctx,
            title: 'الحد الأقصى للاعبين',
            message: message.isNotEmpty
                ? message
                : 'لقد وصلت إلى الحد الأقصى للفترة التجريبية.',
          );
        }
      }
    }
    handler.next(err);
  }
}
