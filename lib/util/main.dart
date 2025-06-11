import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_notifier.dart';
import '../login.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../help_page.dart';
import '../dashboard.dart';
import '../upload_pdf_page.dart';
import '../calendario.dart';
import '../documentacion_page.dart';
import '../tablon.dart';
import '../factura_servicio_uberneta_page.dart';
import '../settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final themeNotifier = ThemeNotifier();
  await themeNotifier.loadThemePreference();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => themeNotifier)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          title: 'Uberneta',
          theme: ThemeData.light(),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: Colors.grey[900],
            scaffoldBackgroundColor: Colors.grey[850],
          ),
          themeMode:
              themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const LoginPage(),
          debugShowCheckedModeBanner: false,
          routes: {
            '/help': (context) {
              final args =
                  ModalRoute.of(context)!.settings.arguments
                      as Map<String, dynamic>?;
              if (args == null) {
                return const LoginPage();
              }
              return HelpPage(
                dni: args['dni'] ?? '',
                id: args['id'] ?? '',
                nombre: args['nombre'] ?? '',
                correo: args['correo'] ?? '',
                contrasena: args['contrasena'] ?? '',
                licencia: args['licencia'] ?? '',
                idTipoUsuario: args['idTipoUsuario'] ?? 0,
              );
            },
            '/dashboard': (context) {
              final args =
                  ModalRoute.of(context)!.settings.arguments
                      as Map<String, dynamic>?;
              if (args == null) {
                return const LoginPage();
              }
              return MyHomePage(
                title: 'Archivos',
                dni: args['dni'] ?? '',
                nombre: args['nombre'] ?? '',
                correo: args['correo'] ?? '',
                id: args['id'] ?? '',
                licencia: args['licencia'] ?? '',
                token: args['token'] ?? '',
                contrasena: args['contrasena'] ?? '',
                idTipoUsuario: args['idTipoUsuario'] ?? 0,
              );
            },
            '/documentacion': (context) {
              final args =
                  ModalRoute.of(context)!.settings.arguments
                      as Map<String, dynamic>?;
              if (args == null) {
                return const LoginPage();
              }
              return DocumentacionPage(
                documentosPorAnio: args['documentosPorAnio'],
                descriptionsAndDatesPorAnio:
                    args['descriptionsAndDatesPorAnio'],
                seleccionadosPorAnio: args['seleccionadosPorAnio'],
                idUsuario: args['idUsuario'],
                onDocumentosContabilizadosChanged:
                    args['onDocumentosContabilizadosChanged'],
                dni: args['dni'] ?? '',
                licencia: args['licencia'] ?? '',
                contrasena: args['contrasena'] ?? '',
                nombre: args['nombre'] ?? '',
                correo: args['correo'] ?? '',
                idTipoUsuario: args['idTipoUsuario'] ?? 0,
              );
            },
            '/tablon': (context) {
              final args =
                  ModalRoute.of(context)!.settings.arguments
                      as Map<String, dynamic>?;
              if (args == null) {
                return const LoginPage();
              }
              return TablonPage(
                dni: args['dni'] ?? '',
                id: args['id'] ?? '',
                licencia: args['licencia'] ?? '',
                contrasena: args['contrasena'] ?? '',
                nombre: args['nombre'] ?? '',
                correo: args['correo'] ?? '',
                idTipoUsuario: args['idTipoUsuario'] ?? 0,
              );
            },
            '/subir_facturas': (context) {
              final args =
                  ModalRoute.of(context)!.settings.arguments
                      as Map<String, dynamic>?;
              if (args == null) {
                return const LoginPage();
              }
              return UploadPdfPage(
                idUsuario: args['idUsuario'] ?? '',
                dni: args['dni'] ?? '',
                nombre: args['nombre'] ?? '',
                correo: args['correo'] ?? '',
                licencia: args['licencia'] ?? '',
                contrasena: args['contrasena'] ?? '',
                idTipoUsuario: args['idTipoUsuario'] ?? 0,
              );
            },
            '/generar_factura': (context) {
              final args =
                  ModalRoute.of(context)!.settings.arguments
                      as Map<String, dynamic>?;
              if (args == null) {
                return const LoginPage();
              }
              return FacturaServicioUbernetaPage(
                id: args['id'] ?? '',
                dni: args['dni'] ?? '',
                nombre: args['nombre'] ?? '',
                correo: args['correo'] ?? '',
                contrasena: args['contrasena'] ?? '',
                licencia: args['licencia'] ?? '',
                tipoFactura: args['tipoFactura'] ?? 'Servicio Taxi',
                idTipoUsuario: args['idTipoUsuario'] ?? 0,
                token: args['token'] ?? '',
              );
            },
            '/calendario': (context) {
              final args =
                  ModalRoute.of(context)!.settings.arguments
                      as Map<String, dynamic>?;
              if (args == null) {
                return const LoginPage();
              }
              return CalendarioPage(
                userId: args['idUsuario'] ?? '',
                nombreUsuario: args['nombre'] ?? '',
                correoUsuario: args['correo'] ?? '',
                dni: args['dni'] ?? '',
                licencia: args['licencia'] ?? '',
                contrasena: args['contrasena'] ?? '',
                idTipoUsuario: args['idTipoUsuario'] ?? 0,
              );
            },
            '/configuracion': (context) {
              final args =
                  ModalRoute.of(context)!.settings.arguments
                      as Map<String, dynamic>?;
              if (args == null) {
                return const LoginPage();
              }
              return SettingsPage(
                id: args['idUsuario'] ?? '',
                nombre: args['nombre'] ?? '',
                correo: args['correo'] ?? '',
                dni: args['dni'] ?? '',
                contrasena: args['contrasena'] ?? '',
                licencia: args['licencia'] ?? '',
                idTipoUsuario: args['idTipoUsuario'] ?? 0,
              );
            },
          },
          locale: const Locale(
            'es',
            'ES',
          ), // Establece la configuración regional a español
          supportedLocales: const [
            Locale('en', 'US'),
            Locale('es', 'ES'),
            // Agrega otros locales si es necesario
          ],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
        );
      },
    );
  }
}

void navigateToDashboard(
  BuildContext context,
  String dni,
  String nombre,
  String correo,
  String id,
  String contrasena,
  String licencia,
  String token,
  int idTipoUsuario,
) {
  Navigator.pushReplacementNamed(
    context,
    '/dashboard',
    arguments: {
      'dni': dni,
      'nombre': nombre,
      'correo': correo,
      'id': id,
      'licencia': licencia,
      'contrasena': contrasena,
      'token': token.isEmpty ? 'null' : token,
      'idTipoUsuario': idTipoUsuario,
    },
  );
}
