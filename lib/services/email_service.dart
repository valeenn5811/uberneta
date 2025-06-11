import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class EmailService {
  static Future<bool> enviarCorreoBienvenida({
    required String correo,
    required String nombre,
    required String codUsuario,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}enviar_correo_bienvenida.php'),
        body: {'correo': correo, 'nombre': nombre, 'codUsuario': codUsuario},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error al enviar correo de bienvenida: $e');
      return false;
    }
  }
}
