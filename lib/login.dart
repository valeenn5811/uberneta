import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dashboard.dart';
import 'config.dart';
import 'dart:html' as html; // Solo para web

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _loadRememberMe();
  }

  void _loadRememberMe() {
    // Usar localStorage para web
    final dni = html.window.localStorage['dni'];
    final password = html.window.localStorage['password'];
    setState(() {
      _rememberMe = dni != null && password != null;
      if (_rememberMe) {
        _dniController.text = dni ?? '';
        _passwordController.text = password ?? '';
      }
    });
  }

  void _saveRememberMe() {
    if (_rememberMe) {
      html.window.localStorage['dni'] = _dniController.text;
      html.window.localStorage['password'] = _passwordController.text;
    } else {
      html.window.localStorage.remove('dni');
      html.window.localStorage.remove('password');
    }
  }

  void _updateRememberMe(bool? value) {
    setState(() {
      _rememberMe = value ?? false;
    });
    _saveRememberMe();
  }

  Future<void> _login() async {
    // Verificar si los campos están vacíos
    if (_dniController.text.isEmpty) {
      _showErrorDialog('Por favor, ingrese su DNI');
      return;
    }

    if (_passwordController.text.isEmpty) {
      _showErrorDialog('Por favor, ingrese su contraseña');
      return;
    }

    // Log: Inicio de proceso de login
    print('Iniciando proceso de login...');
    print('URL: ${Config.baseUrl}login.php');

    try {
      // Enviar DNI y contraseña al servidor con credenciales
      final response = await http.post(
        Uri.parse('${Config.baseUrl}login.php'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'dni': _dniController.text,
          'password': _passwordController.text,
        }),
      );

      print('Status Code: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          if (data['status'] == 'success') {
            print('Datos enviados al iniciar sesión:');
            print('DNI: ${data['dni']}');
            print('Nombre: ${data['nombre']}');
            print('Correo: ${data['correo']}');
            print('Token: ${data['token']}');
            print('ID: ${data['id']}');
            print('Contraseña: ${data['contrasena'] ?? ''}');
            print('ID Tipo Usuario: ${data['idTipoUsuario']}');
            // Actualizar el userDataNotifier con los datos del usuario
            userDataNotifier.value = {
              'nombre': data['nombre'].toString(),
              'correo': data['correo'].toString(),
            };

            // Guardar las preferencias si "Recuérdame" está activado
            if (_rememberMe) {
              html.window.localStorage['dni'] = _dniController.text;
              html.window.localStorage['password'] = _passwordController.text;
            }

            // Proceder con el inicio de sesión
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (context) => MyHomePage(
                      title: 'Dashboard',
                      dni: data['dni'].toString(),
                      nombre: data['nombre'].toString(),
                      correo: data['correo'].toString(),
                      id: data['id'].toString(),
                      licencia: data['licencia'].toString(),
                      token: data['token'].toString(),
                      contrasena: data['contrasena'] ?? '',
                      idTipoUsuario: data['idTipoUsuario'],
                    ),
              ),
            );
          } else {
            _showErrorDialog(data['message'] ?? 'Error desconocido');
          }
        } catch (jsonError) {
          print('Error al decodificar JSON: $jsonError');
          print('Respuesta del servidor: ${response.body}');
          _showErrorDialog(
            'Error en la respuesta del servidor. Por favor, contacte al administrador.',
          );
        }
      } else {
        _showErrorDialog(
          'Error del servidor (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      print('Error completo: $e');
      _showErrorDialog(
        'Error de conexión. Por favor, verifica que el servidor esté funcionando.',
      );
    }
  }

  void _forgotPassword() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController _emailController = TextEditingController();
        return AlertDialog(
          title: const Text('Recuperar Contraseña'),
          content: TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Ingrese su correo electrónico',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Enviar'),
              onPressed: () async {
                final email = _emailController.text;
                if (email.isNotEmpty && _isValidEmail(email)) {
                  await _sendPasswordRecoveryRequest(email);
                  Navigator.of(context).pop();
                } else {
                  _showErrorDialog(
                    'Por favor, ingrese un correo electrónico válido.',
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  bool _isValidEmail(String email) {
    final RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  Future<void> _sendPasswordRecoveryRequest(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}forgot_password.php'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{'email': email}),
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);

          if (data['status'] == 'success') {
            Navigator.of(context).pop(); // Cerrar el diálogo de recuperación
            await Future.delayed(
              Duration(milliseconds: 100),
            ); // Espera breve para asegurar el cierre
            if (mounted) {
              _showSuccessDialog(
                'Se ha enviado un correo de recuperación a $email.\nPor favor, revise su bandeja de entrada y siga las instrucciones para restablecer su contraseña.',
              );
            }
          } else if (data['status'] == 'error') {
            if (data['message'].toString().contains('SMTP Error')) {
              _showErrorDialog(
                'No se pudo enviar el correo de recuperación. Por favor, contacte al administrador del sistema.',
              );
            } else if (data['message'] == 'Correo no encontrado') {
              _showErrorDialog('El correo electrónico no está registrado.');
            } else {
              _showErrorDialog(
                data['message'] ?? 'Error al procesar la solicitud',
              );
            }
          }
        } catch (jsonError) {
          print('Error al decodificar JSON: $jsonError');
          print('Respuesta del servidor: ${response.body}');
          _showErrorDialog(
            'Error en la respuesta del servidor. Por favor, contacte al administrador.',
          );
        }
      } else {
        _showErrorDialog(
          'Error del servidor (${response.statusCode}). Por favor, intente más tarde.',
        );
      }
    } catch (e) {
      print('Error de conexión: $e');
      _showErrorDialog(
        'Error de conexión. Por favor, verifica tu conexión a internet e inténtalo de nuevo.',
      );
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Información'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('Aceptar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Éxito'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('Aceptar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo degradado
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF232526), Color(0xFFA42429)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Formulario centrado y compacto
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380, maxHeight: 520),
              child: Card(
                elevation: 16,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 20,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        // Logo más pequeño
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.10),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 38,
                            backgroundImage: AssetImage(
                              'img/logo-uberneta-limpia.png',
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Bienvenido a Uberneta Intranet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFA42429),
                            letterSpacing: 1.1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Accede a tu cuenta',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),
                        // DNI
                        TextField(
                          controller: _dniController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.badge,
                              color: Color(0xFFA42429),
                            ),
                            labelText: 'DNI',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Contraseña
                        TextField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.lock,
                              color: Color(0xFFA42429),
                            ),
                            labelText: 'Contraseña',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey[600],
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureText = !_obscureText;
                                });
                              },
                            ),
                          ),
                          obscureText: _obscureText,
                        ),
                        const SizedBox(height: 6),
                        // Recuérdame y Olvidé contraseña
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: _updateRememberMe,
                              activeColor: const Color(0xFFA42429),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            const Text(
                              'Recuérdame',
                              style: TextStyle(fontSize: 13),
                            ),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _forgotPassword,
                                  child: const Text(
                                    'He olvidado mi contraseña',
                                    style: TextStyle(
                                      color: Color(0xFFA42429),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Botón de login
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFA42429),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'Iniciar Sesión',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
