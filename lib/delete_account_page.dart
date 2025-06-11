import 'dart:convert';
import 'theme_notifier.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'config.dart';
import 'sidebar.dart';
import 'dashboard.dart';
import 'tablon.dart';
import 'upload_pdf_page.dart';
import 'factura_servicio_uberneta_page.dart';
import 'calendario.dart';
import 'settings_page.dart';
import 'login.dart';

class DeleteAccountPage extends StatelessWidget {
  final String idUsuario;
  final String dni;
  final String licencia;
  final String contrasena;
  final String nombre;
  final String correo;
  final int idTipoUsuario;

  const DeleteAccountPage({
    super.key,
    required this.idUsuario,
    required this.dni,
    required this.licencia,
    required this.contrasena,
    required this.nombre,
    required this.correo,
    required this.idTipoUsuario,
  });

  void _confirmDelete(BuildContext context, String input) async {
    // Verificar que el campo de la contraseña no esté vacío
    if (input.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('Por favor, introduce tu contraseña.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    // Verificar que el método se está llamando
    print('Método _confirmDelete llamado');

    // Imprimir los datos que se enviarán al servidor
    print('Enviando datos: password=$input, user_id=$idUsuario');

    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}eliminar_cuenta.php'),
        body: {'password': input, 'user_id': idUsuario},
      );

      // Verificar que se recibió una respuesta
      print('Código de estado: ${response.statusCode}');
      print('Cuerpo de la respuesta: ${response.body}');

      if (response.body.isNotEmpty) {
        final responseData = json.decode(response.body);

        if (responseData['success']) {
          // Contraseña verificada, proceder con la eliminación
          Navigator.pop(context);

          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Confirmación'),
                content: const Text(
                  'Enviado éxitosamente el formulario de eliminación. '
                  'La eliminación de la cuenta puede tardar hasta 48 horas.',
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        } else {
          // Mostrar error si la contraseña es incorrecta
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Error'),
                content: Text(responseData['error']),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        }
      } else {
        // Manejar el caso donde la respuesta está vacía
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: const Text('Error en la comunicación con el servidor.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      // Manejar errores de red o del servidor
      print('Error al realizar la solicitud: $e');
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('No se pudo conectar con el servidor.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextEditingController _controller = TextEditingController();
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = themeNotifier.isDarkMode;

    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            nombreUsuario: nombre,
            correoUsuario: correo,
            currentRoute: 'configuracion',
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
                          id: idUsuario,
                          licencia: licencia,
                          contrasena: contrasena,
                          token: '',
                          idTipoUsuario: idTipoUsuario,
                        ),
                  ),
                );
              } else if (route == 'documentacion') {
                // Navegación a documentación
              } else if (route == 'tablon') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => TablonPage(
                          dni: dni,
                          id: idUsuario,
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
                          idUsuario: idUsuario,
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
                          id: idUsuario,
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
                          userId: idUsuario,
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
                          id: idUsuario,
                          nombre: nombre,
                          correo: correo,
                          dni: dni,
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
            idUsuario: idUsuario,
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
                          Icons.delete_forever,
                          color: Color(0xFFA42429),
                          size: 32,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Eliminar Cuenta',
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          '¿Estás seguro de que deseas eliminar tu cuenta?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: TextField(
                            controller: _controller,
                            decoration: const InputDecoration(
                              labelText: 'Introduce la contraseña actual',
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: ElevatedButton(
                            onPressed:
                                () => _confirmDelete(context, _controller.text),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFA42429),
                            ),
                            child: const Text(
                              'Confirmar Eliminación',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(
                                color: Color(0xFFA42429),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
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
}
