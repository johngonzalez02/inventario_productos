import 'package:flutter/foundation.dart';

import '../models/usuario.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'session_storage.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Estado global de la sesion. go_router lo escucha (refreshListenable) para
/// redirigir automaticamente entre el login y las pantallas protegidas.
class AuthController extends ChangeNotifier {
  AuthController._() {
    // Si la API responde 401 en cualquier peticion, se cierra la sesion.
    ApiClient.onUnauthorized = _alRecibirNoAutorizado;
  }

  static final AuthController instance = AuthController._();

  final SessionStorage _storage = SessionStorage();
  final AuthService _service = AuthService();

  AuthStatus _status = AuthStatus.unknown;
  Usuario? _usuario;
  String? _tokenPreview;
  String? _aviso;

  AuthStatus get status => _status;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  Usuario? get usuario => _usuario;
  bool get tieneToken => _tokenPreview != null;

  /// Vista parcial del token (nunca el contenido completo).
  String get tokenPreview => _tokenPreview ?? '';

  /// Mensaje pendiente para mostrar en el login (ej. "La sesión ha expirado").
  String? takeAviso() {
    final aviso = _aviso;
    _aviso = null;
    return aviso;
  }

  /// Al abrir la app: restaura la sesion guardada y la valida contra el servidor.
  Future<void> init() async {
    final token = await _storage.readToken();
    if (token == null || token.isEmpty) {
      await _cerrarLocalmente();
      return;
    }

    _tokenPreview = _enmascarar(token);
    _usuario = await _storage.readUsuario();

    try {
      final vigente = await _service.me(); // el backend valida el token
      _usuario = vigente;
      await _storage.saveUsuario(vigente);
      _status = AuthStatus.authenticated;
      notifyListeners();
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        // Token expirado o invalido: se descarta y se pide iniciar sesion.
        await _cerrarLocalmente(aviso: e.message);
      } else {
        // Sin conexion con el servidor: se conserva la sesion local.
        _status = AuthStatus.authenticated;
        notifyListeners();
      }
    }
  }

  /// Valida credenciales en el backend y guarda la sesion. Lanza ApiException si fallan.
  Future<void> login(String email, String password) async {
    final resultado = await _service.login(email, password);
    await _storage.saveSession(
      token: resultado.token,
      usuario: resultado.usuario,
    );
    _usuario = resultado.usuario;
    _tokenPreview = _enmascarar(resultado.token);
    _aviso = null;
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  /// Cierre de sesion: borra token y datos locales; el router vuelve al login.
  Future<void> logout() => _cerrarLocalmente();

  Future<void> _alRecibirNoAutorizado(String mensaje) async {
    if (_status == AuthStatus.unauthenticated) return;
    await _cerrarLocalmente(aviso: mensaje);
  }

  Future<void> _cerrarLocalmente({String? aviso}) async {
    await _storage.clear();
    _usuario = null;
    _tokenPreview = null;
    if (aviso != null) _aviso = aviso;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  String _enmascarar(String token) {
    return token.length <= 8 ? '••••••••' : '${token.substring(0, 8)}••••••••';
  }
}
