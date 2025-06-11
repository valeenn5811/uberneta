import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login.dart';
import 'config.dart';
import 'calendario.dart';
import 'tablon.dart';
import 'settings_page.dart';
import 'upload_pdf_page.dart';
import 'factura_servicio_uberneta_page.dart';
import 'documentacion_page.dart';
import 'theme_notifier.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'sidebar.dart';
import 'admin_tablon_page.dart';
import 'admin_facturas_page.dart';
import 'admin_usuarios_page.dart';

class UserDataNotifier extends ValueNotifier<Map<String, String>> {
  UserDataNotifier(Map<String, String> value) : super(value);
}

final userDataNotifier = UserDataNotifier({'nombre': '', 'correo': ''});

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
    required this.dni,
    required this.nombre,
    required this.correo,
    required this.id,
    required this.licencia,
    required this.contrasena,
    required this.idTipoUsuario,
    required this.token,
  });

  final String title;
  final String dni;
  final String nombre;
  final String correo;
  final String id;
  final String licencia;
  final String contrasena;
  final int idTipoUsuario;
  final String token;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late String nombreUsuario;
  late String correoUsuario;
  late String idUsuario;

  Map<int, Map<String, List<String>>> documentosPorAnio = {};
  Map<int, Map<String, List<bool>>> seleccionadosPorAnio = {};
  Map<int, Map<String, List<String>>> descriptionsAndDatesPorAnio = {};

  PageController _pageController = PageController();
  int _currentPage = 0;

  ThemeNotifier? themeNotifier;

  late AnimationController _animationController;

  // Listas separadas para elementos de menú comunes y de administración
  List<Map<String, dynamic>> _commonMenuItems = [];
  List<Map<String, dynamic>> _adminMenuItems = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    themeNotifier = Provider.of<ThemeNotifier>(context);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Asegurarnos de que el layout se complete antes de cualquier interacción
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });

    nombreUsuario = widget.nombre;
    correoUsuario = widget.correo;
    idUsuario = widget.id;

    userDataNotifier.value = {
      'nombre': widget.nombre,
      'correo': widget.correo,
      'idTipoUsuario': widget.idTipoUsuario.toString(),
    };

    _initializeMenuItems(); // Inicializar los elementos del menú aquí

    _obtenerDocumentos();
    _cargarDatosUsuario();

    _pageController.addListener(() {
      if (mounted) {
        setState(() {
          _currentPage = _pageController.page!.round();
        });
      }
    });

    themeNotifier?.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    themeNotifier?.removeListener(() {});
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_currentPage);
      }

      setState(() {});
    }
  }

  void _obtenerDocumentos() async {
    final String url =
        '${Config.baseUrl}/fetch_pdfs_dashboard.php?idUsuario=$idUsuario';

    try {
      final response = await http.get(Uri.parse(url));

      print('Estado de respuesta: ${response.statusCode}');
      print('Cuerpo de respuesta: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        for (int i = 0; i < data['other_data'].length; i++) {
          var doc = data['other_data'][i];
          final String? urlDocumento = doc['URLDocumento'] as String?;
          final String? tipoDocumento = doc['TipoDocumento'] as String?;

          if (urlDocumento != null && tipoDocumento != null) {
            print(
              'Archivo: ${urlDocumento.split('/').last}, TipoDocumento: $tipoDocumento',
            );
          }
        }

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

            final int idUsuarioInt = int.parse(idUsuario);

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
      } else {
        print('Error al obtener documentos: ${response.statusCode}');
        _showErrorSnackbar(
          'Error al obtener documentos: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Excepción al obtener documentos: $e');
      _showErrorSnackbar('Error al obtener documentos: $e');
    }
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

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _cargarDatosUsuario() async {
    setState(() {
      nombreUsuario = widget.nombre;
      correoUsuario = widget.correo;
    });
    userDataNotifier.value = {'nombre': nombreUsuario, 'correo': correoUsuario};
  }

  void _initializeMenuItems() {
    _commonMenuItems = [
      {
        'title': 'Documentación',
        'icon': Icons.description,
        'backgroundColor': const Color(0xFFA42429),
        'onPressed': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => DocumentacionPage(
                    documentosPorAnio: documentosPorAnio,
                    descriptionsAndDatesPorAnio: descriptionsAndDatesPorAnio,
                    seleccionadosPorAnio: seleccionadosPorAnio,
                    idUsuario: idUsuario,
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
        },
      },
      {
        'title': 'Tablón de Anuncios',
        'icon': Icons.announcement,
        'backgroundColor': const Color(0xFF181C32),
        'onPressed': () {
          Navigator.push(
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
        },
      },
      {
        'title': 'Subir Facturas',
        'icon': Icons.upload_file,
        'backgroundColor': const Color(0xFFA42429),
        'onPressed': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => UploadPdfPage(
                    idUsuario: idUsuario,
                    dni: widget.dni,
                    nombre: widget.nombre,
                    correo: widget.correo,
                    licencia: widget.licencia,
                    contrasena: widget.contrasena,
                    idTipoUsuario: widget.idTipoUsuario,
                  ),
            ),
          );
        },
      },
      {
        'title': 'Generar Factura',
        'icon': Icons.receipt,
        'backgroundColor': const Color(0xFF181C32),
        'onPressed': () {
          Navigator.push(
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
                    token: widget.token,
                  ),
            ),
          );
        },
      },
      {
        'title': 'Calendario',
        'icon': Icons.calendar_today,
        'backgroundColor': const Color(0xFFA42429),
        'onPressed': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => CalendarioPage(
                    userId: idUsuario,
                    nombreUsuario: widget.nombre,
                    correoUsuario: widget.correo,
                    dni: widget.dni,
                    licencia: widget.licencia,
                    contrasena: widget.contrasena,
                    idTipoUsuario: widget.idTipoUsuario,
                  ),
            ),
          );
        },
      },
    ];

    _adminMenuItems = [
      {
        'title': 'Administrar Tablón',
        'icon': Icons.admin_panel_settings,
        'backgroundColor': const Color(0xFF181C32),
        'onPressed': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => AdminTablonPage(
                    adminId: widget.id,
                    adminName: widget.nombre,
                    idTipoUsuario: widget.idTipoUsuario,
                    dni: widget.dni,
                    correo: widget.correo,
                    licencia: widget.licencia,
                    contrasena: widget.contrasena,
                  ),
            ),
          );
        },
      },
      {
        'title': 'Administrar Facturas',
        'icon': Icons.admin_panel_settings,
        'backgroundColor': const Color(0xFFA42429),
        'onPressed': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => AdminFacturasPage(
                    adminId: widget.id,
                    adminName: widget.nombre,
                    idTipoUsuario: widget.idTipoUsuario,
                    dni: widget.dni,
                    correo: widget.correo,
                    licencia: widget.licencia,
                    contrasena: widget.contrasena,
                  ),
            ),
          );
        },
      },
      {
        'title': 'Administrar Usuarios',
        'icon': Icons.people,
        'backgroundColor': const Color(0xFF181C32),
        'onPressed': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => AdminUsuariosPage(
                    adminId: widget.id,
                    adminName: widget.nombre,
                    idTipoUsuario: widget.idTipoUsuario,
                    dni: widget.dni,
                    correo: widget.correo,
                    contrasena: widget.contrasena,
                  ),
            ),
          );
        },
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    print("Construyendo la interfaz de usuario");
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = themeNotifier.isDarkMode;

    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            nombreUsuario: userDataNotifier.value['nombre'] ?? '',
            correoUsuario: userDataNotifier.value['correo'] ?? '',
            currentRoute: 'dashboard',
            onNavigate: (route) {
              if (route == 'dashboard') return;
              if (route == 'documentacion') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => DocumentacionPage(
                          documentosPorAnio: documentosPorAnio,
                          descriptionsAndDatesPorAnio:
                              descriptionsAndDatesPorAnio,
                          seleccionadosPorAnio: seleccionadosPorAnio,
                          idUsuario: idUsuario,
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
                Navigator.push(
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => UploadPdfPage(
                          idUsuario: idUsuario,
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
                Navigator.push(
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
                          token: widget.token,
                        ),
                  ),
                );
              } else if (route == 'calendario') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => CalendarioPage(
                          userId: idUsuario,
                          nombreUsuario: widget.nombre,
                          correoUsuario: widget.correo,
                          dni: widget.dni,
                          licencia: widget.licencia,
                          contrasena: widget.contrasena,
                          idTipoUsuario: widget.idTipoUsuario,
                        ),
                  ),
                );
              } else if (route == 'pedidos_almacen') {
                _abrirWhatsApp();
              } else if (route == 'configuracion') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => SettingsPage(
                          id: idUsuario,
                          nombre: widget.nombre,
                          correo: widget.correo,
                          dni: widget.dni,
                          contrasena: widget.contrasena,
                          licencia: widget.licencia,
                          idTipoUsuario: widget.idTipoUsuario,
                        ),
                  ),
                );
              } else if (route == 'admin_usuarios' && _isAdmin()) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => AdminUsuariosPage(
                          adminId: widget.id,
                          adminName: widget.nombre,
                          idTipoUsuario: widget.idTipoUsuario,
                          dni: widget.dni,
                          correo: widget.correo,
                          contrasena: widget.contrasena,
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
              color: isDark ? const Color(0xFF23272F) : const Color(0xFFFFFFFF),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  padding: EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal:
                        MediaQuery.of(context).size.width < 600 ? 8 : 12,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Panel de control (Grid de botones comunes)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            int crossAxisCount;
                            double childAspectRatio;
                            double spacing;

                            if (constraints.maxWidth > 900) {
                              crossAxisCount = 3;
                              childAspectRatio = 1.5;
                              spacing = 32;
                            } else if (constraints.maxWidth > 600) {
                              crossAxisCount = 2;
                              childAspectRatio = 1.3;
                              spacing = 24;
                            } else {
                              crossAxisCount = 1;
                              childAspectRatio = 1.2;
                              spacing = 16;
                            }

                            if (_isAdmin()) {
                              childAspectRatio *=
                                  2; // Hace las tarjetas la mitad de altas
                            }

                            return GridView.builder(
                              padding: EdgeInsets.all(spacing / 2),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: spacing,
                                    mainAxisSpacing: spacing,
                                    childAspectRatio: childAspectRatio,
                                  ),
                              itemCount: _commonMenuItems.length,
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                final item = _commonMenuItems[index];
                                return _buildMenuButton(
                                  context,
                                  item['title'] as String,
                                  item['icon'] as IconData,
                                  item['onPressed'] as VoidCallback,
                                  backgroundColor:
                                      item['backgroundColor'] as Color,
                                );
                              },
                            );
                          },
                        ),
                        if (_isAdmin()) ...[
                          SizedBox(height: 32), // Espacio entre secciones
                          Text(
                            'Administración',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          SizedBox(height: 16), // Espacio después del título
                          LayoutBuilder(
                            builder: (context, constraints) {
                              int crossAxisCount;
                              double childAspectRatio;
                              double spacing;

                              if (constraints.maxWidth > 900) {
                                crossAxisCount = 3;
                                childAspectRatio = 1.5;
                                spacing = 32;
                              } else if (constraints.maxWidth > 600) {
                                crossAxisCount = 2;
                                childAspectRatio = 1.3;
                                spacing = 24;
                              } else {
                                crossAxisCount = 1;
                                childAspectRatio = 1.2;
                                spacing = 16;
                              }

                              if (_isAdmin()) {
                                childAspectRatio *=
                                    2; // Hace las tarjetas la mitad de altas
                              }

                              return GridView.builder(
                                padding: EdgeInsets.all(spacing / 2),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      crossAxisSpacing: spacing,
                                      mainAxisSpacing: spacing,
                                      childAspectRatio: childAspectRatio,
                                    ),
                                itemCount: _adminMenuItems.length,
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  final item = _adminMenuItems[index];
                                  return _buildMenuButton(
                                    context,
                                    item['title'] as String,
                                    item['icon'] as IconData,
                                    item['onPressed'] as VoidCallback,
                                    backgroundColor:
                                        item['backgroundColor'] as Color,
                                  );
                                },
                              );
                            },
                          ),
                        ],
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

  void _abrirWhatsApp() async {
    const telefono = '34976458287';
    final urlWhatsApp = 'whatsapp://send?phone=$telefono';
    final urlWeb =
        'https://api.whatsapp.com/send/?phone=$telefono&type=phone_number&app_absent=0';

    try {
      bool launched = await launchUrl(
        Uri.parse(urlWhatsApp),
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(
          Uri.parse(urlWeb),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      await launchUrl(Uri.parse(urlWeb), mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildMenuButton(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onPressed, {
    Color backgroundColor = const Color(0xFFA42429),
  }) {
    final isDark = Provider.of<ThemeNotifier>(context).isDarkMode;
    final isMobile = MediaQuery.of(context).size.width < 600;

    double iconSize = isMobile ? 28 : 36;
    double fontSize = isMobile ? 13 : 15;
    double verticalPadding = isMobile ? 12 : 16;

    // Ajusta el tamaño de los iconos y el texto si es una vista de administrador y las tarjetas son más pequeñas
    if (_isAdmin()) {
      iconSize = isMobile ? 20 : 28;
      fontSize = isMobile ? 10 : 12;
      verticalPadding = isMobile ? 6 : 8;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black12,
            width: 1.5,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: verticalPadding,
              horizontal: isMobile ? 2 : 4,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: iconSize, color: Colors.white),
                SizedBox(height: isMobile ? 6 : 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: fontSize,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isAdmin() {
    return widget.idTipoUsuario == 1 || widget.idTipoUsuario == 2;
  }
}
