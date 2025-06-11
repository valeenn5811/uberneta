import 'theme_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'sidebar.dart';
import 'dashboard.dart';
import 'documentacion_page.dart';
import 'tablon.dart';
import 'upload_pdf_page.dart';
import 'factura_servicio_uberneta_page.dart';
import 'calendario.dart';
import 'settings_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';
import 'login.dart';

class HelpPage extends StatelessWidget {
  final String dni;
  final String id;
  final String nombre;
  final String correo;
  final String contrasena;
  final String licencia;
  final int idTipoUsuario;

  const HelpPage({
    super.key,
    required this.dni,
    required this.id,
    required this.nombre,
    required this.correo,
    required this.contrasena,
    required this.licencia,
    required this.idTipoUsuario,
  });

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = themeNotifier.isDarkMode;

    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            nombreUsuario: nombre,
            correoUsuario: correo,
            currentRoute: 'help',
            onNavigate: (route) {
              if (route == 'dashboard') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => MyHomePage(
                          title: 'Panel de control',
                          dni: dni,
                          nombre: nombre,
                          correo: correo,
                          id: id,
                          licencia: licencia,
                          contrasena: contrasena,
                          token: '',
                          idTipoUsuario: idTipoUsuario,
                        ),
                  ),
                );
              } else if (route == 'documentacion') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => DocumentacionPage(
                          documentosPorAnio: {},
                          descriptionsAndDatesPorAnio: {},
                          seleccionadosPorAnio: {},
                          idUsuario: id,
                          onDocumentosContabilizadosChanged: () {},
                          dni: dni,
                          licencia: licencia,
                          contrasena: contrasena,
                          nombre: nombre,
                          correo: correo,
                          idTipoUsuario: idTipoUsuario,
                        ),
                  ),
                );
              } else if (route == 'tablon') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => TablonPage(
                          dni: dni,
                          id: id,
                          licencia: licencia,
                          contrasena: contrasena,
                          nombre: nombre,
                          correo: correo,
                          idTipoUsuario: idTipoUsuario,
                        ),
                  ),
                );
              } else if (route == 'subir_facturas') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => UploadPdfPage(
                          idUsuario: id,
                          dni: dni,
                          nombre: nombre,
                          correo: correo,
                          licencia: licencia,
                          contrasena: contrasena,
                          idTipoUsuario: idTipoUsuario,
                        ),
                  ),
                );
              } else if (route == 'generar_factura') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => FacturaServicioUbernetaPage(
                          id: id,
                          dni: dni,
                          nombre: nombre,
                          correo: correo,
                          contrasena: contrasena,
                          licencia: licencia,
                          idTipoUsuario: idTipoUsuario,
                          tipoFactura: 'Servicio Taxi',
                          token: '',
                        ),
                  ),
                );
              } else if (route == 'calendario') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => CalendarioPage(
                          userId: id,
                          nombreUsuario: nombre,
                          correoUsuario: correo,
                          dni: dni,
                          licencia: licencia,
                          contrasena: contrasena,
                          idTipoUsuario: idTipoUsuario,
                        ),
                  ),
                );
              } else if (route == 'configuracion') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => SettingsPage(
                          id: id,
                          dni: dni,
                          nombre: nombre,
                          correo: correo,
                          contrasena: contrasena,
                          licencia: licencia,
                          idTipoUsuario: idTipoUsuario,
                        ),
                  ),
                );
              }
            },
            onLogout: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Cerrar Sesión'),
                    content: const Text(
                      '¿Está seguro de que desea cerrar sesión?',
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('No'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: const Text('Sí'),
                        onPressed: () async {
                          Navigator.of(context).pop();
                          try {
                            final response = await http.post(
                              Uri.parse('${Config.baseUrl}eliminar_token.php'),
                              headers: <String, String>{
                                'Content-Type':
                                    'application/json; charset=UTF-8',
                              },
                              body: jsonEncode(<String, String>{'dni': dni}),
                            );

                            final data = jsonDecode(response.body);
                            if (response.statusCode == 200 &&
                                data['status'] == 'success') {
                              print('Token eliminado correctamente');
                            }

                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                            );
                          } catch (e) {
                            print('Error en la solicitud: $e');
                          }
                        },
                      ),
                    ],
                  );
                },
              );
            },
            dni: dni,
            idUsuario: id,
            licencia: licencia,
            contrasena: contrasena,
            idTipoUsuario: idTipoUsuario,
          ),
          Expanded(
            child: Container(
              color: const Color(0xFFFFFFFF),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 32.0,
                      left: 24.0,
                      right: 24.0,
                      bottom: 8.0,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.help_outline,
                          color: Color(0xFFA42429),
                          size: 32,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Ayuda y Soporte',
                          style: TextStyle(
                            color: isDark ? Colors.white : Color(0xFF181C32),
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        _buildHelpItem(
                          '¿Cómo puedo cambiar mi contraseña?',
                          'Ve a la sección de configuración y selecciona "Cambiar Contraseña".',
                        ),
                        _buildHelpItem(
                          '¿Cómo contacto con soporte?',
                          'Puedes enviar un correo a valeenn811@gmail.com o llamar al 976 405 978.',
                        ),
                        _buildHelpItem(
                          '¿Cómo actualizo mi perfil?',
                          'Ve a la sección de perfil para editar tu información.',
                        ),
                        _buildHelpItem(
                          '¿Cómo gestiono las notificaciones?',
                          'Para gestionar las notificaciones, accede a la configuración de tu dispositivo y ajusta las preferencias para esta aplicación.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String question, String answer) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ExpansionTile(
        leading: const Icon(Icons.help_outline, color: Color(0xFFA42429)),
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(padding: const EdgeInsets.all(8.0), child: Text(answer)),
        ],
      ),
    );
  }
}
