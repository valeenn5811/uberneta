import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'config.dart';
import 'documentos_anio_page_tablon.dart';
import 'dart:async';
import 'sidebar.dart';
import 'dashboard.dart' hide userDataNotifier;
import 'documentacion_page.dart';
import 'calendario.dart';
import 'login.dart';

class TablonPage extends StatefulWidget {
  final String dni;
  final String id;
  final String licencia;
  final String contrasena;
  final String nombre;
  final String correo;
  final int idTipoUsuario;

  const TablonPage({
    super.key,
    required this.dni,
    required this.id,
    required this.licencia,
    required this.contrasena,
    required this.nombre,
    required this.correo,
    required this.idTipoUsuario,
  });

  @override
  _TablonPageState createState() => _TablonPageState();
}

class _TablonPageState extends State<TablonPage>
    with SingleTickerProviderStateMixin {
  Map<int, List<Map<String, dynamic>>> documentosPorAnio = {};
  List<Map<String, dynamic>> documentosTablon = [];

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    // Asegurarnos de que el layout se complete antes de cualquier interacción
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });

    _fetchDocuments();
    _fetchTablonDocuments();

    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchDocuments() async {
    final String phpUrl = '${Config.baseUrl}/fetch_pdfs.php';

    try {
      final response = await http.get(Uri.parse(phpUrl));

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        print('Datos recibidos: $data');

        setState(() {
          documentosPorAnio.clear();

          if (data is Map<String, dynamic>) {
            data.forEach((anio, documentos) {
              documentosPorAnio[int.parse(
                anio,
              )] = List<Map<String, dynamic>>.from(documentos);
            });
          }
        });
      } else {
        print('Error al obtener los documentos: ${response.statusCode}');
      }
    } catch (e) {
      print('Excepción al obtener los documentos: $e');
    }
  }

  Future<void> _fetchTablonDocuments() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/fetch_tablon_documents.php'),
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

  Widget _buildTablonSection() {
    return SizedBox.shrink();
  }

  void _logout() {
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
                try {
                  final response = await http.post(
                    Uri.parse('${Config.baseUrl}eliminar_token.php'),
                    headers: <String, String>{
                      'Content-Type': 'application/json; charset=UTF-8',
                    },
                    body: jsonEncode(<String, String>{'dni': widget.dni}),
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
  }

  @override
  Widget build(BuildContext context) {
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
              }
            },
            onLogout: _logout,
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
                  _buildTablonSection(),
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
                          Icons.campaign,
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
                            'Tablón de anuncios',
                            style: TextStyle(
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Color(0xFF181C32),
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
                    child:
                        documentosPorAnio.isEmpty
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
                            : GridView.builder(
                              padding: EdgeInsets.all(
                                MediaQuery.of(context).size.width < 600
                                    ? 8
                                    : 16,
                              ),
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
                              itemCount: documentosPorAnio.keys.length,
                              itemBuilder: (context, anioIndex) {
                                final anio = documentosPorAnio.keys.elementAt(
                                  anioIndex,
                                );
                                final documentos = documentosPorAnio[anio]!;
                                Color cardColor =
                                    (anioIndex % 2 == 0)
                                        ? Color(0xFFA42429)
                                        : Color(0xFF181C32);
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                DocumentosAnioPageTablon(
                                                  anio: anio,
                                                  documentos: documentos,
                                                  idUsuario: widget.id,
                                                  dni: widget.dni,
                                                  licencia: widget.licencia,
                                                  contrasena: widget.contrasena,
                                                  nombre: widget.nombre,
                                                  correo: widget.correo,
                                                  idTipoUsuario:
                                                      widget.idTipoUsuario,
                                                ),
                                      ),
                                    );
                                  },
                                  child: Stack(
                                    children: [
                                      Card(
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
                                    ],
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
