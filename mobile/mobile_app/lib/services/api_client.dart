import 'package:dio/dio.dart';

import '../config/env.dart';

/// Error controlado de comunicacion con la API. Su mensaje se muestra al usuario.
class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.fieldErrors = const {},
  });

  final String message;
  final int? statusCode;

  /// Errores por campo devueltos por la API en un 422 (ej. {"precio": "..."}).
  final Map<String, String> fieldErrors;

  /// Traduce un DioException a un mensaje claro para el usuario.
  factory ApiException.fromDio(DioException e) {
    final type = e.type;

    if (type == DioExceptionType.connectionTimeout ||
        type == DioExceptionType.sendTimeout ||
        type == DioExceptionType.receiveTimeout) {
      return const ApiException('El servidor tardó demasiado en responder.');
    }
    if (type == DioExceptionType.connectionError) {
      return const ApiException(
        'No se pudo conectar con el servidor. Verifica que la API esté '
        'encendida y que la URL del .env sea correcta.',
      );
    }
    if (type == DioExceptionType.badResponse) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      var message = 'Error del servidor (${status ?? '?'}).';
      var fieldErrors = <String, String>{};
      if (data is Map) {
        final m = data['message'];
        if (m is String && m.isNotEmpty) message = m;
        final errs = data['errors'];
        if (errs is Map) {
          fieldErrors =
              errs.map((k, v) => MapEntry(k.toString(), v.toString()));
        }
      }
      return ApiException(message, statusCode: status, fieldErrors: fieldErrors);
    }
    if (type == DioExceptionType.cancel) {
      return const ApiException('La solicitud fue cancelada.');
    }
    return const ApiException('Ocurrió un error inesperado de comunicación.');
  }

  @override
  String toString() => message;
}

/// Cliente Dio unico de la app, configurado con la URL base del .env.
class ApiClient {
  ApiClient._()
      : dio = Dio(
          BaseOptions(
            baseUrl: Env.apiBaseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {'Accept': 'application/json'},
          ),
        );

  static final ApiClient instance = ApiClient._();

  final Dio dio;
}
