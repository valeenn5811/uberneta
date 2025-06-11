import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'sidebar.dart';
import 'dashboard.dart' hide userDataNotifier;
import 'documentacion_page.dart';
import 'tablon.dart';
import 'upload_pdf_page.dart';
import 'factura_servicio_uberneta_page.dart';
import 'calendario.dart';
import 'settings_page.dart';
import 'login.dart';

class DocumentosAnioPageTablon extends StatefulWidget {
  final int anio;
  final String idUsuario;
  final String dni;
  final String licencia;
  final String contrasena;
  final List<Map<String, dynamic>> documentos;
  final String nombre;
  final String correo;
  final int idTipoUsuario;

  const DocumentosAnioPageTablon({
    Key? key,
    required this.anio,
    required this.documentos,
    required this.idUsuario,
    required this.dni,
    required this.licencia,
    required this.contrasena,
    required this.nombre,
    required this.correo,
    required this.idTipoUsuario,
  }) : super(key: key);

  @override
  _DocumentosAnioPageTablonState createState() =>
      _DocumentosAnioPageTablonState();
}

class _DocumentosAnioPageTablonState extends State<DocumentosAnioPageTablon> {
  Map<int, Map<String, List<String>>> documentosPorAnio = {};
  Map<int, Map<String, List<bool>>> seleccionadosPorAnio = {};
  Map<int, Map<String, List<String>>> descriptionsAndDatesPorAnio = {};

  @override
  void initState() {
    super.initState();
    _obtenerDocumentos();
  }

  Future<void> _obtenerDocumentos() async {
    final String url =
        '${Config.baseUrl}/fetch_pdfs_dashboard.php?idUsuario=${widget.idUsuario}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        setState(() {
          documentosPorAnio.clear();
          seleccionadosPorAnio.clear();
          descriptionsAndDatesPorAnio.clear();

          for (int i = 0; i < data['other_data'].length; i++) {
            var doc = data['other_data'][i];
            final String? urlDocumento = doc['URLDocumento'] as String?;
            final int? idDocumento = doc['IDUsuario'] as int?;
            final int? idEstadoDocumento = doc['IdEstadoDocumento'] as int?;
            final int? anioDocumento = doc['AnioDocumento'] as int?;
            final String? tipoDocumento = doc['TipoDocumento'] as String?;

            final int idUsuarioInt = int.parse(widget.idUsuario);

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

              if (!documentosPorAnio.containsKey(anioDocumento)) {
                documentosPorAnio[anioDocumento!] = {};
                seleccionadosPorAnio[anioDocumento] = {};
                descriptionsAndDatesPorAnio[anioDocumento] = {};
              }

              if (!documentosPorAnio[anioDocumento]!.containsKey(categoria)) {
                documentosPorAnio[anioDocumento]![categoria] = [];
                seleccionadosPorAnio[anioDocumento]![categoria] = [];
                descriptionsAndDatesPorAnio[anioDocumento]![categoria] = [];
              }

              documentosPorAnio[anioDocumento]![categoria]!.add(urlDocumento);
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

  void _abrirPdfEnNuevaPestana(
    String urlDocumento,
    String nombreDocumento,
  ) async {
    // Si urlDocumento ya es una URL completa, úsala directamente
    String fullUrl;
    if (urlDocumento.startsWith('http')) {
      fullUrl = urlDocumento;
    } else {
      // Concatenar la base y el nombre del documento
      fullUrl = '${Config.baseUrlDocumentosTodos}$nombreDocumento';
    }
    await launchUrl(Uri.parse(fullUrl), webOnlyWindowName: '_blank');
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    // Ordenar documentos por fecha de publicación, de más reciente a más antiguo
    widget.documentos.sort((a, b) {
      final fechaA = DateTime.parse(a['FechaPublicacionDocumento']);
      final fechaB = DateTime.parse(b['FechaPublicacionDocumento']);
      return fechaB.compareTo(fechaA);
    });

    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            nombreUsuario: widget.nombre,
            correoUsuario: widget.correo,
            currentRoute: 'tablon',
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
                          documentosPorAnio: documentosPorAnio,
                          descriptionsAndDatesPorAnio:
                              descriptionsAndDatesPorAnio,
                          seleccionadosPorAnio: seleccionadosPorAnio,
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
                          nombre: '',
                          correo: '',
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
                          nombre: '',
                          correo: '',
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
                          nombre: '',
                          correo: '',
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
                    padding: EdgeInsets.only(
                      top: 32.0,
                      left: isMobile ? 8.0 : 24.0,
                      right: isMobile ? 8.0 : 24.0,
                      bottom: 8.0,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.folder,
                          color: Color(0xFFA42429),
                          size: isMobile ? 24 : 32,
                        ),
                        SizedBox(width: isMobile ? 4 : 12),
                        Expanded(
                          child: Text(
                            'Documentos del Año ${widget.anio}',
                            style: TextStyle(
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Color(0xFF181C32),
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 18 : 24,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      color: const Color(0xFFFFFFFF),
                      child:
                          widget.documentos.isEmpty
                              ? const Center(
                                child: Text('No hay documentos disponibles.'),
                              )
                              : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: widget.documentos.length,
                                itemBuilder: (context, index) {
                                  final documento = widget.documentos[index];
                                  final tituloInterfaz =
                                      documento['TituloDocumento']
                                          ?.split('/')
                                          .last
                                          ?.replaceFirst(
                                            RegExp(r'^[^_]+_'),
                                            '',
                                          ) ??
                                      'Sin título';
                                  final titulo =
                                      documento['TituloDocumento'] ??
                                      'Sin título';
                                  final url = documento['URLDocumento'] ?? '';
                                  final descripcion =
                                      documento['DescripcionDocumento'] ?? '';
                                  final fecha =
                                      documento['FechaPublicacionDocumento'] ??
                                      'Fecha no disponible';

                                  return Container(
                                    margin: EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: isMobile ? 8 : 16,
                                    ),
                                    padding: EdgeInsets.all(isMobile ? 8 : 16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFFFFF),
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
                                        color: Color(0xFFA42429),
                                        size: isMobile ? 24 : 32,
                                      ),
                                      title: Text(
                                        tituloInterfaz,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.copyWith(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (descripcion.isNotEmpty)
                                            Text(
                                              'Descripción: $descripcion',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodyMedium?.copyWith(
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.onSurface,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          Text(
                                            'Fecha: $fecha',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium?.copyWith(
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                      trailing: const Icon(
                                        Icons.remove_red_eye,
                                        color: Color(0xFFA42429),
                                      ),
                                      onTap:
                                          () => _abrirPdfEnNuevaPestana(
                                            url,
                                            titulo,
                                          ),
                                    ),
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
