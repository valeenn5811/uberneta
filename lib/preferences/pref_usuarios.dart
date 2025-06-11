import 'package:shared_preferences/shared_preferences.dart';

class PrefUsuarios {
  static final PrefUsuarios _instancia = new PrefUsuarios._internal();

  factory PrefUsuarios() {
    return _instancia;
  }

  late SharedPreferences _prefs;

  PrefUsuarios._internal();

  initPrefs() async {
    this._prefs = await SharedPreferences.getInstance();
  }

  String get token {
    return _prefs.getString('token') ?? '';
  }

  set token(String value) {
    _prefs.setString('token', value);
  }
}