import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';
import 'sidebar.dart';
import 'dashboard.dart';
import 'documentacion_page.dart';
import 'calendario.dart';
import 'tablon.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login.dart';

class AdminFacturasPage extends StatefulWidget {
  final String adminId;
  final String adminName;
  final int idTipoUsuario;
  final String dni;
  final String correo;
  final String licencia;
  final String contrasena;

  const AdminFacturasPage({
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
  _AdminFacturasPageState createState() => _AdminFacturasPageState();
}

class _AdminFacturasPageState extends State<AdminFacturasPage> {
  List<Map<String, dynamic>> facturas = [];
  List<Map<String, dynamic>> _filteredFacturas = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  bool _isAdmin() {
    return widget.idTipoUsuario == 1 || widget.idTipoUsuario == 2;
  }

  @override
  void initState() {
    super.initState();
    if (!_isAdmin()) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes permisos para acceder a esta página'),
          backgroundColor: Colors.red,
        ),
      );
    }
    _fetchFacturas();
    _searchController.addListener(_filterFacturas);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterFacturas() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredFacturas =
          facturas.where((factura) {
            // Filtra por IdConductor (convertido a String para la comparación)
            final IdConductor =
                factura['IdConductor']?.toString().toLowerCase() ?? '';
            return IdConductor.contains(query);
          }).toList();
    });
  }

  Future<void> _fetchFacturas() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}fetch_facturas.php'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List) {
          setState(() {
            facturas =
                data.map((item) => Map<String, dynamic>.from(item)).toList();
            _isLoading = false;
            _filterFacturas(); // Llama a filtrar después de cargar las facturas
          });
        } else if (data is Map && data.containsKey('error')) {
          setState(() {
            _errorMessage = data['error'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Respuesta inesperada del servidor';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Error al conectar con el servidor';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _actualizarEstadoFactura(
    String idFactura,
    int nuevoEstado, {
    String? observaciones,
  }) async {
    if (!mounted) return; // Verificar si el widget sigue montado

    try {
      // Verificar si la factura está rechazada
      final facturaActual = facturas.firstWhere(
        (f) => f['IdDocumentoFactura'].toString() == idFactura,
        orElse: () => {'IdEstadoDocumento': 0},
      );

      if (facturaActual['IdEstadoDocumento'] == 4) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se puede modificar el estado de una factura rechazada',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final Map<String, String> body = {
        'idFactura': idFactura,
        'nuevoEstado': nuevoEstado.toString(),
      };

      if (observaciones != null && observaciones.isNotEmpty) {
        body['observaciones'] = observaciones;
      }

      final response = await http.post(
        Uri.parse('${Config.baseUrl}actualizar_estado_factura.php'),
        body: body,
      );

      if (!mounted)
        return; // Verificar si el widget sigue montado después de la llamada HTTP

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Estado actualizado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          await _fetchFacturas(); // Recargar la lista
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Error al actualizar el estado'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
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
      backgroundColor: Colors.white,
      body: Row(
        children: [
          Sidebar(
            nombreUsuario: widget.adminName,
            correoUsuario: widget.correo,
            currentRoute: 'admin_facturas',
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
                          documentosPorAnio: {},
                          descriptionsAndDatesPorAnio: {},
                          seleccionadosPorAnio: {},
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
              color: Colors.white,
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
                                Icons.receipt_long,
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
                                  'Administrar Facturas',
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
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 16,
                            runSpacing: 8,
                            children: [
                              _leyendaIcono(
                                Icons.upload_file,
                                Colors.blue,
                                'Pendiente',
                              ),
                              _leyendaIcono(
                                Icons.visibility,
                                Colors.orange,
                                'Abierto',
                              ),
                              _leyendaIcono(
                                Icons.cancel,
                                Colors.red,
                                'Rechazado',
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              labelText: 'Buscar por ID de Taxista',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child:
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _errorMessage != null
                            ? Center(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            )
                            : ListView.builder(
                              itemCount: _filteredFacturas.length,
                              itemBuilder: (context, index) {
                                final factura = _filteredFacturas[index];
                                return Card(
                                  elevation: 0,
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      'Factura #${factura['IdDocumentoFactura']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Taxista: ${factura['IdConductor']}',
                                        ),
                                        Text(
                                          'Título: ${_getNombreLimpio(factura['TituloDocumento'])}',
                                        ),
                                        Text(
                                          'Fecha: ${factura['FechaPublicacionDocumento']}',
                                        ),
                                        if (factura['ObservacionesFactura'] !=
                                                null &&
                                            factura['ObservacionesFactura']
                                                .toString()
                                                .isNotEmpty)
                                          Text(
                                            'Observaciones: ${factura['ObservacionesFactura']}',
                                          ),
                                        Row(
                                          children: [
                                            _getEstadoIcono(
                                              factura['IdEstadoDocumento'],
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.visibility),
                                          tooltip: 'Ver Factura',
                                          onPressed: () async {
                                            String baseUrl = Config.baseUrl;
                                            if (baseUrl.endsWith('/')) {
                                              baseUrl = baseUrl.substring(
                                                0,
                                                baseUrl.length - 1,
                                              );
                                            }
                                            final url =
                                                '$baseUrl${factura['URLDocumento']}';

                                            if (await canLaunchUrl(
                                              Uri.parse(url),
                                            )) {
                                              await launchUrl(Uri.parse(url));
                                              // Solo actualizar el estado si NO está rechazada
                                              if (factura['IdEstadoDocumento'] !=
                                                  4) {
                                                _actualizarEstadoFactura(
                                                  factura['IdDocumentoFactura']
                                                      .toString(),
                                                  2,
                                                );
                                              }
                                            } else {
                                              if (!mounted) return;
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'No se pudo abrir la factura: $url',
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                        PopupMenuButton<int>(
                                          onSelected: (int estado) {
                                            if (estado == 4) {
                                              _showObservacionesDialog(factura);
                                            } else if (estado == 3) {
                                              if (factura['IdEstadoDocumento'] !=
                                                  4) {
                                                _actualizarEstadoFactura(
                                                  factura['IdDocumentoFactura']
                                                      .toString(),
                                                  estado,
                                                );
                                              }
                                            }
                                          },
                                          itemBuilder:
                                              (BuildContext context) => [
                                                PopupMenuItem(
                                                  value: 3,
                                                  enabled:
                                                      factura['IdEstadoDocumento'] !=
                                                      4,
                                                  child: Text(
                                                    'Contabilizar',
                                                    style: TextStyle(
                                                      color:
                                                          factura['IdEstadoDocumento'] !=
                                                                  4
                                                              ? null
                                                              : Colors.grey,
                                                    ),
                                                  ),
                                                ),
                                                const PopupMenuItem(
                                                  value: 4,
                                                  child: Text('Rechazar'),
                                                ),
                                              ],
                                        ),
                                      ],
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

  String _getNombreLimpio(String? titulo) {
    if (titulo == null) return '';
    // Busca el primer guion bajo y devuelve lo que hay después
    int index = titulo.indexOf('_');
    if (index != -1 && index + 1 < titulo.length) {
      return titulo.substring(index + 1);
    }
    return titulo;
  }

  Widget _getEstadoIcono(dynamic estado) {
    switch (estado.toString()) {
      case '1':
        return const Icon(
          Icons.upload_file,
          color: Colors.blue,
          semanticLabel: 'Subido por el taxista',
        );
      case '2':
        return const Icon(
          Icons.visibility,
          color: Colors.orange,
          semanticLabel: 'AbiertO',
        );
      case '3':
        return const Icon(
          Icons.check_circle,
          color: Colors.green,
          semanticLabel: 'Aceptado/Contabilizado',
        );
      case '4':
        return const Icon(
          Icons.cancel,
          color: Colors.red,
          semanticLabel: 'Rechazado',
        );
      default:
        return const Icon(
          Icons.help_outline,
          color: Colors.grey,
          semanticLabel: 'Desconocido',
        );
    }
  }

  Widget _leyendaIcono(IconData icon, Color color, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 4),
        Text(texto, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  void _showObservacionesDialog(Map<String, dynamic> factura) {
    if (!mounted) return;

    final TextEditingController observacionesController =
        TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Añadir Observaciones de Rechazo'),
          content: TextField(
            controller: observacionesController,
            decoration: const InputDecoration(
              hintText: 'Escribe tus observaciones aquí',
            ),
            maxLines: 3,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
                observacionesController.dispose();
              },
            ),
            TextButton(
              child: const Text('Confirmar'),
              onPressed: () {
                if (!mounted) return;
                _actualizarEstadoFactura(
                  factura['IdDocumentoFactura'].toString(),
                  4,
                  observaciones: observacionesController.text,
                );
                Navigator.of(context).pop();
                observacionesController.dispose();
              },
            ),
          ],
        );
      },
    );
  }
}
