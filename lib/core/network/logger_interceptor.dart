import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LoggerInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    if (kDebugMode) {
      debugPrint("========== REQUEST ==========");
      debugPrint("METHOD : ${options.method}");
      debugPrint("URL    : ${options.uri}");
      debugPrint("Headers: ${options.headers}");

      if (options.queryParameters.isNotEmpty) {
        debugPrint("Query  : ${options.queryParameters}");
      }

      if (options.data != null) {
        debugPrint("Body   : ${options.data}");
      }

      debugPrint("=============================");
    }

    handler.next(options);
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    if (kDebugMode) {
      debugPrint("========== RESPONSE =========");
      debugPrint("STATUS : ${response.statusCode}");
      debugPrint("URL    : ${response.requestOptions.uri}");
      debugPrint("DATA   : ${response.data}");
      debugPrint("=============================");
    }

    handler.next(response);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    if (kDebugMode) {
      debugPrint("=========== ERROR ===========");
      debugPrint("URL    : ${err.requestOptions.uri}");
      debugPrint("METHOD : ${err.requestOptions.method}");
      debugPrint("ERROR  : ${err.message}");

      if (err.response != null) {
        debugPrint("STATUS : ${err.response?.statusCode}");
        debugPrint("DATA   : ${err.response?.data}");
      }

      debugPrint("=============================");
    }

    handler.next(err);
  }
}