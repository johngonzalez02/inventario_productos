import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'routes/app_router.dart';
import 'services/auth_controller.dart';
import 'themes/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Carga API_BASE_URL desde el archivo .env antes de iniciar la app.
  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
  // Restaura y valida la sesion guardada; mientras tanto el router muestra /splash.
  AuthController.instance.init();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Control de Inventario',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
