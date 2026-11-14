import 'package:dio/dio.dart';

import '../models/usuario.dart';
import 'api_client.dart';

class LoginResult {
  const LoginResult({required this.token, required this.usuario});

  final String token;
  final Usuario usuario;
}

/// Llamadas HTTP de autenticacion (usa Dio). Ningun widget llama a Dio directamente.
class AuthService {
  AuthService({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  /// POST /auth/login
  Future<LoginResult> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      final data = response.data as Map<String, dynamic>;
      return LoginResult(
        token: data['access_token'] as String,
        usuario: Usuario.fromJson(data['usuario'] as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// GET /auth/me  (requiere token). Sirve para validar que la sesion sigue vigente.
  Future<Usuario> me() async {
    try {
      final response = await _dio.get('/auth/me');
      return Usuario.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
