import 'package:dio/dio.dart';
import 'auth_interceptor.dart';
import '../config/app_config.dart';
import 'logger_interceptor.dart';

class DioClient {
  static final Dio dio =
      Dio(
          BaseOptions(
            baseUrl: AppConfig.baseUrl,
            connectTimeout: AppConfig.connectTimeout,
            receiveTimeout: AppConfig.receiveTimeout,
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
          ),
        )
        ..interceptors.add(AuthInterceptor())
        ..interceptors.add(LoggerInterceptor());
}
