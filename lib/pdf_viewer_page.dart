import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

class PdfViewerPage extends StatelessWidget {
  final String pdfUrl;
  final String pdfName;

  const PdfViewerPage({Key? key, required this.pdfUrl, required this.pdfName})
    : super(key: key);

  // Método para construir la URL completa del PDF
  String _construirUrlPdf() {
    String pdfName = this.pdfName;
    if (pdfName.startsWith('uploads/')) {
      pdfName = pdfName.replaceFirst('uploads/', '');
    }
    String url = 'baseUrl$pdfName'.replaceAll(RegExp(r'(?<!:)//'), '/');
    return url;
  }

  Future<void> _abrirPdfEnWeb(BuildContext context) async {
    final String url = _construirUrlPdf();
    if (kIsWeb) {
      await launchUrl(Uri.parse(url), webOnlyWindowName: '_blank');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PDF',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Color(0xFFA42429),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () => _abrirPdfEnWeb(context),
        child: const Text('Abrir PDF'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFA42429),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
