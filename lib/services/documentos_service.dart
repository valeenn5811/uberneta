import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class DocumentosService {
  static Future<Map<String, dynamic>> loadDocumentos(String idUsuario) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${Config.baseUrl}fetch_pdfs_dashboard.php?idUsuario=$idUsuario',
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        final Map<int, Map<String, List<String>>> documentos = {};
        final Map<int, Map<String, List<String>>> descriptions = {};
        final Map<int, Map<String, List<bool>>> seleccionados = {};

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

            if (!documentos.containsKey(anioDocumento)) {
              documentos[anioDocumento!] = {};
              seleccionados[anioDocumento] = {};
              descriptions[anioDocumento] = {};
            }

            if (!documentos[anioDocumento]!.containsKey(categoria)) {
              documentos[anioDocumento]![categoria] = [];
              seleccionados[anioDocumento]![categoria] = [];
              descriptions[anioDocumento]![categoria] = [];
            }

            documentos[anioDocumento]![categoria]!.add(urlDocumento);
            seleccionados[anioDocumento]![categoria]!.add(false);

            var descFecha = data['descriptions_and_dates'][i];
            final String descripcion =
                descFecha['DescripcionDocumento'] ?? 'Sin descripción';
            final String fecha =
                descFecha['FechaPublicacionDocumento'] ?? 'Fecha no disponible';

            descriptions[anioDocumento]![categoria]!.add(
              'Descripción: $descripcion, Fecha: $fecha',
            );
          }
        }

        return {
          'documentos': documentos,
          'descriptions': descriptions,
          'seleccionados': seleccionados,
        };
      }
      return {
        'documentos': <int, Map<String, List<String>>>{},
        'descriptions': <int, Map<String, List<String>>>{},
        'seleccionados': <int, Map<String, List<bool>>>{},
      };
    } catch (e) {
      print('Error al cargar documentos: $e');
      return {
        'documentos': <int, Map<String, List<String>>>{},
        'descriptions': <int, Map<String, List<String>>>{},
        'seleccionados': <int, Map<String, List<bool>>>{},
      };
    }
  }
}
