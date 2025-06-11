import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_selector/file_selector.dart';
import 'config.dart';
import 'package:http_parser/http_parser.dart';
import 'sidebar.dart';
import 'dashboard.dart' hide userDataNotifier;
import 'documentacion_page.dart';
import 'tablon.dart';
import 'factura_servicio_uberneta_page.dart';
import 'calendario.dart';
import 'settings_page.dart';
import 'dart:convert';
import 'services/documentos_service.dart';
import 'login.dart';

class UploadPdfPage extends StatefulWidget {
  final String idUsuario;
  final String dni;
  final String nombre;
  final String correo;
  final String licencia;
  final String contrasena;
  final int idTipoUsuario;

  const UploadPdfPage({
    Key? key,
    required this.idUsuario,
    required this.dni,
    required this.nombre,
    required this.correo,
    required this.licencia,
    required this.contrasena,
    required this.idTipoUsuario,
  }) : super(key: key);

  @override
  _UploadPdfPageState createState() => _UploadPdfPageState();
}

class _UploadPdfPageState extends State<UploadPdfPage> {
  final TextEditingController _descripcionController = TextEditingController();
  XFile? _selectedFile;
  bool _isLoading = false;

  Future<void> _selectFile() async {
    try {
      final typeGroup = XTypeGroup(
        label: 'PDFs',
        extensions: ['pdf'],
        mimeTypes: ['application/pdf'],
        uniformTypeIdentifiers: ['com.adobe.pdf'],
      );

      final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);

      if (file != null) {
        if (file.name.toLowerCase().endsWith('.pdf')) {
          setState(() {
            _selectedFile = file;
            print('Nombre original del archivo: ${file.name}');
          });
        } else {
          _showSnackBar('El archivo seleccionado no es un PDF.');
        }
      } else {
        _showSnackBar('No se seleccionó ningún archivo.');
      }
    } catch (e) {
      _showSnackBar('Error al seleccionar el archivo: $e');
    }
  }

  String renameFile(XFile file) {
    var replaceName = file.name;
    var replaceNameFile = replaceName.replaceAll(RegExp(r'[^0-9a-zA-Z.]'), "");
    var newName =
        DateTime.now().millisecondsSinceEpoch.toString() +
        '_' +
        replaceNameFile;
    return newName;
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null) {
      _showSnackBar('Por favor, adjunta una factura.');
      return;
    }

    if (_descripcionController.text.isEmpty) {
      final confirm = await _showConfirmationDialog();
      if (!confirm) return;
    }

    setState(() => _isLoading = true);

    final descripcion = _descripcionController.text;
    final fileName = renameFile(_selectedFile!);
    final fileURL = '/uploads/facturas/${widget.idUsuario}/$fileName';

    print('Dirección de subida del archivo: $fileURL');

    try {
      // Primero registramos en la base de datos con el mismo nombre de archivo
      if (await _registerInDatabase(descripcion, fileURL, fileName)) {
        // Subir el archivo a tu backend usando HTTP POST (ejemplo)
        if (await _uploadToBackend(_selectedFile!, fileName)) {
          _showSuccessDialog();
        }
      }
    } catch (e) {
      _showSnackBar('Error en la subida: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _registerInDatabase(
    String descripcion,
    String fileURL,
    String fileName,
  ) async {
    final dbUri = Uri.parse('${Config.baseUrl}subirFactura.php');
    final dbResponse = await http.post(
      dbUri,
      body: {
        'IdUsuario': '0',
        'IdConductor': widget.idUsuario,
        'TituloDocumento': Uri.encodeComponent(
          fileName,
        ), // Guardamos el nombre del archivo en la base de datos
        'DescripcionDocumento': descripcion,
        'URLDocumento': fileURL,
        'FechaPublicacionDocumento': DateTime.now().toIso8601String(),
        'IdEstadoDocumento': '1',
        'ObservacionesFactura': '',
      },
    );

    if (dbResponse.statusCode != 200) {
      _showSnackBar('Error al registrar los datos en la base de datos.');
      return false;
    }
    return true;
  }

  Future<bool> _uploadToBackend(XFile file, String fileName) async {
    try {
      final uri = Uri.parse('${Config.baseUrl}upload_pdf_web.php');
      final request = http.MultipartRequest('POST', uri);
      request.fields['fileName'] = fileName;
      request.fields['userId'] = widget.idUsuario;
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          await file.readAsBytes(),
          filename: fileName,
          contentType: MediaType('application', 'pdf'),
        ),
      );
      final response = await request.send();
      if (response.statusCode == 200) {
        return true;
      } else {
        _showSnackBar('Error al subir el archivo al backend.');
        return false;
      }
    } catch (e) {
      _showSnackBar('Error al subir el archivo: $e');
      return false;
    }
  }

  Future<bool> _showConfirmationDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Advertencia'),
          content: Text(
            'Está a punto de subir una factura sin descripción. ¿Desea continuar?',
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Continuar'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    ).then((value) => value ?? false);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Éxito'),
          content: Text('La factura se ha subido correctamente.'),
          actions: <Widget>[
            TextButton(
              child: Text('Aceptar'),
              onPressed: () {
                Navigator.of(context).pop();
                // Navegar al dashboard con los datos actualizados
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => MyHomePage(
                          title: 'Dashboard',
                          dni: widget.dni,
                          nombre: widget.nombre,
                          correo: widget.correo,
                          id: widget.idUsuario,
                          licencia: widget.licencia,
                          token: '',
                          contrasena: widget.contrasena,
                          idTipoUsuario: widget.idTipoUsuario,
                        ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildBody());
  }

  Widget _buildBody() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Sidebar(
          nombreUsuario: widget.nombre,
          correoUsuario: widget.correo,
          currentRoute: 'subir_facturas',
          idTipoUsuario: widget.idTipoUsuario,
          onNavigate: (route) async {
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
              final documentos = await DocumentosService.loadDocumentos(
                widget.idUsuario,
              );
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => DocumentacionPage(
                        documentosPorAnio: documentos['documentos'],
                        descriptionsAndDatesPorAnio: documentos['descriptions'],
                        seleccionadosPorAnio: documentos['seleccionados'],
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
              return;
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
                              'Content-Type': 'application/json; charset=UTF-8',
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
        ),
        Expanded(
          child: Container(
            color: const Color(0xFFFFFFFF),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    top: 16.0, // Ajustado para móvil
                    left: 16.0,
                    right: 16.0,
                    bottom: 8.0,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.upload_file,
                        color: Color(0xFFA42429),
                        size: 28, // Ajustado para móvil
                      ),
                      SizedBox(width: 8), // Ajustado para móvil
                      Text(
                        'Subir Factura',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Color(0xFF181C32),
                          fontWeight: FontWeight.bold,
                          fontSize: 20, // Ajustado para móvil
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0), // Ajustado para móvil
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          15,
                        ), // Ajustado para móvil
                      ),
                      color: const Color(0xFFFFFFFF),
                      shadowColor: Colors.black.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(
                          16.0,
                        ), // Ajustado para móvil
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Detalles del Documento',
                              style: TextStyle(
                                fontSize: 18, // Ajustado para móvil
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            SizedBox(height: 16), // Ajustado para móvil
                            TextField(
                              controller: _descripcionController,
                              decoration: InputDecoration(
                                labelText: 'Descripción del Documento',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    8,
                                  ), // Ajustado para móvil
                                ),
                              ),
                            ),
                            SizedBox(height: 16), // Ajustado para móvil
                            Center(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFA42429),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ), // Ajustado para móvil
                                ),
                                onPressed: _selectFile,
                                icon: Icon(
                                  Icons.attach_file,
                                  color: Colors.white,
                                  size: 20, // Ajustado para móvil
                                ),
                                label: Text(
                                  'Adjuntar Factura',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 16, // Ajustado para móvil
                                  ),
                                ),
                              ),
                            ),
                            if (_selectedFile != null) ...[
                              ListTile(
                                leading: Icon(
                                  Icons.picture_as_pdf,
                                  color: Color(0xFFA42429),
                                  size: 24, // Ajustado para móvil
                                ),
                                title: Text(
                                  'Archivo seleccionado: ${_selectedFile!.name}',
                                  style: TextStyle(
                                    fontSize: 14,
                                  ), // Ajustado para móvil
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: Color(0xFFA42429),
                                    size: 20, // Ajustado para móvil
                                  ),
                                  onPressed:
                                      () =>
                                          setState(() => _selectedFile = null),
                                ),
                              ),
                            ],
                            SizedBox(height: 16), // Ajustado para móvil
                            Center(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      _selectedFile != null
                                          ? Color(0xFFA42429)
                                          : Colors.grey,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ), // Ajustado para móvil
                                ),
                                onPressed:
                                    _selectedFile != null ? _uploadFile : null,
                                child:
                                    _isLoading
                                        ? CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2, // Ajustado para móvil
                                        )
                                        : Text(
                                          'Subir Factura',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color:
                                                isDarkMode ||
                                                        _selectedFile != null
                                                    ? Colors.white
                                                    : Colors.black,
                                            fontSize: 16, // Ajustado para móvil
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
              ],
            ),
          ),
        ),
      ],
    );
  }
}
