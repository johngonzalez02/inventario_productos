import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Variables de entorno. En el emulador Android, 10.0.2.2 apunta al
/// localhost del computador donde corre la API.
class Env {
  Env._();

  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000/api';
}
