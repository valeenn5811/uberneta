import 'theme_notifier.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'pdf_viewer_page.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'sidebar.dart';
import 'dashboard.dart';
import 'tablon.dart';
import 'upload_pdf_page.dart';
import 'factura_servicio_uberneta_page.dart';
import 'calendario.dart';
import 'settings_page.dart';
import 'login.dart';

class DocumentosAnioPage extends StatelessWidget {
  final int anio;
  final Map<String, List<String>> documentos;
  final Map<String, List<String>> descriptionsAndDates;
  final Map<String, List<bool>> seleccionados;
  final String idUsuario;
  final Function onDocumentosContabilizadosChanged;
  final String dni;
  final String licencia;
  final String contrasena;
  final String nombre;
  final String correo;
  final int idTipoUsuario;

  const DocumentosAnioPage({
    Key? key,
    required this.anio,
    required this.documentos,
    required this.descriptionsAndDates,
    required this.seleccionados,
    required this.idUsuario,
    required this.onDocumentosContabilizadosChanged,
    required this.dni,
    required this.licencia,
    required this.contrasena,
    required this.nombre,
    required this.correo,
    required this.idTipoUsuario,
  }) : super(key: key);

  static void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  static Future<void> openPdf(
    BuildContext context,
    String pdfUrl,
    String idUsuario,
  ) async {
    if (pdfUrl.isEmpty) {
      _showErrorSnackbar(context, 'URL del PDF no válida.');
      return;
    }

    final String fullUrl =
        pdfUrl.startsWith('http')
            ? pdfUrl
            : '${Config.baseUrlDocumentos}/${idUsuario}/${pdfUrl.split('/').last}';
    final String pdfName = fullUrl.split('/').last;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerPage(pdfUrl: fullUrl, pdfName: pdfName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriasConDocumentos =
        documentos.keys
            .where((categoria) => documentos[categoria]!.isNotEmpty)
            .toList();
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = themeNotifier.isDarkMode;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            nombreUsuario: nombre,
            correoUsuario: correo,
            currentRoute: 'documentacion',
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
                          tipoFactura: 'Servicio Taxi',
                          idTipoUsuario: idTipoUsuario,
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
              } else if (route == 'documentacion') {
                Navigator.pop(context);
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
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      top: 32.0,
                      left: isMobile ? 4.0 : 24.0,
                      right: isMobile ? 4.0 : 24.0,
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
                            'Documentos del Año $anio',
                            style: TextStyle(
                              color: isDark ? Colors.white : Color(0xFF181C32),
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
                    child:
                        categoriasConDocumentos.isEmpty
                            ? const Center(child: CircularProgressIndicator())
                            : GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount:
                                        MediaQuery.of(context).size.width > 900
                                            ? 3
                                            : MediaQuery.of(
                                                  context,
                                                ).size.width >
                                                600
                                            ? 2
                                            : 1,
                                    crossAxisSpacing:
                                        MediaQuery.of(context).size.width < 600
                                            ? 8
                                            : 16,
                                    mainAxisSpacing:
                                        MediaQuery.of(context).size.width < 600
                                            ? 8
                                            : 16,
                                    childAspectRatio:
                                        MediaQuery.of(context).size.width > 900
                                            ? 1.5
                                            : MediaQuery.of(
                                                  context,
                                                ).size.width >
                                                600
                                            ? 1.3
                                            : 1.2,
                                  ),
                              itemCount: categoriasConDocumentos.length,
                              itemBuilder: (context, index) {
                                final categoria =
                                    categoriasConDocumentos[index];
                                final documentosCategoria =
                                    documentos[categoria]!;
                                Color cardColor =
                                    (index % 2 == 0)
                                        ? Color(0xFFA42429)
                                        : Color(0xFF181C32);

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (
                                              context,
                                            ) => DocumentosCategoriaPage(
                                              categoria: categoria,
                                              documentos: documentosCategoria,
                                              descriptionsAndDates:
                                                  descriptionsAndDates[categoria] ??
                                                  [],
                                              idUsuario: idUsuario,
                                              onDocumentosContabilizadosChanged:
                                                  onDocumentosContabilizadosChanged,
                                              dni: dni,
                                              licencia: licencia,
                                              contrasena: contrasena,
                                              nombre: nombre,
                                              correo: correo,
                                              anio: anio,
                                              idTipoUsuario: idTipoUsuario,
                                            ),
                                      ),
                                    );
                                  },
                                  child: Card(
                                    color: cardColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
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
                                            categoria,
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

class DocumentosCategoriaPage extends StatefulWidget {
  final String categoria;
  final List<String> documentos;
  final List<String> descriptionsAndDates;
  final String idUsuario;
  final Function onDocumentosContabilizadosChanged;
  final String dni;
  final String licencia;
  final String contrasena;
  final String nombre;
  final String correo;
  final int anio;
  final int idTipoUsuario;

  const DocumentosCategoriaPage({
    Key? key,
    required this.categoria,
    required this.documentos,
    required this.descriptionsAndDates,
    required this.idUsuario,
    required this.onDocumentosContabilizadosChanged,
    required this.dni,
    required this.licencia,
    required this.contrasena,
    required this.nombre,
    required this.correo,
    required this.anio,
    required this.idTipoUsuario,
  }) : super(key: key);

  @override
  _DocumentosCategoriaPageState createState() =>
      _DocumentosCategoriaPageState();
}

class _DocumentosCategoriaPageState extends State<DocumentosCategoriaPage> {
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _abrirPdfEnNuevaPestana(
    String urlDocumento,
    String nombreDocumento,
  ) async {
    String fullUrl =
        '${Config.baseUrlDocumentos}/${widget.idUsuario}/$nombreDocumento'
            .replaceAll(RegExp(r'(?<!:)//'), '/');

    try {
      final Uri uri = Uri.parse(fullUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          webOnlyWindowName: '_blank',
          mode: LaunchMode.externalApplication,
        );
      } else {
        _showErrorSnackbar('No se pudo abrir el documento');
      }
    } catch (e) {
      _showErrorSnackbar('Error al abrir el documento: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = themeNotifier.isDarkMode;
    final isMobile = MediaQuery.of(context).size.width < 600;

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
              } else if (route == 'documentacion') {
                Navigator.pop(context);
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
                          size: isMobile ? 20 : 32,
                        ),
                        SizedBox(width: isMobile ? 0 : 12),
                        Expanded(
                          child: Text(
                            '  ${widget.categoria} - Año ${widget.anio}',
                            style: TextStyle(
                              color: isDark ? Colors.white : Color(0xFF181C32),
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
                                final nombreOriginal =
                                    documento.split('/').last;
                                final tituloInterfaz = nombreOriginal
                                    .replaceAll(RegExp(r'^\d+_'), '');
                                final descripcion =
                                    widget.descriptionsAndDates[index];

                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 16,
                                  ),
                                  padding: const EdgeInsets.all(16),
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
                                      size:
                                          MediaQuery.of(context).size.width <
                                                  600
                                              ? 24
                                              : 32,
                                    ),
                                    title: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Text(
                                        tituloInterfaz,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.copyWith(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                          fontWeight: FontWeight.bold,
                                          fontSize:
                                              MediaQuery.of(
                                                        context,
                                                      ).size.width <
                                                      600
                                                  ? 14
                                                  : 16,
                                        ),
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (descripcion.isNotEmpty)
                                          Text(
                                            descripcion,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium?.copyWith(
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface,
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: const Icon(
                                      Icons.remove_red_eye,
                                      color: Color(0xFFA42429),
                                    ),
                                    onTap:
                                        () => _abrirPdfEnNuevaPestana(
                                          documento,
                                          nombreOriginal,
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
}
