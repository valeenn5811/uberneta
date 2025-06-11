import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import 'package:universal_html/html.dart' as html;
import 'sidebar.dart';
import 'dashboard.dart';
import 'documentacion_page.dart';
import 'tablon.dart';
import 'upload_pdf_page.dart';
import 'factura_servicio_uberneta_page.dart';
import 'calendario.dart';
import 'settings_page.dart';
import 'login.dart';

class Factura {
  final int id;
  final double precio;
  final String concepto;
  final String fecha;
  final String nombre;
  final String enlace;
  final String observaciones;
  final String nombreCliente;
  final String dniCliente;
  final String direccionCliente;
  final String provinciaCliente;
  final String codigoPostalCliente;
  final String nombreTaxista;
  final String dniTaxista;
  final String direccionTaxista;
  final String provinciaTaxista;
  final String codigoPostalTaxista;
  final int numeroLicencia;
  final int iva;

  Factura({
    required this.id,
    required this.precio,
    required this.concepto,
    required this.fecha,
    required this.nombre,
    required this.enlace,
    required this.observaciones,
    required this.nombreCliente,
    required this.dniCliente,
    required this.direccionCliente,
    required this.provinciaCliente,
    required this.codigoPostalCliente,
    required this.nombreTaxista,
    required this.dniTaxista,
    required this.direccionTaxista,
    required this.provinciaTaxista,
    required this.codigoPostalTaxista,
    required this.numeroLicencia,
    required this.iva,
  });

  factory Factura.fromJson(Map<String, dynamic> json) {
    return Factura(
      id: json['IdFactura'],
      precio: (json['Precio'] as num).toDouble(),
      concepto: json['Concepto'] ?? '',
      fecha: json['FechaFactura'] ?? '',
      nombre: json['RazonSocial'] ?? '',
      enlace: json['Enlace'] ?? '',
      observaciones: json['ObservacionesFactura'] ?? '',
      nombreCliente: json['NombreCliente'] ?? '',
      dniCliente: json['DNICliente'] ?? '',
      direccionCliente: json['DireccionCliente'] ?? '',
      provinciaCliente: json['ProvinciaCliente'] ?? '',
      codigoPostalCliente: json['CodigoPostalCliente'] ?? '',
      nombreTaxista: json['NombreConductor'] ?? '',
      dniTaxista: json['DNIConductor'] ?? '',
      direccionTaxista: json['DireccionConductor'] ?? '',
      provinciaTaxista: json['ProvinciaConductor'] ?? '',
      codigoPostalTaxista: json['CodigoPostalConductor'] ?? '',
      numeroLicencia: json['CodUsuarioConductor'] ?? 0,
      iva: json['IVA'],
    );
  }
}

class ListadoFacturasPage extends StatefulWidget {
  final String id;
  final String dni;
  final String nombre;
  final String correo;
  final String contrasena;
  final String licencia;
  final int idTipoUsuario;

  const ListadoFacturasPage({
    Key? key,
    required this.id,
    required this.dni,
    required this.nombre,
    required this.correo,
    required this.contrasena,
    required this.licencia,
    required this.idTipoUsuario,
  }) : super(key: key);

  @override
  _ListadoFacturasPageState createState() => _ListadoFacturasPageState();
}

class _ListadoFacturasPageState extends State<ListadoFacturasPage> {
  String _searchTerm = '';
  String _selectedTrimester = 'Selecciona Trimestre';
  String _selectedYear = 'Selecciona Año';
  List<String> _availableYears = [];

  @override
  void initState() {
    super.initState();
    _fetchAvailableYears();
  }

  Future<void> _fetchAvailableYears() async {
    try {
      final facturas = await _fetchFacturas();
      final years =
          facturas
              .map(
                (factura) => DateFormat(
                  'yyyy',
                ).format(DateFormat('yyyy-MM-dd').parse(factura.fecha)),
              )
              .toSet()
              .toList();
      setState(() {
        _availableYears = years;
      });
    } catch (e) {
      // Manejar errores si es necesario
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            nombreUsuario: widget.nombre,
            correoUsuario: widget.correo,
            currentRoute: 'listado_facturas',
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
              } else if (route == 'tablon') {
                Navigator.pushReplacement(
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
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => UploadPdfPage(
                          idUsuario: widget.id,
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
                          id: widget.id,
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
              } else if (route == 'configuracion') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => SettingsPage(
                          id: widget.id,
                          dni: widget.dni,
                          nombre: widget.nombre,
                          correo: widget.correo,
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
            idUsuario: widget.id,
            licencia: widget.licencia,
            contrasena: widget.contrasena,
            idTipoUsuario: widget.idTipoUsuario,
          ),
          Expanded(
            child: Container(
              color: Colors.white,
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
                          'Listado de Facturas',
                          style: TextStyle(
                            color: Color(0xFF181C32),
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'Buscar por Razón Social',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchTerm = value;
                              });
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: DropdownButtonFormField<String>(
                            value: _selectedTrimester,
                            decoration: InputDecoration(
                              labelText: 'Seleccionar Trimestre',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items:
                                [
                                  'Selecciona Trimestre',
                                  'Todos',
                                  'Trimestre 1',
                                  'Trimestre 2',
                                  'Trimestre 3',
                                  'Trimestre 4',
                                ].map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                _selectedTrimester = newValue!;
                              });
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: DropdownButtonFormField<String>(
                            value: _selectedYear,
                            decoration: InputDecoration(
                              labelText: 'Seleccionar Año',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items:
                                ['Selecciona Año', ..._availableYears].map((
                                  String value,
                                ) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                _selectedYear = newValue!;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: FutureBuilder<List<Factura>>(
                            future: _fetchFacturas(),
                            builder: (context, snapshot) {
                              return Container(
                                color: Colors.white,
                                child: Builder(
                                  builder: (context) {
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
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              size: 48,
                                              color: Color(0xFFA42429),
                                            ),
                                            SizedBox(height: 16),
                                            Text(
                                              'No hay facturas disponibles',
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
                                      final sortedFacturas =
                                          snapshot.data!..sort(
                                            (a, b) =>
                                                b.fecha.compareTo(a.fecha),
                                          );
                                      final filteredFacturas =
                                          sortedFacturas.where((factura) {
                                            final matchesSearch = factura.nombre
                                                .toLowerCase()
                                                .contains(
                                                  _searchTerm.toLowerCase(),
                                                );
                                            final matchesTrimester =
                                                _matchesTrimester(
                                                  factura.fecha,
                                                );
                                            final matchesYear =
                                                _selectedYear ==
                                                    'Selecciona Año' ||
                                                DateFormat('yyyy').format(
                                                      DateFormat(
                                                        'yyyy-MM-dd',
                                                      ).parse(factura.fecha),
                                                    ) ==
                                                    _selectedYear;
                                            return matchesSearch &&
                                                matchesTrimester &&
                                                matchesYear;
                                          }).toList();

                                      if (filteredFacturas.isEmpty) {
                                        return Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.info_outline,
                                                size: 48,
                                                color: Color(0xFFA42429),
                                              ),
                                              SizedBox(height: 16),
                                              Text(
                                                'No hay facturas disponibles',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  color: Color(0xFF181C32),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }

                                      return ListView.builder(
                                        itemCount: filteredFacturas.length,
                                        itemBuilder: (context, index) {
                                          final factura =
                                              filteredFacturas[index];
                                          return FacturaTile(
                                            factura: factura,
                                            dni: widget.dni,
                                            nombre: widget.nombre,
                                            correo: widget.correo,
                                            idUsuario: widget.id,
                                            licencia: widget.licencia,
                                            contrasena: widget.contrasena,
                                          );
                                        },
                                      );
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
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

  bool _matchesTrimester(String fecha) {
    if (_selectedTrimester == 'Todos' ||
        _selectedTrimester == 'Selecciona Trimestre')
      return true;

    final date = DateFormat('yyyy-MM-dd').parse(fecha);
    final month = date.month;

    switch (_selectedTrimester) {
      case 'Trimestre 1':
        return month >= 1 && month <= 3;
      case 'Trimestre 2':
        return month >= 4 && month <= 6;
      case 'Trimestre 3':
        return month >= 7 && month <= 9;
      case 'Trimestre 4':
        return month >= 10 && month <= 12;
      default:
        return false;
    }
  }

  Future<List<Factura>> _fetchFacturas() async {
    final String url =
        '${Config.baseUrl}listar_factura_cliente.php?idUsuarioConductor=${widget.id}';
    print('URL: $url');
    try {
      final response = await http.get(Uri.parse(url));
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((factura) => Factura.fromJson(factura)).toList();
      } else {
        throw Exception('Error al cargar las facturas');
      }
    } catch (e) {
      throw Exception('Error al conectar con el servidor: $e');
    }
  }
}

class FacturaTile extends StatefulWidget {
  final Factura factura;
  final String dni;
  final String nombre;
  final String correo;
  final String idUsuario;
  final String licencia;
  final String contrasena;

  const FacturaTile({
    Key? key,
    required this.factura,
    required this.dni,
    required this.nombre,
    required this.correo,
    required this.idUsuario,
    required this.licencia,
    required this.contrasena,
  }) : super(key: key);

  @override
  _FacturaTileState createState() => _FacturaTileState();
}

class _FacturaTileState extends State<FacturaTile> {
  bool _showObservaciones = false;

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormat = NumberFormat("#,##0.00 €", "es_ES");

    // Determinar si es abono basado en el concepto
    final bool esAbono = widget.factura.concepto.toLowerCase() == 'Abono';
    final double precioMostrar =
        esAbono
            ? -widget.factura.precio.toDouble()
            : widget.factura.precio.toDouble();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
        title: Row(
          children: [
            const Icon(
              Icons.picture_as_pdf,
              color: Color(0xFFA42429),
              size: 16,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  '${widget.factura.enlace}.pdf',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fecha: ${widget.factura.fecha}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              'Precio: ${currencyFormat.format(precioMostrar)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            if (_showObservaciones)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Observaciones: ${widget.factura.observaciones}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.factura.observaciones.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.info, size: 20),
                onPressed: () {
                  setState(() {
                    _showObservaciones = !_showObservaciones;
                  });
                },
              ),
            IconButton(
              icon: const Icon(Icons.download, size: 20),
              onPressed: () {
                _generatePdf(widget.factura);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generatePdf(Factura factura) async {
    final pdf = pw.Document();
    print('Generando PDF');
    // Cargar la fuente Times New Roman
    final ttf = pw.Font.ttf(await rootBundle.load('fonts/timesnewroman.ttf'));
    final fallbackFont = pw.Font.ttf(
      await rootBundle.load('fonts/OpenSansRegular.ttf'),
    );
    final ttfBold = pw.Font.ttf(
      await rootBundle.load('fonts/OpenSansBold.ttf'),
    );
    print('Fuente cargada correctamente');

    final imageBytes = await rootBundle.load('img/logo-uberneta-limpia.png');
    final image = pw.MemoryImage(imageBytes.buffer.asUint8List());

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Table(
                children: [
                  pw.TableRow(
                    children: [
                      pw.Image(image, width: 160),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.RichText(
                            text: pw.TextSpan(
                              style: pw.TextStyle(font: ttfBold),
                              children: [
                                pw.TextSpan(text: 'Número de factura: '),
                                pw.TextSpan(
                                  text: '${factura.enlace}',
                                  style: pw.TextStyle(font: ttf),
                                ),
                              ],
                            ),
                          ),
                          pw.RichText(
                            text: pw.TextSpan(
                              style: pw.TextStyle(font: ttfBold),
                              children: [
                                pw.TextSpan(text: 'Fecha: '),
                                pw.TextSpan(
                                  text: '${factura.fecha}',
                                  style: pw.TextStyle(font: ttf),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                children: [
                  pw.TableRow(
                    children: [
                      pw.Text(
                        'TAXISTA',
                        style: pw.TextStyle(
                          font: ttfBold,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'CLIENTE',
                        style: pw.TextStyle(
                          font: ttfBold,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.RichText(
                        text: pw.TextSpan(
                          style: pw.TextStyle(font: fallbackFont),
                          children: [
                            pw.TextSpan(
                              text: 'Nombre: ',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.TextSpan(text: '${factura.nombreTaxista}'),
                          ],
                        ),
                      ),
                      pw.RichText(
                        text: pw.TextSpan(
                          style: pw.TextStyle(font: fallbackFont),
                          children: [
                            pw.TextSpan(
                              text: 'Nombre: ',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.TextSpan(text: '${factura.nombre}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.RichText(
                        text: pw.TextSpan(
                          style: pw.TextStyle(font: fallbackFont),
                          children: [
                            pw.TextSpan(
                              text: 'DNI: ',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.TextSpan(text: '${factura.dniTaxista}'),
                          ],
                        ),
                      ),
                      pw.RichText(
                        text: pw.TextSpan(
                          style: pw.TextStyle(font: fallbackFont),
                          children: [
                            pw.TextSpan(
                              text: 'DNI: ',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.TextSpan(text: '${factura.dniCliente}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.RichText(
                        text: pw.TextSpan(
                          style: pw.TextStyle(font: fallbackFont),
                          children: [
                            pw.TextSpan(
                              text: 'Dirección: ',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.TextSpan(text: '${factura.direccionTaxista}'),
                          ],
                        ),
                      ),
                      pw.RichText(
                        text: pw.TextSpan(
                          style: pw.TextStyle(font: fallbackFont),
                          children: [
                            pw.TextSpan(
                              text: 'Dirección: ',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.TextSpan(text: '${factura.direccionCliente}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.RichText(
                        text: pw.TextSpan(
                          style: pw.TextStyle(font: fallbackFont),
                          children: [
                            pw.TextSpan(
                              text: 'Provincia: ',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.TextSpan(text: '${factura.provinciaTaxista}'),
                          ],
                        ),
                      ),
                      pw.RichText(
                        text: pw.TextSpan(
                          style: pw.TextStyle(font: fallbackFont),
                          children: [
                            pw.TextSpan(
                              text: 'Provincia: ',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.TextSpan(text: '${factura.provinciaCliente}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.RichText(
                        text: pw.TextSpan(
                          style: pw.TextStyle(font: fallbackFont),
                          children: [
                            pw.TextSpan(
                              text: 'Código Postal: ',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.TextSpan(text: '${factura.codigoPostalTaxista}'),
                          ],
                        ),
                      ),
                      pw.RichText(
                        text: pw.TextSpan(
                          style: pw.TextStyle(font: fallbackFont),
                          children: [
                            pw.TextSpan(
                              text: 'Código Postal: ',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.TextSpan(text: '${factura.codigoPostalCliente}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#a42429'),
                    ),
                    children: [
                      pw.Text(
                        'Concepto',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          font: ttfBold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        'Base Imponible (€)',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          font: ttfBold,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Text(
                        factura.concepto,
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(font: ttf),
                      ),
                      pw.Text(
                        '${(factura.precio / (1 + factura.iva / 100)).toStringAsFixed(2)} €',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(font: fallbackFont),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Text(
                        'Total Imponible:',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          font: ttfBold,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        '${(factura.precio / (1 + factura.iva / 100)).toStringAsFixed(2)} €',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          font: fallbackFont,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Text(
                        'I.V.A. ${factura.iva}%:',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          font: ttfBold,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        '${((factura.precio * factura.iva) / 100).toStringAsFixed(2)} €',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          font: fallbackFont,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Text(
                        'Total:',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          font: ttfBold,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        '${factura.precio.toStringAsFixed(2)} €',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          font: fallbackFont,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (factura.observaciones.isNotEmpty)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(height: 20),
                    pw.Text(
                      'Observaciones:',
                      style: pw.TextStyle(font: ttfBold, fontSize: 12),
                    ),
                    pw.Text(
                      '${factura.observaciones}',
                      style: pw.TextStyle(font: fallbackFont, fontSize: 12),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );

    // Guardar el archivo PDF
    try {
      final bytes = await pdf.save();

      // Para web, descargar directamente
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor =
          html.AnchorElement(href: url)
            ..setAttribute('download', '${factura.enlace}.pdf')
            ..click();
      html.Url.revokeObjectUrl(url);

      // Mostrar un mensaje de éxito
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Descarga Completa'),
            content: Text('PDF descargado exitosamente'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Error al guardar el PDF: $e');
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Error al descargar el PDF: $e'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }
}
