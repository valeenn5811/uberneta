import 'dart:convert';
import 'dashboard.dart';
import 'theme_notifier.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'config.dart';
import 'sidebar.dart';
import 'documentacion_page.dart';
import 'tablon.dart';
import 'upload_pdf_page.dart';
import 'factura_servicio_uberneta_page.dart';
import 'calendario.dart';
import 'settings_page.dart';
import 'login.dart';

class ProfilePage extends StatefulWidget {
  final String dni;
  final String id;
  final String nombre;
  final String correo;
  final String contrasena;
  final String licencia;
  final int idTipoUsuario;

  const ProfilePage({
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
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Controladores de texto para los campos del perfil
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();

  // Variables para almacenar los valores originales
  String _originalName = '';
  String _originalEmail = '';
  String _originalPhone = '';
  String _originalAddress = '';
  String _originalProvince = '';
  String _originalPostalCode = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfile(); // Cargar datos reales del perfil
  }

  @override
  void dispose() {
    // Asegúrate de cancelar cualquier suscripción o listener aquí
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _provinceController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final response = await http.post(
      Uri.parse('${Config.baseUrl}get_user_data.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{'dni': widget.dni}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        if (mounted) {
          setState(() {
            _nameController.text = data['data']['Nombre'] ?? '';
            _emailController.text = data['data']['CorreoUsuario'] ?? '';
            _phoneController.text =
                (data['data']['TelefonoUsuario'] ?? '').toString();
            _addressController.text = data['data']['Direccion'] ?? '';
            _provinceController.text = data['data']['Provincia'] ?? '';
            _postalCodeController.text = data['data']['CodigoPostal'] ?? '';

            // Almacenar los valores originales
            _originalName = data['data']['Nombre'] ?? '';
            _originalEmail = data['data']['CorreoUsuario'] ?? '';
            _originalPhone = (data['data']['TelefonoUsuario'] ?? '').toString();
            _originalAddress = data['data']['Direccion'] ?? '';
            _originalProvince = data['data']['Provincia'] ?? '';
            _originalPostalCode = data['data']['CodigoPostal'] ?? '';
          });
        }
      } else {
        _showErrorSnackbar(data['message']);
      }
    } else {
      _showErrorSnackbar('Error al cargar los datos del perfil');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = themeNotifier.isDarkMode;

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
                        Icon(Icons.person, color: Color(0xFFA42429), size: 32),
                        SizedBox(width: 12),
                        Text(
                          'Datos Personales',
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
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildTextField(_nameController, 'Nombre Completo'),
                            const SizedBox(height: 10),
                            _buildTextField(
                              _emailController,
                              'Correo Electrónico',
                            ),
                            const SizedBox(height: 10),
                            _buildTextField(_phoneController, 'Teléfono'),
                            const SizedBox(height: 10),
                            _buildTextField(_addressController, 'Dirección'),
                            const SizedBox(height: 10),
                            _buildTextField(_provinceController, 'Provincia'),
                            const SizedBox(height: 10),
                            _buildTextField(
                              _postalCodeController,
                              'Código Postal',
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _showConfirmationDialog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFA42429),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 50,
                                  vertical: 15,
                                ),
                              ),
                              child: const Text(
                                'Guardar Cambios',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  void _saveProfile() async {
    final response = await http.post(
      Uri.parse('${Config.baseUrl}update_user_data.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'dni': widget.dni,
        'Nombre': _nameController.text,
        'CorreoUsuario': _emailController.text,
        'TelefonoUsuario': _phoneController.text,
        'Direccion': _addressController.text,
        'Provincia': _provinceController.text,
        'CodigoPostal': _postalCodeController.text,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        if (mounted) {
          // Actualizar el estado global del usuario
          userDataNotifier.value = {
            'nombre': _nameController.text,
            'correo': _emailController.text,
          };

          // Mostrar mensaje de éxito
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Perfil actualizado correctamente'),
              backgroundColor: Colors.green,
            ),
          );

          // Actualizar el sidebar navegando a la misma página con los nuevos datos
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ProfilePage(
                    dni: widget.dni,
                    id: widget.id,
                    nombre: _nameController.text,
                    correo: _emailController.text,
                    contrasena: widget.contrasena,
                    licencia: widget.licencia,
                    idTipoUsuario: widget.idTipoUsuario,
                  ),
            ),
          );
        }
      } else {
        _showErrorSnackbar(data['message']);
      }
    } else {
      _showErrorSnackbar('Error al actualizar el perfil');
    }
  }

  void _showConfirmationDialog() {
    if (!_isNumeric(_postalCodeController.text)) {
      _showCustomDialog('Error', 'El código postal debe contener solo números');
      return;
    }

    if (!_isNumeric(_phoneController.text)) {
      _showCustomDialog('Error', 'El teléfono debe contener solo números');
      return;
    }

    bool hasChanges =
        _nameController.text != _originalName ||
        _emailController.text != _originalEmail ||
        _phoneController.text != _originalPhone ||
        _addressController.text != _originalAddress ||
        _provinceController.text != _originalProvince ||
        _postalCodeController.text != _originalPostalCode;

    if (!hasChanges) {
      _showCustomDialog('Sin Cambios', 'No hay cambios para guardar');
      return;
    }

    final changes = <Map<String, String>>[];

    if (_nameController.text != _originalName) {
      changes.add({
        'label': 'Nombre',
        'current': _originalName,
        'new': _nameController.text,
      });
    }
    if (_emailController.text != _originalEmail) {
      changes.add({
        'label': 'Correo Electrónico',
        'current': _originalEmail,
        'new': _emailController.text,
      });
    }
    if (_phoneController.text != _originalPhone) {
      changes.add({
        'label': 'Teléfono',
        'current': _originalPhone,
        'new': _phoneController.text,
      });
    }
    if (_addressController.text != _originalAddress) {
      changes.add({
        'label': 'Dirección',
        'current': _originalAddress,
        'new': _addressController.text,
      });
    }
    if (_provinceController.text != _originalProvince) {
      changes.add({
        'label': 'Provincia',
        'current': _originalProvince,
        'new': _provinceController.text,
      });
    }
    if (_postalCodeController.text != _originalPostalCode) {
      changes.add({
        'label': 'Código Postal',
        'current': _originalPostalCode,
        'new': _postalCodeController.text,
      });
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Cambios'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  changes.map((change) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            change['label']!,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Actual: ${change['current']}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          Text(
                            'Nuevo: ${change['new']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Divider(),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Confirmar'),
              onPressed: () {
                Navigator.of(context).pop();
                _saveProfile(); // Llamar a la función para guardar los cambios
              },
            ),
          ],
        );
      },
    );
  }

  void _showCustomDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            ElevatedButton(
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

  bool _isNumeric(String str) {
    return RegExp(r'^[0-9]+$').hasMatch(str);
  }
}
