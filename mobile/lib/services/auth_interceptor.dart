import 'package:dio/dio.dart';

import 'session_storage.dart';

/// Interceptor de Dio:
///  - onRequest: agrega `Authorization: Bearer <token>` a cada peticion.
///  - onError: si la API responde 401 (token ausente, invalido o expirado),
///    avisa para cerrar la sesion y volver al login.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage, {required this.onUnauthorized});

  final SessionStorage _storage;
  final Future<void> Function(String message) onUnauthorized;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.readToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Un 401 en el login significa "credenciales incorrectas", no sesion vencida.
    final esLogin = err.requestOptions.path.endsWith('/auth/login');
    if (err.response?.statusCode == 401 && !esLogin) {
      final data = err.response?.data;
      final mensaje = (data is Map && data['message'] is String)
          ? data['message'] as String
          : 'Tu sesión ya no es válida. Inicia sesión de nuevo.';
      await onUnauthorized(mensaje);
    }
    handler.next(err);
  }
}
