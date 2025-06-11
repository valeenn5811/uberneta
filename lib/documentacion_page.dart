import 'theme_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'sidebar.dart';
import 'documentos_anio_page.dart';
import 'dashboard.dart';
import 'tablon.dart';
import 'upload_pdf_page.dart';
import 'factura_servicio_uberneta_page.dart';
import 'calendario.dart';
import 'settings_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';
import 'services/documentos_service.dart';
import 'login.dart';

class DocumentacionPage extends StatefulWidget {
  final Map<int, Map<String, List<String>>> documentosPorAnio;
  final Map<int, Map<String, List<String>>> descriptionsAndDatesPorAnio;
  final Map<int, Map<String, List<bool>>> seleccionadosPorAnio;
  final String idUsuario;
  final Function onDocumentosContabilizadosChanged;
  final String dni;
  final String licencia;
  final String contrasena;
  final String nombre;
  final String correo;
  final int idTipoUsuario;

  const DocumentacionPage({
    Key? key,
    required this.documentosPorAnio,
    required this.descriptionsAndDatesPorAnio,
    required this.seleccionadosPorAnio,
    required this.idUsuario,
    required this.onDocumentosContabilizadosChanged,
    required this.dni,
    required this.licencia,
    required this.contrasena,
    required this.nombre,
    required this.correo,
    required this.idTipoUsuario,
  }) : super(key: key);

  @override
  _DocumentacionPageState createState() => _DocumentacionPageState();
}

class _DocumentacionPageState extends State<DocumentacionPage> {
  late Map<int, Map<String, List<String>>> _documentosPorAnio;
  late Map<int, Map<String, List<String>>> _descriptionsAndDatesPorAnio;
  late Map<int, Map<String, List<bool>>> _seleccionadosPorAnio;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _documentosPorAnio = widget.documentosPorAnio;
    _descriptionsAndDatesPorAnio = widget.descriptionsAndDatesPorAnio;
    _seleccionadosPorAnio = widget.seleccionadosPorAnio;

    if (_documentosPorAnio.isEmpty) {
      _loadDocuments();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadDocuments() async {
    try {
      final documentos = await DocumentosService.loadDocumentos(
        widget.idUsuario,
      );

      setState(() {
        _documentosPorAnio = documentos['documentos'];
        _descriptionsAndDatesPorAnio = documentos['descriptions'];
        _seleccionadosPorAnio = documentos['seleccionados'];
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar documentos: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = themeNotifier.isDarkMode;

    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            nombreUsuario: widget.nombre,
            correoUsuario: widget.correo,
            currentRoute: 'documentacion',
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
                // Ya estamos aquí
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
            idUsuario: widget.idUsuario,
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
                        Icon(Icons.folder, color: Color(0xFFA42429), size: 32),
                        SizedBox(width: 12),
                        Text(
                          'Documentación',
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
                    child:
                        _documentosPorAnio.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 48,
                                    color: Color(0xFFA42429),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No hay documentos disponibles',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Color(0xFF181C32),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : Scrollbar(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  int crossAxisCount;
                                  double childAspectRatio;
                                  double spacing;

                                  if (constraints.maxWidth > 900) {
                                    crossAxisCount = 3;
                                    childAspectRatio = 1.5;
                                    spacing = 16;
                                  } else if (constraints.maxWidth > 600) {
                                    crossAxisCount = 2;
                                    childAspectRatio = 1.3;
                                    spacing = 16;
                                  } else {
                                    crossAxisCount = 1;
                                    childAspectRatio = 1.2;
                                    spacing = 8;
                                  }

                                  return GridView.builder(
                                    padding: EdgeInsets.all(spacing),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: crossAxisCount,
                                          crossAxisSpacing: spacing,
                                          mainAxisSpacing: spacing,
                                          childAspectRatio: childAspectRatio,
                                        ),
                                    itemCount: _documentosPorAnio.keys.length,
                                    itemBuilder: (context, anioIndex) {
                                      final anio = _documentosPorAnio.keys
                                          .elementAt(anioIndex);
                                      Color cardColor =
                                          (anioIndex % 2 == 0)
                                              ? const Color(0xFFA42429)
                                              : const Color(0xFF181C32);
                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (
                                                    context,
                                                  ) => DocumentosAnioPage(
                                                    anio: anio,
                                                    documentos:
                                                        _documentosPorAnio[anio]!,
                                                    descriptionsAndDates:
                                                        _descriptionsAndDatesPorAnio[anio]!,
                                                    seleccionados:
                                                        _seleccionadosPorAnio[anio]!,
                                                    idUsuario: widget.idUsuario,
                                                    onDocumentosContabilizadosChanged:
                                                        widget
                                                            .onDocumentosContabilizadosChanged,
                                                    dni: widget.dni,
                                                    licencia: widget.licencia,
                                                    contrasena:
                                                        widget.contrasena,
                                                    nombre: widget.nombre,
                                                    correo: widget.correo,
                                                    idTipoUsuario:
                                                        widget.idTipoUsuario,
                                                  ),
                                            ),
                                          );
                                        },
                                        child: Card(
                                          color: cardColor,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          elevation: 4,
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.folder,
                                                  color: Colors.white,
                                                  size: 48,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Año $anio',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
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
}
