import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';
import 'package:intl/intl.dart';
import 'sidebar.dart';
import 'dashboard.dart';
import 'documentacion_page.dart';
import 'tablon.dart';
import 'upload_pdf_page.dart';
import 'factura_servicio_uberneta_page.dart';
import 'calendario.dart';
import 'settings_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/documentos_service.dart';
import 'login.dart';

class EstadoFacturasPage extends StatefulWidget {
  final String idUsuario;
  final String nombreUsuario;
  final String correoUsuario;
  final String dni;
  final String licencia;
  final String contrasena;
  final int idTipoUsuario;

  const EstadoFacturasPage({
    Key? key,
    required this.idUsuario,
    required this.nombreUsuario,
    required this.correoUsuario,
    required this.dni,
    required this.licencia,
    required this.contrasena,
    required this.idTipoUsuario,
  }) : super(key: key);

  @override
  _EstadoFacturasPageState createState() => _EstadoFacturasPageState();
}

class _EstadoFacturasPageState extends State<EstadoFacturasPage> {
  Future<List<Map<String, dynamic>>> fetchDocuments(int idUsuario) async {
    final response = await http.get(
      Uri.parse('${Config.baseUrl}fetch_pdfs_estado.php?idUsuario=$idUsuario'),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Error al obtener los documentos');
    }
  }

  int _selectedFilter = 0; // 0 para todos, 1 para subidas, 2 para leídas, etc.
  DateTime? _selectedDate; // Variable para almacenar la fecha seleccionada
  bool _isDeleting = false; // Variable para controlar el estado de eliminación

  void _abrirPdfEnNuevaPestana(
    String urlDocumento,
    String nombreDocumento,
  ) async {
    // Si urlDocumento ya es una URL completa, úsala directamente
    String fullUrl;
    if (urlDocumento.startsWith('http')) {
      fullUrl = urlDocumento;
    } else {
      // Concatenar la base, el ID del usuario y el nombre del documento
      fullUrl =
          '${Config.baseUrlSubirFacturas}${widget.idUsuario}/$nombreDocumento';
    }
    await launchUrl(Uri.parse(fullUrl), webOnlyWindowName: '_blank');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            nombreUsuario: widget.nombreUsuario,
            correoUsuario: widget.correoUsuario,
            currentRoute: 'estado_facturas',
            onNavigate: (route) async {
              if (route == 'dashboard') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => MyHomePage(
                          title: 'Panel de control',
                          dni: widget.dni,
                          nombre: widget.nombreUsuario,
                          correo: widget.correoUsuario,
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
                          descriptionsAndDatesPorAnio:
                              documentos['descriptions'],
                          seleccionadosPorAnio: documentos['seleccionados'],
                          idUsuario: widget.idUsuario,
                          onDocumentosContabilizadosChanged: () {},
                          dni: widget.dni,
                          licencia: widget.licencia,
                          contrasena: widget.contrasena,
                          nombre: widget.nombreUsuario,
                          correo: widget.correoUsuario,
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
                          nombre: widget.nombreUsuario,
                          correo: widget.correoUsuario,
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
                          nombre: widget.nombreUsuario,
                          correo: widget.correoUsuario,
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
                          nombre: widget.nombreUsuario,
                          correo: widget.correoUsuario,
                          contrasena: widget.contrasena,
                          licencia: widget.licencia,
                          tipoFactura: 'Servicio Uberneta',
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
                          nombreUsuario: widget.nombreUsuario,
                          correoUsuario: widget.correoUsuario,
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
                          nombre: widget.nombreUsuario,
                          correo: widget.correoUsuario,
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
            child: Scaffold(
              body: Container(
                color: Color(0xFFFFFFFF),
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
                            Icons.picture_as_pdf,
                            color: Color(0xFFA42429),
                            size: 32,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Estado Facturas',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedFilter = 0; // Todas
                              });
                            },
                            child: _buildLegendItem(Colors.grey, 'Todas'),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedFilter = 1; // Subidas
                              });
                            },
                            child: _buildLegendItem(
                              Colors.blueAccent,
                              'Subidas',
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedFilter = 2; // Leídas
                              });
                            },
                            child: _buildLegendItem(
                              Colors.greenAccent,
                              'Leídas',
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedFilter = 4; // Rechazadas
                              });
                            },
                            child: _buildLegendItem(
                              Color(0xFFA42429),
                              'Rechazadas',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFA42429),
                            ),
                            onPressed: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2101),
                              );
                              if (pickedDate != null &&
                                  pickedDate != _selectedDate) {
                                setState(() {
                                  _selectedDate = pickedDate;
                                });
                              }
                            },
                            child: Text(
                              _selectedDate == null
                                  ? 'Buscar por fecha'
                                  : 'Facturas del: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedDate =
                                    null; // Restablecer la fecha seleccionada
                              });
                            },
                            child: Text(
                              'Mostrar todo',
                              style: TextStyle(
                                color:
                                    Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color ??
                                    Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: fetchDocuments(int.parse(widget.idUsuario)),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          } else if (snapshot.hasError) {
                            return Center(
                              child: Text('Error: ${snapshot.error}'),
                            );
                          } else if (!snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return Center(
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
                            );
                          } else {
                            final filteredDocuments =
                                snapshot.data!.where((doc) {
                                  final url = doc['URLDocumento'];
                                  final title = doc['TituloDocumento'];
                                  final date = doc['FechaPublicacionDocumento'];
                                  if (url == null ||
                                      title == null ||
                                      date == null) {
                                    print(
                                      'Documento con datos incompletos: $doc',
                                    );
                                    return false; // Filtra documentos con datos incompletos
                                  }
                                  final matchesDate =
                                      _selectedDate == null ||
                                      date.startsWith(
                                        _selectedDate!.toIso8601String().split(
                                          'T',
                                        )[0],
                                      );
                                  if (_selectedFilter == 0) {
                                    return doc['IdEstadoDocumento'] != 3 &&
                                        matchesDate;
                                  }
                                  return doc['IdEstadoDocumento'] ==
                                          _selectedFilter &&
                                      matchesDate;
                                }).toList();

                            // Ordenar los documentos por fecha, más reciente primero
                            filteredDocuments.sort((a, b) {
                              final dateA = DateTime.parse(
                                a['FechaPublicacionDocumento'],
                              );
                              final dateB = DateTime.parse(
                                b['FechaPublicacionDocumento'],
                              );
                              return dateB.compareTo(dateA);
                            });

                            return ListView.builder(
                              itemCount: filteredDocuments.length,
                              itemBuilder: (context, index) {
                                final document = filteredDocuments[index];
                                final color = _getColorForStatus(
                                  document['IdEstadoDocumento'],
                                );
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 16,
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFFFFFFF),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.2),
                                        spreadRadius: 2,
                                        blurRadius: 5,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.picture_as_pdf,
                                      color: color,
                                      size: 32,
                                    ),
                                    title: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Text(
                                        document['TituloDocumento']
                                                ?.split('_')
                                                .skip(1)
                                                .join('_') ??
                                            'Sin título',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.copyWith(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (document['DescripcionDocumento'] !=
                                                null &&
                                            document['DescripcionDocumento']
                                                .isNotEmpty)
                                          Text(
                                            'Descripción: ${document['DescripcionDocumento']}',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium?.copyWith(
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface,
                                            ),
                                          ),
                                        Text(
                                          'Fecha: ${document['FechaPublicacionDocumento']}',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium?.copyWith(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                          ),
                                        ),
                                        if (document['IdEstadoDocumento'] == 4)
                                          Text(
                                            'Observaciones: ${document['ObservacionesFactura']}',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall?.copyWith(
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface,
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.remove_red_eye,
                                          color: Color(0xFFA42429),
                                        ),
                                        if (document['IdEstadoDocumento'] == 4)
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete,
                                              color: Color(0xFFA42429),
                                            ),
                                            onPressed: () {
                                              final documentId =
                                                  document['IdDocumentoFactura'];
                                              if (documentId != null) {
                                                _showDeleteConfirmationDialog(
                                                  documentId,
                                                  document['URLDocumento'],
                                                );
                                              }
                                            },
                                          ),
                                      ],
                                    ),
                                    onTap: () {
                                      final pdfUrl = document['URLDocumento'];
                                      final pdfNameCompleto =
                                          document['TituloDocumento'];

                                      if (pdfUrl != null &&
                                          pdfNameCompleto != null) {
                                        _abrirPdfEnNuevaPestana(
                                          pdfUrl,
                                          pdfNameCompleto,
                                        );
                                      }
                                    },
                                  ),
                                );
                              },
                            );
                          }
                        },
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

  Color _getColorForStatus(int status) {
    switch (status) {
      case 1:
        return Colors.blueAccent; // Subidas
      case 2:
        return Colors.greenAccent; // Leídas
      case 4:
        return Color(0xFFA42429); // Rechazadas
      default:
        return Colors.grey; // Default
    }
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Icon(Icons.picture_as_pdf, color: color, size: 16),
        const SizedBox(width: 4),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  // Mostrar cuadro de confirmación de eliminación
  void _showDeleteConfirmationDialog(int documentId, String documentUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: const Text(
            '¿Estás seguro de que deseas eliminar esta factura?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
              },
            ),
            TextButton(
              child: const Text('Eliminar'),
              onPressed: () async {
                Navigator.of(context).pop(); // Cierra el diálogo
                await _deleteDocument(documentId, documentUrl);
              },
            ),
          ],
        );
      },
    );
  }

  // Función para eliminar el documento de la base de datos
  Future<void> _deleteDocument(int documentId, String documentUrl) async {
    setState(() {
      _isDeleting = true; // Mostrar cargando
    });

    setState(() {
      _isDeleting = false; // Ocultar cargando
    });

    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}delete_document.php'),
        body: {'documentId': documentId.toString()},
      );
      print("Código de estado: ${response.statusCode}");
      print("Respuesta del response.body: " + response.body);
      if (response.statusCode == 200) {
        // Eliminar éxito
        _showDialog('Éxito', 'Factura eliminada exitosamente');
      } else {
        // Error al eliminar el documento
        _showDialog('Error', 'Error al eliminar la factura');
      }
    } catch (e) {
      // Manejo de error
      print('Error al eliminar el documento: $e');
      _showDialog('Error', 'Error en la eliminación');
    }
  }

  // Mostrar cuadro de diálogo con mensaje
  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
                setState(() {}); // Recarga la lista después de la eliminación
              },
            ),
          ],
        );
      },
    );
  }
}
