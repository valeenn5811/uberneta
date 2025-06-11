import 'package:flutter/material.dart';

class UserDataNotifier extends ValueNotifier<Map<String, String>> {
  UserDataNotifier(Map<String, String> value) : super(value);
}

// Instancia global del ValueNotifier
final userDataNotifier = UserDataNotifier({
  'nombre': '',
  'correo': '',
});