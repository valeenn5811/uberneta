import 'dart:convert';
import 'dart:io';
import 'theme_notifier.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'config.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class PdfViewerEstado extends StatefulWidget {
  final String pdfUrl;
  final String pdfNameCompleto;
  final String idUsuario;

  const PdfViewerEstado({
    Key? key,
    required this.pdfUrl,
    required this.pdfNameCompleto,
    required this.idUsuario,
  }) : super(key: key);

  @override
  _PdfViewerEstadoState createState() => _PdfViewerEstadoState();
}

class _PdfViewerEstadoState extends State<PdfViewerEstado> {
  int currentPage = 0;
  int totalPages = 0;
  String? localFilePath;

  // Método para construir la URL completa del PDF
  String _construirUrlPdf() {
    String baseUrl = Config.baseUrlSubirFacturas;
    String pdfNameCompleto = widget.pdfNameCompleto;
    String idUsuario = widget.idUsuario;

    if (baseUrl.endsWith('uploads/facturas/') &&
        pdfNameCompleto.startsWith('uploads/facturas/')) {
      pdfNameCompleto = pdfNameCompleto.replaceFirst('uploads/facturas/', '');
    }

    String fullUrl = '$baseUrl$idUsuario/$pdfNameCompleto';
    print('URL construida: $fullUrl');
    return fullUrl;
  }

  // Método para descargar el PDF y obtener la ruta local
  Future<void> _loadPdf() async {
    final String url = _construirUrlPdf();

    try {
      final respuesta = await http.get(Uri.parse(url));

      if (respuesta.statusCode == 200) {
        Directory tempDir = await getTemporaryDirectory();
        String tempPath = '${tempDir.path}/${widget.pdfNameCompleto}';
        final archivo = File(tempPath);
        await archivo.writeAsBytes(respuesta.bodyBytes);
        setState(() {
          localFilePath = tempPath;
        });
        print('PDF cargado localmente: $tempPath');
      } else {
        print('Error al descargar PDF: ${respuesta.statusCode}');
      }
    } catch (e) {
      print('Error al descargar PDF: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  @override
  Widget build(BuildContext context) {
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
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child:
                    localFilePath != null
                        ? PDFView(
                          filePath: localFilePath,
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
                        )
                        : const Center(child: CircularProgressIndicator()),
              ),
            ),
            // Indicador de página
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Página ${currentPage + 1} de $totalPages',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
