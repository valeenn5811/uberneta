import 'profile_page.dart';
import 'package:flutter/material.dart';
import 'configuracion/change_password_page.dart';
import 'delete_account_page.dart';
import 'sidebar.dart';
import 'dashboard.dart';
import 'documentacion_page.dart';
import 'tablon.dart';
import 'upload_pdf_page.dart';
import 'factura_servicio_uberneta_page.dart';
import 'calendario.dart';
import 'help_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';
import 'login.dart';

class SettingsPage extends StatefulWidget {
  final String id;
  final String dni;
  final String nombre;
  final String correo;
  final String contrasena;
  final String licencia;
  final int idTipoUsuario;

  const SettingsPage({
    Key? key,
    required this.id,
    required this.dni,
    required this.nombre,
    required this.correo,
    required this.contrasena,
    required this.licencia,
    required this.idTipoUsuario,
  }) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ProfilePage(
              dni: widget.dni,
              id: widget.id,
              nombre: widget.nombre,
              correo: widget.correo,
              contrasena: widget.contrasena,
              licencia: widget.licencia,
              idTipoUsuario: widget.idTipoUsuario,
            ),
      ),
    );
  }

  void _navigateToChangePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ChangePasswordPage(
              contrasena: widget.contrasena,
              idUsuario: widget.id,
              nombre: widget.nombre,
              correo: widget.correo,
              dni: widget.dni,
              licencia: widget.licencia,
              idTipoUsuario: widget.idTipoUsuario,
            ),
      ),
    );
  }

  void _navigateToDeleteAccount() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => DeleteAccountPage(
              idUsuario: widget.id,
              dni: widget.dni,
              licencia: widget.licencia,
              contrasena: widget.contrasena,
              nombre: widget.nombre,
              correo: widget.correo,
              idTipoUsuario: widget.idTipoUsuario,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          Sidebar(
            nombreUsuario: widget.nombre,
            correoUsuario: widget.correo,
            currentRoute: 'settings',
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
                          id: widget.id,
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
                          idUsuario: widget.id,
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
                          id: widget.id,
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
                          idUsuario: widget.id,
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
                          id: widget.id,
                          dni: widget.dni,
                          nombre: widget.nombre,
                          correo: widget.correo,
                          contrasena: widget.contrasena,
                          licencia: widget.licencia,
                          tipoFactura: 'Servicio Taxi',
                          idTipoUsuario: widget.idTipoUsuario,
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
                          userId: widget.id,
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
                          id: widget.id,
                          dni: widget.dni,
                          nombre: widget.nombre,
                          correo: widget.correo,
                          contrasena: widget.contrasena,
                          licencia: widget.licencia,
                          idTipoUsuario: widget.idTipoUsuario,
                        ),
                  ),
                );
              } else if (route == 'delete_account') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => DeleteAccountPage(
                          idUsuario: widget.id,
                          dni: widget.dni,
                          licencia: widget.licencia,
                          contrasena: widget.contrasena,
                          nombre: widget.nombre,
                          correo: widget.correo,
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
            idUsuario: widget.id,
            licencia: widget.licencia,
            contrasena: widget.contrasena,
            idTipoUsuario: widget.idTipoUsuario,
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      top: 32.0,
                      left:
                          MediaQuery.of(context).size.width < 600 ? 16.0 : 24.0,
                      right:
                          MediaQuery.of(context).size.width < 600 ? 16.0 : 24.0,
                      bottom: 8.0,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.settings,
                          color: Color(0xFFA42429),
                          size:
                              MediaQuery.of(context).size.width < 600 ? 24 : 32,
                        ),
                        SizedBox(
                          width:
                              MediaQuery.of(context).size.width < 600 ? 8 : 12,
                        ),
                        Expanded(
                          child: Text(
                            'Configuración',
                            style: TextStyle(
                              color: Color(0xFF181C32),
                              fontWeight: FontWeight.bold,
                              fontSize:
                                  MediaQuery.of(context).size.width < 600
                                      ? 20
                                      : 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(
                        MediaQuery.of(context).size.width < 600 ? 16.0 : 24.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          _buildSectionTitle('Cuenta'),
                          _buildListTile(
                            context,
                            icon: Icons.person,
                            title: 'Perfil',
                            subtitle: 'Ver y editar tu perfil',
                            onTap: _navigateToProfile,
                          ),
                          _buildListTile(
                            context,
                            icon: Icons.lock,
                            title: 'Cambiar Contraseña',
                            subtitle: 'Actualiza tu contraseña',
                            onTap: _navigateToChangePassword,
                          ),
                          _buildListTile(
                            context,
                            icon: Icons.delete,
                            title: 'Eliminar Cuenta',
                            subtitle: 'Eliminar tu cuenta',
                            onTap: _navigateToDeleteAccount,
                          ),
                          const Divider(),
                          _buildSectionTitle('Soporte'),
                          _buildListTile(
                            context,
                            icon: Icons.help,
                            title: 'Ayuda',
                            subtitle: 'Obtener ayuda y soporte',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => HelpPage(
                                        dni: widget.dni,
                                        id: widget.id,
                                        nombre: widget.nombre,
                                        correo: widget.correo,
                                        contrasena: widget.contrasena,
                                        licencia: widget.licencia,
                                        idTipoUsuario: widget.idTipoUsuario,
                                      ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFFA42429),
        ),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Color(0xFFA42429)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
      onTap: onTap,
    );
  }
}
