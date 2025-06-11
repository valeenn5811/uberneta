import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart'; // Asegúrate de que la ruta sea correcta
import '../sidebar.dart';
import '../dashboard.dart';
import '../documentacion_page.dart';
import '../tablon.dart';
import '../upload_pdf_page.dart';
import '../factura_servicio_uberneta_page.dart';
import '../calendario.dart';
import '../settings_page.dart';
import '../login.dart';

class ChangePasswordPage extends StatefulWidget {
  final String contrasena;
  final String idUsuario;
  final String nombre;
  final String correo;
  final String dni;
  final String licencia;
  final int idTipoUsuario;

  const ChangePasswordPage({
    Key? key,
    required this.contrasena,
    required this.idUsuario,
    required this.nombre,
    required this.correo,
    required this.dni,
    required this.licencia,
    required this.idTipoUsuario,
  }) : super(key: key);

  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isCurrentPasswordValid = false;
  bool _areNewPasswordsMatching = true;

  Future<void> _verifyCurrentPassword() async {
    // Simulación de verificación de contraseña actual
    if (_currentPasswordController.text == widget.contrasena) {
      setState(() {
        _isCurrentPasswordValid = true;
      });
    } else {
      // Mostrar un diálogo de error
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('Contraseña actual incorrecta'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _updatePassword() async {
    if (_isCurrentPasswordValid && _areNewPasswordsMatching) {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}update_password.php'),
        body: jsonEncode({
          'newPassword': _newPasswordController.text,
          'idUsuario': widget.idUsuario,
        }),
      );

      if (response.statusCode == 200) {
        // Mostrar un diálogo de éxito
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Éxito'),
              content: Text('Contraseña actualizada con éxito'),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      } else {
        // Mostrar un diálogo de error
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('Error al actualizar la contraseña'),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            nombreUsuario: widget.nombre,
            correoUsuario: widget.correo,
            currentRoute: 'configuracion',
            onNavigate: (route) {
              if (route == 'dashboard') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => MyHomePage(
                          title: 'Panel de control',
                          dni: widget.dni,
                          nombre: widget.nombre,
                          correo: widget.correo,
                          id: widget.idUsuario,
                          licencia: widget.licencia,
                          contrasena: widget.contrasena,
                          token: '',
                          idTipoUsuario: widget.idTipoUsuario,
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
                          idUsuario: widget.idUsuario,
                          onDocumentosContabilizadosChanged: () {},
                          dni: widget.dni,
                          licencia: widget.licencia,
                          contrasena: widget.contrasena,
                          nombre: widget.nombre,
                          correo: widget.correo,
                          idTipoUsuario: widget.idTipoUsuario,
                        ),
                  ),
                );
              } else if (route == 'tablon') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => TablonPage(
                          dni: widget.dni,
                          id: widget.idUsuario,
                          licencia: widget.licencia,
                          contrasena: widget.contrasena,
                          nombre: widget.nombre,
                          correo: widget.correo,
                          idTipoUsuario: widget.idTipoUsuario,
                        ),
                  ),
                );
              } else if (route == 'subir_facturas') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => UploadPdfPage(
                          idUsuario: widget.idUsuario,
                          dni: widget.dni,
                          nombre: widget.nombre,
                          correo: widget.correo,
                          licencia: widget.licencia,
                          contrasena: widget.contrasena,
                          idTipoUsuario: widget.idTipoUsuario,
                        ),
                  ),
                );
              } else if (route == 'generar_factura') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => FacturaServicioUbernetaPage(
                          id: widget.idUsuario,
                          dni: widget.dni,
                          nombre: widget.nombre,
                          correo: widget.correo,
                          contrasena: widget.contrasena,
                          licencia: widget.licencia,
                          idTipoUsuario: widget.idTipoUsuario,
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
                          userId: widget.idUsuario,
                          nombreUsuario: widget.nombre,
                          correoUsuario: widget.correo,
                          dni: widget.dni,
                          licencia: widget.licencia,
                          contrasena: widget.contrasena,
                          idTipoUsuario: widget.idTipoUsuario,
                        ),
                  ),
                );
              } else if (route == 'configuracion') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => SettingsPage(
                          id: widget.idUsuario,
                          nombre: widget.nombre,
                          correo: widget.correo,
                          dni: widget.dni,
                          licencia: widget.licencia,
                          contrasena: widget.contrasena,
                          idTipoUsuario: widget.idTipoUsuario,
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
                              body: jsonEncode(<String, String>{
                                'dni': widget.dni,
                              }),
                            );

                            final data = jsonDecode(response.body);
                            if (response.statusCode == 200 &&
                                data['status'] == 'success') {
                              print('Token eliminado correctamente');
                            }

                            if (mounted) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginPage(),
                                ),
                              );
                            }
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
            dni: widget.dni,
            idUsuario: widget.idUsuario,
            licencia: widget.licencia,
            contrasena: widget.contrasena,
            idTipoUsuario: widget.idTipoUsuario,
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Cambiar Contraseña',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF181C32),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Introduce tu nueva contraseña',
                      style: TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _currentPasswordController,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña Actual',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),
                    if (_isCurrentPasswordValid)
                      Column(
                        children: [
                          TextField(
                            controller: _newPasswordController,
                            decoration: const InputDecoration(
                              labelText: 'Nueva Contraseña',
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _confirmPasswordController,
                            decoration: InputDecoration(
                              labelText: 'Confirmar Nueva Contraseña',
                              border: const OutlineInputBorder(),
                              errorText:
                                  _areNewPasswordsMatching
                                      ? null
                                      : 'Las contraseñas no coinciden',
                            ),
                            obscureText: true,
                            onChanged: (value) {
                              setState(() {
                                _areNewPasswordsMatching =
                                    _newPasswordController.text == value;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ElevatedButton(
                      onPressed:
                          _isCurrentPasswordValid
                              ? _updatePassword
                              : _verifyCurrentPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA42429),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text(
                        'Actualizar Contraseña',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Color(0xFFA42429),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
