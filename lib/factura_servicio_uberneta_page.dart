import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'config.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'sidebar.dart';
import 'dashboard.dart';
import 'documentacion_page.dart';
import 'tablon.dart';
import 'upload_pdf_page.dart';
import 'calendario.dart';
import 'settings_page.dart';
import 'login.dart';

class FacturaServicioUbernetaPage extends StatefulWidget {
  final String id;
  final String dni;
  final String nombre;
  final String correo;
  final String contrasena;
  final String licencia;
  final String tipoFactura;
  final int idTipoUsuario;
  final String token;

  const FacturaServicioUbernetaPage({
    Key? key,
    required this.id,
    required this.dni,
    required this.nombre,
    required this.correo,
    required this.contrasena,
    required this.licencia,
    required this.tipoFactura,
    required this.idTipoUsuario,
    required this.token,
  }) : super(key: key);

  @override
  State<FacturaServicioUbernetaPage> createState() =>
      _FacturaServicioUbernetaPageState();
}

class _FacturaServicioUbernetaPageState
    extends State<FacturaServicioUbernetaPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _observacionesController =
      TextEditingController();
  final TextEditingController _razonSocialController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  bool _mostrarRazonSocial = false;
  bool _isLoading = false;
  bool _mostrarFormularioAlta = false;
  String _errorDniMessage = '';
  String _errorFormMessage = '';
  String _errorAltaMessage = '';

  Future<void> insertarFactura(
    int idCliente,
    String fechaFactura,
    int idUsuarioConductor,
    String concepto,
    String razonSocial,
    String observacionesFactura,
    double precio,
  ) async {
    final String url = '${Config.baseUrl}insertar_factura_cliente.php';

    // Construir el enlace similar a como se hace en PHP
    final String anioActual = DateTime.now().year.toString();
    final String enlace =
        '$anioActual-${idUsuarioConductor.toString().padLeft(4, '0')}.pdf';

    try {
      final response = await http.post(
        Uri.parse(url),
        body: {
          'idCliente': idCliente.toString(),
          'fechaFactura': fechaFactura,
          'idUsuarioConductor': idUsuarioConductor.toString(),
          'concepto': concepto,
          'razonSocial': razonSocial,
          'observacionesFactura': observacionesFactura,
          'precio': precio.toString(),
          'enlace': enlace,
        },
      );

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          if (responseData['success'] != null) {
            print(responseData['success']);
            _procesarFactura(responseData);
          } else if (responseData['error'] != null) {
            print(responseData['error']);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${responseData['error']}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } catch (e) {
          print('Error al decodificar la respuesta: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error en la respuesta del servidor'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        print('Error al insertar la factura: ${response.statusCode}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error del servidor: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error al conectar con el servidor: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de conexión: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _obtenerRazonSocial(String dni) async {
    if (dni.isEmpty || dni.length < 9) {
      setState(() {
        _mostrarRazonSocial = false;
        _razonSocialController.clear();
        _errorDniMessage = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorDniMessage = '';
    });

    final String url = '${Config.baseUrl}obtener_razon_social.php?dni=$dni';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        setState(() {
          if (data.containsKey('razon_social') &&
              data['razon_social'] != null) {
            _razonSocialController.text = data['razon_social'];
            _mostrarRazonSocial = true;
          } else {
            _mostrarRazonSocial = false;
            _razonSocialController.clear();
            _errorDniMessage = 'Cliente no existe';
          }
        });
      } else {
        _mostrarRazonSocial = false;
        _razonSocialController.clear();
        _errorDniMessage = 'Error al obtener los datos. Inténtelo nuevamente.';
      }
    } catch (e) {
      _mostrarRazonSocial = false;
      _razonSocialController.clear();
      _errorDniMessage = 'Ocurrió un error al conectarse al servidor';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<int?> _obtenerIdCliente(String dni) async {
    final String url = '${Config.baseUrl}obtener_id_cliente.php?dni=$dni';
    try {
      final response = await http.get(Uri.parse(url));
      print('Response body: ${response.body}');

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data.containsKey('id_cliente')) {
          return int.tryParse(data['id_cliente']);
        }
      }
    } catch (e) {
      print('Error al conectar con el servidor para obtener idCliente: $e');
    }
    return null;
  }

  Future<void> _darAltaCliente() async {
    if (_dniController.text.isEmpty ||
        _correoController.text.isEmpty ||
        _nombreController.text.isEmpty) {
      setState(() {
        _errorAltaMessage = 'Por favor, complete todos los campos obligatorios';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorAltaMessage = '';
    });

    final String url = '${Config.baseUrl}dar_alta_cliente.php';
    try {
      final response = await http.post(
        Uri.parse(url),
        body: {
          'dni': _dniController.text,
          'correo': _correoController.text,
          'nombre': _nombreController.text,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _mostrarFormularioAlta = false;
            _errorAltaMessage = '';
          });
          // Actualizar la razón social después de dar de alta
          await _obtenerRazonSocial(_dniController.text);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cliente dado de alta correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() {
            _errorAltaMessage =
                data['message'] ?? 'Error al dar de alta el cliente';
          });
        }
      } else {
        setState(() {
          _errorAltaMessage = 'Error al conectar con el servidor';
        });
      }
    } catch (e) {
      setState(() {
        _errorAltaMessage = 'Error al conectar con el servidor: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _validarFormulario() async {
    setState(() {
      _errorFormMessage = '';
    });

    if (_formKey.currentState!.validate()) {
      // Mostrar diálogo de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA42429)),
                ),
                SizedBox(height: 16),
                Text('Generando y enviando factura...'),
              ],
            ),
          );
        },
      );

      final int? idCliente = await _obtenerIdCliente(_dniController.text);
      if (idCliente != null) {
        await insertarFactura(
          idCliente,
          DateTime.now().toIso8601String(),
          int.parse(widget.id),
          'Servicio Uberneta',
          _razonSocialController.text,
          _observacionesController.text,
          double.parse(_precioController.text),
        );
      } else {
        // Cerrar diálogo de carga
        Navigator.of(context).pop();

        setState(() {
          _errorFormMessage =
              'No se pudo obtener el id del cliente. Verifique el DNI.';
        });
      }
    } else {
      setState(() {
        _errorFormMessage = 'Por favor, complete todos los campos obligatorios';
      });
    }
  }

  Future<void> _generarYEnviarFactura(
    Map<String, dynamic> facturaInfo,
    Map<String, dynamic> conductorInfo,
    Map<String, dynamic> clienteInfo,
  ) async {
    final pdf = pw.Document();

    // Cargar las fuentes con manejo de errores
    pw.Font? ttf;
    pw.Font? fallbackFont;
    pw.Font? ttfBold;

    try {
      ttf = pw.Font.ttf(await rootBundle.load('fonts/timesnewroman.ttf'));
      fallbackFont = pw.Font.ttf(
        await rootBundle.load('fonts/OpenSansRegular.ttf'),
      );
      ttfBold = pw.Font.ttf(await rootBundle.load('fonts/OpenSansBold.ttf'));
      print('Fuentes cargadas correctamente');
    } catch (e) {
      print('Error al cargar las fuentes: $e');
      // Usar fuentes por defecto si hay error
      ttf = pw.Font.helvetica();
      fallbackFont = pw.Font.helvetica();
      ttfBold = pw.Font.helveticaBold();
    }

    final imageBytes = await rootBundle.load('img/logo-uberneta.png');
    final image = pw.MemoryImage(imageBytes.buffer.asUint8List());

    // Generar el contenido del PDF
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
                      pw.Image(
                        image,
                        width: 160,
                      ), // Asegúrate de definir 'image'
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.RichText(
                            text: pw.TextSpan(
                              style: pw.TextStyle(font: ttfBold),
                              children: [
                                pw.TextSpan(text: 'Número de factura: '),
                                pw.TextSpan(
                                  text: '${facturaInfo['NumeroFactura']}',
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
                                  text: '${facturaInfo['FechaFactura']}',
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
                        'CONDUCTOR',
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
                            pw.TextSpan(text: '${conductorInfo['Nombre']}'),
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
                            pw.TextSpan(text: '${clienteInfo['Nombre']}'),
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
                            pw.TextSpan(text: '${conductorInfo['DNIUsuario']}'),
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
                            pw.TextSpan(text: '${clienteInfo['DNIUsuario']}'),
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
                            pw.TextSpan(text: '${conductorInfo['Direccion']}'),
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
                            pw.TextSpan(text: '${clienteInfo['Direccion']}'),
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
                            pw.TextSpan(text: '${conductorInfo['Provincia']}'),
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
                            pw.TextSpan(text: '${clienteInfo['Provincia']}'),
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
                            pw.TextSpan(
                              text: '${conductorInfo['CodigoPostal']}',
                            ),
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
                            pw.TextSpan(text: '${clienteInfo['CodigoPostal']}'),
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
                        'Servicio Uberneta',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(font: ttf),
                      ),
                      pw.Text(
                        '${(facturaInfo['Precio'] / (1 + facturaInfo['IVA'] / 100)).toStringAsFixed(2)} €',
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
                        '${(facturaInfo['Precio'] / (1 + facturaInfo['IVA'] / 100)).toStringAsFixed(2)} €',
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
                        'I.V.A. ${facturaInfo['IVA']}%:',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          font: ttfBold,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        '${((facturaInfo['Precio'] * facturaInfo['IVA']) / 100).toStringAsFixed(2)} €',
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
                        '${facturaInfo['Precio'].toStringAsFixed(2)} €',
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
              if (facturaInfo['ObservacionesFactura'] != null &&
                  facturaInfo['ObservacionesFactura'].isNotEmpty)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(height: 20),
                    pw.Text(
                      'Observaciones:',
                      style: pw.TextStyle(font: ttfBold, fontSize: 12),
                    ),
                    pw.Text(
                      '${facturaInfo['ObservacionesFactura']}',
                      style: pw.TextStyle(font: fallbackFont, fontSize: 12),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );

    // Guardar el PDF en la carpeta de descargas
    final bytes = await pdf.save();

    // Enviar el PDF por correo usando un servicio web con mejor manejo de errores
    final url = Uri.parse('${Config.baseUrl}enviar_correo.php');
    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: {
              'from': 'vlopeztapiagomez@gmail.com',
              'to': jsonEncode([
                conductorInfo['CorreoUsuario'],
                clienteInfo['CorreoUsuario'],
              ]),
              'subject':
                  'Servicio Uberneta - Factura ${facturaInfo['NumeroFactura']}',
              'text':
                  'Adjunto encontraras la factura del servicio de uberneta.',
              'pdf': base64Encode(bytes),
              'filename': facturaInfo['Enlace'],
              'smtp_host': 'smtp.gmail.com',
              'smtp_port': '587',
              'smtp_secure': 'tls',
              'smtp_auth': 'true',
              'smtp_username': 'vlopeztapiagomez@gmail.com',
              'smtp_password': 'ihbh tmef dwyq ykrm',
              'smtp_debug': 'true',
              'verify_peer': 'false',
              'verify_peer_name': 'false',
            },
          )
          .timeout(const Duration(seconds: 30));

      print('Respuesta del servidor: ${response.body}'); // Debug

      // Cerrar el diálogo de carga
      Navigator.of(context).pop();

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          if (responseData['success'] == true) {
            print('Correo enviado exitosamente');
            // Mostrar diálogo de éxito
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Éxito'),
                  content: const Text(
                    'Factura generada y enviada correctamente',
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('OK'),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => MyHomePage(
                                  title: 'Dashboard',
                                  dni: widget.dni,
                                  nombre: widget.nombre,
                                  correo: widget.correo,
                                  id: widget.id,
                                  licencia: widget.licencia,
                                  contrasena: widget.contrasena,
                                  token: widget.token,
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
          } else {
            final errorMessage = responseData['message'] ?? 'Error desconocido';
            print('Error al enviar el correo: $errorMessage');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al enviar el correo: $errorMessage'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (jsonError) {
          print('Error al decodificar JSON: $jsonError');
          print('Contenido de la respuesta: ${response.body}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al procesar la respuesta del servidor'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        print('Error HTTP: ${response.statusCode}');
        print('Respuesta del servidor: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error del servidor: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Cerrar el diálogo de carga en caso de error
      Navigator.of(context).pop();

      print('Error al enviar el correo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar el correo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _procesarFactura(Map<String, dynamic> responseData) {
    final facturaInfo = responseData['factura'];
    final conductorInfo = responseData['conductor'];
    final clienteInfo = responseData['cliente'];

    _generarYEnviarFactura(facturaInfo, conductorInfo, clienteInfo);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Sidebar(
                  nombreUsuario: widget.nombre,
                  correoUsuario: widget.correo,
                  currentRoute: 'generar_factura',
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
                                token: widget.token,
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
                                tipoFactura: 'Servicio Uberneta',
                                idTipoUsuario: widget.idTipoUsuario,
                                token: widget.token,
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
                                    Uri.parse(
                                      '${Config.baseUrl}eliminar_token.php',
                                    ),
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
                              Icon(
                                Icons.local_taxi,
                                color: Color(0xFFA42429),
                                size: 32,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Factura Servicio Uberneta',
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
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Concepto*: Servicio Uberneta',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  if (_mostrarRazonSocial)
                                    TextFormField(
                                      controller: _razonSocialController,
                                      decoration: const InputDecoration(
                                        labelText: 'Razón Social*',
                                        border: OutlineInputBorder(),
                                      ),
                                      readOnly: true,
                                    ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _dniController,
                                    decoration: const InputDecoration(
                                      labelText: 'DNI/NIE/CIF Cliente*',
                                      border: OutlineInputBorder(),
                                    ),
                                    textInputAction: TextInputAction.done,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor, ingrese el DNI/NIE/CIF del cliente';
                                      }
                                      final RegExp dniNifRegExp = RegExp(
                                        r'^[0-9]{8}[a-zA-Z]$|^[XYZxyz][0-9]{7}[a-zA-Z]$|^[ABCDEFGHJNPQRSUVWabcdefghjnpqrsuvw][0-9]{7}[0-9A-Ja-j]$',
                                        caseSensitive: false,
                                      );
                                      if (!dniNifRegExp.hasMatch(value)) {
                                        return 'Por favor, ingrese un DNI/NIE/CIF válido';
                                      }
                                      return null;
                                    },
                                    onChanged: (value) {
                                      _obtenerRazonSocial(value);
                                    },
                                  ),
                                  if (_errorDniMessage.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _errorDniMessage,
                                            style: const TextStyle(
                                              color: Colors.red,
                                            ),
                                          ),
                                          if (_errorDniMessage ==
                                              'Cliente no existe') ...[
                                            const SizedBox(height: 8.0),
                                            ElevatedButton(
                                              onPressed: () {
                                                setState(() {
                                                  _mostrarFormularioAlta = true;
                                                });
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Color(
                                                  0xFFA42429,
                                                ),
                                                foregroundColor: Colors.white,
                                              ),
                                              child: const Text('Dar de Alta'),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  if (_mostrarFormularioAlta) ...[
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _nombreController,
                                      decoration: const InputDecoration(
                                        labelText: 'Nombre Completo*',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Por favor, ingrese el nombre del cliente';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _correoController,
                                      decoration: const InputDecoration(
                                        labelText: 'Correo Electrónico*',
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Por favor, ingrese el correo electrónico';
                                        }
                                        final emailRegExp = RegExp(
                                          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                                        );
                                        if (!emailRegExp.hasMatch(value)) {
                                          return 'Por favor, ingrese un correo electrónico válido';
                                        }
                                        return null;
                                      },
                                    ),
                                    if (_errorAltaMessage.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8.0,
                                        ),
                                        child: Text(
                                          _errorAltaMessage,
                                          style: const TextStyle(
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        ElevatedButton(
                                          onPressed: _darAltaCliente,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Color(0xFFA42429),
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text('Guardar'),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              _mostrarFormularioAlta = false;
                                              _errorAltaMessage = '';
                                              _correoController.clear();
                                              _nombreController.clear();
                                            });
                                          },
                                          child: const Text('Cancelar'),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  if (_isLoading)
                                    const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _precioController,
                                    decoration: const InputDecoration(
                                      labelText: 'Precio (€)*',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType:
                                        TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d+[\.,]?\d{0,2}'),
                                      ),
                                    ],
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor, ingrese el precio';
                                      }
                                      String precioString = value.replaceAll(
                                        ',',
                                        '.',
                                      );
                                      final double? precio = double.tryParse(
                                        precioString,
                                      );
                                      if (precio == null) {
                                        return 'Por favor, ingrese un número válido';
                                      }
                                      return null;
                                    },
                                    onChanged: (value) {
                                      _precioController.text = value.replaceAll(
                                        ',',
                                        '.',
                                      );
                                      _precioController.selection =
                                          TextSelection.fromPosition(
                                            TextPosition(
                                              offset:
                                                  _precioController.text.length,
                                            ),
                                          );
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _observacionesController,
                                    decoration: const InputDecoration(
                                      labelText: 'Observaciones',
                                      border: OutlineInputBorder(),
                                    ),
                                    maxLines: 3,
                                  ),
                                  const SizedBox(height: 16),
                                  if (_errorFormMessage.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        _errorFormMessage,
                                        style: const TextStyle(
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 16),
                                  Center(
                                    child: ElevatedButton(
                                      onPressed: _validarFormulario,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFFA42429),
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text(
                                        'Guardar y Generar Factura',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _dniController.dispose();
    _precioController.dispose();
    _observacionesController.dispose();
    _razonSocialController.dispose();
    _correoController.dispose();
    _nombreController.dispose();
    super.dispose();
  }
}
