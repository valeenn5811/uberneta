import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'sidebar.dart';
import 'dashboard.dart';
import 'documentacion_page.dart';
import 'calendario.dart';
import 'tablon.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'login.dart';

class AdminTablonPage extends StatefulWidget {
  final String adminId;
  final String adminName;
  final int idTipoUsuario;
  final String dni;
  final String correo;
  final String licencia;
  final String contrasena;

  const AdminTablonPage({
    Key? key,
    required this.adminId,
    required this.adminName,
    required this.idTipoUsuario,
    required this.dni,
    required this.correo,
    required this.licencia,
    required this.contrasena,
  }) : super(key: key);

  @override
  _AdminTablonPageState createState() => _AdminTablonPageState();
}

class _AdminTablonPageState extends State<AdminTablonPage> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();
  FilePickerResult? _selectedFile;
  bool _isUploading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> documentosTablon = [];

  // Variables para Documentación
  Map<int, Map<String, List<String>>> documentosPorAnioDashboard = {};
  Map<int, Map<String, List<bool>>> seleccionadosPorAnio = {};
  Map<int, Map<String, List<String>>> descriptionsAndDatesPorAnio = {};

  bool _isAdmin() {
    return widget.idTipoUsuario == 1 || widget.idTipoUsuario == 2;
  }

  @override
  void initState() {
    super.initState();
    print('Tipo de usuario recibido: ${widget.idTipoUsuario}');
    if (!_isAdmin()) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes permisos para acceder a esta página'),
          backgroundColor: Colors.red,
        ),
      );
    }
    _fetchTablonDocuments();
    _obtenerDocumentosDashboard();
  }

  Future<void> _fetchTablonDocuments() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}fetch_tablon_documents.php'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            documentosTablon = List<Map<String, dynamic>>.from(
              data['documentos'],
            );
          });
        }
      }
    } catch (e) {
      print('Error al obtener documentos del tablón: $e');
    }
  }

  Future<void> _obtenerDocumentosDashboard() async {
    final String url =
        '${Config.baseUrl}/fetch_pdfs_dashboard.php?idUsuario=${widget.adminId}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        setState(() {
          documentosPorAnioDashboard.clear();
          seleccionadosPorAnio.clear();
          descriptionsAndDatesPorAnio.clear();

          for (int i = 0; i < data['other_data'].length; i++) {
            var doc = data['other_data'][i];
            final String? urlDocumento = doc['URLDocumento'] as String?;
            final int? idDocumento = doc['IDUsuario'] as int?;
            final int? idEstadoDocumento = doc['IdEstadoDocumento'] as int?;
            final int? anioDocumento = doc['AnioDocumento'] as int?;
            final String? tipoDocumento = doc['TipoDocumento'] as String?;

            final int idUsuarioInt = int.parse(widget.adminId);

            if (idDocumento != null &&
                idDocumento == idUsuarioInt &&
                urlDocumento != null &&
                (idEstadoDocumento == 3 || idEstadoDocumento == 0)) {
              String categoria;
              if (tipoDocumento == 'F') {
                categoria = 'Facturas';
              } else if (tipoDocumento == 'I') {
                categoria = 'Impuestos';
              } else {
                categoria = 'Otros';
              }

              if (!documentosPorAnioDashboard.containsKey(anioDocumento)) {
                documentosPorAnioDashboard[anioDocumento!] = {};
                seleccionadosPorAnio[anioDocumento] = {};
                descriptionsAndDatesPorAnio[anioDocumento] = {};
              }

              if (!documentosPorAnioDashboard[anioDocumento]!.containsKey(
                categoria,
              )) {
                documentosPorAnioDashboard[anioDocumento]![categoria] = [];
                seleccionadosPorAnio[anioDocumento]![categoria] = [];
                descriptionsAndDatesPorAnio[anioDocumento]![categoria] = [];
              }

              documentosPorAnioDashboard[anioDocumento]![categoria]!.add(
                urlDocumento,
              );
              seleccionadosPorAnio[anioDocumento]![categoria]!.add(false);

              var descFecha = data['descriptions_and_dates'][i];
              final String descripcion =
                  descFecha['DescripcionDocumento'] ?? 'Sin descripción';
              final String fecha =
                  descFecha['FechaPublicacionDocumento'] ??
                  'Fecha no disponible';

              descriptionsAndDatesPorAnio[anioDocumento]![categoria]!.add(
                'Descripción: $descripcion, Fecha: $fecha',
              );
            }
          }
        });
      }
    } catch (e) {
      print('Error al obtener documentos: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        setState(() {
          _selectedFile = result;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al seleccionar el archivo: $e';
      });
    }
  }

  Future<void> _uploadDocument() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null) {
      setState(() {
        _errorMessage = 'Por favor, selecciona un archivo PDF';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      String fileName = _selectedFile!.files.first.name;
      MultipartFile multipartFile;
      if (kIsWeb) {
        // En web, usar bytes
        final bytes = _selectedFile!.files.first.bytes;
        if (bytes == null) throw Exception('No se pudo leer el archivo en web');
        multipartFile = MultipartFile.fromBytes(bytes, filename: fileName);
      } else {
        // En móvil/escritorio, usar path
        final path = _selectedFile!.files.first.path;
        if (path == null) throw Exception('No se pudo leer el archivo');
        multipartFile = await MultipartFile.fromFile(path, filename: fileName);
      }

      FormData formData = FormData.fromMap({
        'file': multipartFile,
        'admin_id': int.parse(widget.adminId),
        'descripcionDocumento': _descripcionController.text,
      });

      Dio dio = Dio();
      final response = await dio.post(
        '${Config.baseUrl}/upload_tablon_document.php',
        data: formData,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        print(data);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Documento subido exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          _resetForm();
          _fetchTablonDocuments();
        } else {
          throw Exception(data['error'] ?? 'Error desconocido');
        }
      } else {
        throw Exception('Error en la respuesta del servidor');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al subir el documento: $e';
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _resetForm() {
    _descripcionController.clear();
    setState(() {
      _selectedFile = null;
      _errorMessage = null;
    });
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Está seguro de que desea cerrar sesión?'),
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
                await _handleLogout();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}eliminar_token.php'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{'dni': widget.dni}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        print('Token eliminado correctamente');
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } catch (e) {
      print('Error en la solicitud: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin()) {
      return const Scaffold(
        body: Center(
          child: Text('No tienes permisos para acceder a esta página'),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            nombreUsuario: widget.adminName,
            correoUsuario: widget.correo,
            currentRoute: 'admin_tablon',
            onNavigate: (route) {
              if (route == 'dashboard') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => MyHomePage(
                          title: 'Panel de control',
                          dni: widget.dni,
                          nombre: widget.adminName,
                          correo: widget.correo,
                          id: widget.adminId,
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
                          documentosPorAnio: documentosPorAnioDashboard,
                          descriptionsAndDatesPorAnio:
                              descriptionsAndDatesPorAnio,
                          seleccionadosPorAnio: seleccionadosPorAnio,
                          idUsuario: widget.adminId,
                          onDocumentosContabilizadosChanged: () {},
                          dni: widget.dni,
                          licencia: widget.licencia,
                          contrasena: widget.contrasena,
                          nombre: widget.adminName,
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
                          id: widget.adminId,
                          licencia: widget.licencia,
                          contrasena: widget.contrasena,
                          nombre: widget.adminName,
                          correo: widget.correo,
                          idTipoUsuario: widget.idTipoUsuario,
                        ),
                  ),
                );
              } else if (route == 'calendario') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => CalendarioPage(
                          userId: widget.adminId,
                          nombreUsuario: widget.adminName,
                          correoUsuario: widget.correo,
                          dni: widget.dni,
                          licencia: widget.licencia,
                          contrasena: widget.contrasena,
                          idTipoUsuario: widget.idTipoUsuario,
                        ),
                  ),
                );
              }
            },
            onLogout: _logout,
            dni: widget.dni,
            idUsuario: widget.adminId,
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
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.admin_panel_settings,
                                color: Color(0xFFA42429),
                                size:
                                    MediaQuery.of(context).size.width < 600
                                        ? 24
                                        : 32,
                              ),
                              SizedBox(
                                width:
                                    MediaQuery.of(context).size.width < 600
                                        ? 8
                                        : 12,
                              ),
                              Flexible(
                                child: Text(
                                  'Administrar Tablón de Anuncios',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : Color(0xFF181C32),
                                    fontWeight: FontWeight.bold,
                                    fontSize:
                                        MediaQuery.of(context).size.width < 600
                                            ? 18
                                            : 24,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Center(
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width < 600
                                      ? 400
                                      : 800,
                            ),
                            child: Card(
                              elevation: 0,
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(
                                  MediaQuery.of(context).size.width < 600
                                      ? 16.0
                                      : 24.0,
                                ),
                                child: SingleChildScrollView(
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          'Subir Nuevo Documento',
                                          style: TextStyle(
                                            fontSize:
                                                MediaQuery.of(
                                                          context,
                                                        ).size.width <
                                                        600
                                                    ? 20
                                                    : 24,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF181C32),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(
                                          height:
                                              MediaQuery.of(
                                                        context,
                                                      ).size.width <
                                                      600
                                                  ? 24
                                                  : 32,
                                        ),
                                        TextFormField(
                                          controller: _descripcionController,
                                          decoration: InputDecoration(
                                            labelText: 'Descripción',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey[50],
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal:
                                                      MediaQuery.of(
                                                                context,
                                                              ).size.width <
                                                              600
                                                          ? 12
                                                          : 16,
                                                  vertical:
                                                      MediaQuery.of(
                                                                context,
                                                              ).size.width <
                                                              600
                                                          ? 12
                                                          : 16,
                                                ),
                                          ),
                                          maxLines: 3,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Por favor, ingresa una descripción';
                                            }
                                            return null;
                                          },
                                        ),
                                        SizedBox(
                                          height:
                                              MediaQuery.of(
                                                        context,
                                                      ).size.width <
                                                      600
                                                  ? 16
                                                  : 24,
                                        ),
                                        ElevatedButton.icon(
                                          onPressed:
                                              _isUploading ? null : _pickFile,
                                          icon: Icon(
                                            Icons.upload_file,
                                            size:
                                                MediaQuery.of(
                                                          context,
                                                        ).size.width <
                                                        600
                                                    ? 20
                                                    : 24,
                                          ),
                                          label: Text(
                                            _selectedFile == null
                                                ? 'Seleccionar PDF'
                                                : MediaQuery.of(
                                                      context,
                                                    ).size.width <
                                                    600
                                                ? 'Archivo seleccionado'
                                                : 'Archivo seleccionado: ${_selectedFile!.files.first.name}',
                                            style: TextStyle(
                                              fontSize:
                                                  MediaQuery.of(
                                                            context,
                                                          ).size.width <
                                                          600
                                                      ? 14
                                                      : 16,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            padding: EdgeInsets.all(
                                              MediaQuery.of(
                                                        context,
                                                      ).size.width <
                                                      600
                                                  ? 12
                                                  : 16,
                                            ),
                                            backgroundColor: const Color(
                                              0xFF181C32,
                                            ),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                        if (_errorMessage != null)
                                          Padding(
                                            padding: EdgeInsets.only(
                                              top:
                                                  MediaQuery.of(
                                                            context,
                                                          ).size.width <
                                                          600
                                                      ? 12
                                                      : 16,
                                            ),
                                            child: Text(
                                              _errorMessage!,
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontSize:
                                                    MediaQuery.of(
                                                              context,
                                                            ).size.width <
                                                            600
                                                        ? 12
                                                        : 14,
                                              ),
                                            ),
                                          ),
                                        SizedBox(
                                          height:
                                              MediaQuery.of(
                                                        context,
                                                      ).size.width <
                                                      600
                                                  ? 24
                                                  : 32,
                                        ),
                                        ElevatedButton(
                                          onPressed:
                                              _isUploading
                                                  ? null
                                                  : _uploadDocument,
                                          style: ElevatedButton.styleFrom(
                                            padding: EdgeInsets.all(
                                              MediaQuery.of(
                                                        context,
                                                      ).size.width <
                                                      600
                                                  ? 12
                                                  : 16,
                                            ),
                                            backgroundColor: const Color(
                                              0xFFA42429,
                                            ),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child:
                                              _isUploading
                                                  ? SizedBox(
                                                    height:
                                                        MediaQuery.of(
                                                                  context,
                                                                ).size.width <
                                                                600
                                                            ? 20
                                                            : 24,
                                                    width:
                                                        MediaQuery.of(
                                                                  context,
                                                                ).size.width <
                                                                600
                                                            ? 20
                                                            : 24,
                                                    child:
                                                        const CircularProgressIndicator(
                                                          color: Colors.white,
                                                        ),
                                                  )
                                                  : Text(
                                                    'Subir Documento',
                                                    style: TextStyle(
                                                      fontSize:
                                                          MediaQuery.of(
                                                                    context,
                                                                  ).size.width <
                                                                  600
                                                              ? 14
                                                              : 16,
                                                      fontWeight:
                                                          FontWeight.bold,
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
                        );
                      },
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

  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }
}
