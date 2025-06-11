import 'dart:convert';
import 'dart:io';
import 'theme_notifier.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'config.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class PDFViewerDocumento extends StatefulWidget {
  final String pdfUrl;
  final String pdfName;
  final String idUsuario; // Añadir este campo

  const PDFViewerDocumento({
    Key? key,
    required this.pdfUrl,
    required this.pdfName,
    required this.idUsuario, // Asegúrate de requerirlo
  }) : super(key: key);

  @override
  _PdfViewerDocumentoState createState() => _PdfViewerDocumentoState();
}

class _PdfViewerDocumentoState extends State<PDFViewerDocumento> {
  int currentPage = 0;
  int totalPages = 0;

  void _showDownloadMessage(String message, {bool success = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: success ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: success ? Colors.black87 : Color(0xFF181C32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Descarga Completa'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Cierra el diálogo
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _downloadPdf() async {
    final String url =
        '${Config.baseUrlDocumentos}/uploads/${widget.idUsuario}/${widget.pdfName}'
            .replaceAll(
              RegExp(r'(?<!:)//'),
              '/',
            ); // Elimina barras dobles no precedidas por ':'

    Directory? directory;

    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }
      directory = Directory('/storage/emulated/0/Download');
    } else if (Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
    }

    if (directory != null) {
      String nombreArchivo = widget.pdfName;

      // Eliminar los números al principio del nombre del archivo
      if (nombreArchivo.contains('_')) {
        List<String> partes = nombreArchivo.split('_');
        nombreArchivo = partes.last;
      }

      // Asegurar que el archivo tenga extensión .pdf
      if (!nombreArchivo.toLowerCase().endsWith('.pdf')) {
        nombreArchivo = '$nombreArchivo.pdf';
      }

      final String rutaArchivo = '${directory.path}/$nombreArchivo';

      try {
        print('Descargando desde la URL: $url');

        final respuesta = await http.get(Uri.parse(url));

        if (respuesta.statusCode == 200) {
          // Verificar el tipo de contenido
          if (respuesta.headers['content-type'] != null &&
              respuesta.headers['content-type']!.contains('application/pdf')) {
            final archivo = File(rutaArchivo);
            await archivo.writeAsBytes(respuesta.bodyBytes);
            _showSuccessDialog('¡PDF descargado exitosamente!');
            print('PDF descargado exitosamente: $rutaArchivo');

            // Leer las primeras líneas del archivo para verificar el contenido
            final contenido = await archivo.readAsBytes();
            if (contenido.isNotEmpty &&
                String.fromCharCodes(contenido.take(4)) == '%PDF') {
              print('El archivo es un PDF válido.');
            } else {
              print('El archivo descargado no es un PDF válido.');
              _showDownloadMessage(
                'El archivo descargado no es un PDF válido.',
                success: false,
              );
            }
          } else {
            print(
              'Error: la respuesta no es un PDF válido. Tipo: ${respuesta.headers['content-type']}',
            );
            _showDownloadMessage(
              'Error: la respuesta no es un PDF válido.',
              success: false,
            );
          }
        } else {
          print('Error al descargar PDF: ${respuesta.statusCode}');
          _showDownloadMessage(
            'Error al descargar PDF: ${respuesta.statusCode}',
            success: false,
          );
        }
      } catch (e) {
        print('Error al descargar PDF: $e');
        _showDownloadMessage('Error al descargar PDF: $e', success: false);
      }
    } else {
      _showDownloadMessage(
        'No se pudo obtener el directorio de descarga.',
        success: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print(
      'Intentando mostrar PDF desde: ${widget.pdfUrl}',
    ); // Mensaje de depuración

    // Verificar si el archivo existe y su tamaño
    final archivo = File(widget.pdfUrl);
    if (archivo.existsSync()) {
      print('El archivo existe. Tamaño: ${archivo.lengthSync()} bytes');
    } else {
      print('El archivo no existe en la ruta especificada.');
    }
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PDF',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor:
            themeNotifier.isDarkMode ? Color(0xFFA42429) : Color(0xFF181C32),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: Theme.of(context).colorScheme.background,
        child: Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color:
                      Theme.of(
                        context,
                      ).colorScheme.surface, // Mismo fondo que en TablonPage
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: PDFView(
                  filePath: widget.pdfUrl,
                  enableSwipe: true,
                  swipeHorizontal: false,
                  autoSpacing: false,
                  pageFling: false,
                  pageSnap: true,
                  defaultPage: 0,
                  onPageChanged: (int? page, int? total) {
                    setState(() {
                      currentPage = page ?? 0;
                      totalPages = total ?? 0;
                    });
                    print('Página $page de $total');
                  },
                  onError: (error) {
                    print('Error al cargar el PDF: $error'); // Mensaje de error
                    _showDownloadMessage(
                      'Error al cargar el PDF: $error',
                      success: false,
                    );
                  },
                  onPageError: (page, error) {
                    print(
                      'Error en la página $page: $error',
                    ); // Mensaje de error por página
                    _showDownloadMessage(
                      'Error en la página $page: $error',
                      success: false,
                    );
                  },
                ),
              ),
            ),
            // Indicador de página
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Página ${currentPage + 1} de $totalPages',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            // Botón de descarga
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: _downloadPdf,
                child: const Text('Descargar PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFA42429),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
