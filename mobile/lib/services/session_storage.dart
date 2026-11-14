import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/usuario.dart';

/// Almacenamiento local de la sesion.
///
///  - flutter_secure_storage (cifrado): SOLO el access_token.
///  - shared_preferences: datos NO sensibles (id, nombre y correo del usuario).
///
/// La contrasena nunca se guarda.
class SessionStorage {
  SessionStorage();

  static const String _tokenKey = 'access_token';
  static const String _idKey = 'usuario_id';
  static const String _nombreKey = 'usuario_nombre';
  static const String _emailKey = 'usuario_email';

  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  /// Guarda el token (cifrado) y los datos del usuario (preferencias).
  Future<void> saveSession({
    required String token,
    required Usuario usuario,
  }) async {
    await _secure.write(key: _tokenKey, value: token);
    await saveUsuario(usuario);
  }

  Future<void> saveUsuario(Usuario usuario) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_idKey, usuario.id);
    await prefs.setString(_nombreKey, usuario.nombre);
    await prefs.setString(_emailKey, usuario.email);
  }

  Future<String?> readToken() async {
    try {
      return await _secure.read(key: _tokenKey);
    } catch (_) {
      // El almacen cifrado quedo ilegible (por ejemplo tras reinstalar la app):
      // se descarta para no bloquear el arranque y se pedira iniciar sesion.
      await _borrarAlmacenSeguro();
      return null;
    }
  }

  Future<Usuario?> readUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final nombre = prefs.getString(_nombreKey);
    final email = prefs.getString(_emailKey);
    if (nombre == null || email == null) return null;
    return Usuario(id: prefs.getInt(_idKey) ?? 0, nombre: nombre, email: email);
  }

  /// Elimina el token y los datos del usuario (cierre de sesion).
  Future<void> clear() async {
    await _borrarAlmacenSeguro();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_idKey);
    await prefs.remove(_nombreKey);
    await prefs.remove(_emailKey);
  }

  Future<void> _borrarAlmacenSeguro() async {
    try {
      await _secure.delete(key: _tokenKey);
    } catch (_) {
      // Si tampoco se puede borrar, no hay nada mas que limpiar.
    }
  }
}
