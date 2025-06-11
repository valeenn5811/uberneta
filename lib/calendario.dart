import 'theme_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';
import 'sidebar.dart';
import 'dashboard.dart';
import 'documentacion_page.dart';
import 'tablon.dart';
import 'upload_pdf_page.dart';
import 'factura_servicio_uberneta_page.dart';
import 'settings_page.dart';
import 'login.dart';

class CalendarioPage extends StatefulWidget {
  final String userId;
  final String nombreUsuario;
  final String correoUsuario;
  final String dni;
  final String licencia;
  final String contrasena;
  final int idTipoUsuario;

  const CalendarioPage({
    Key? key,
    required this.userId,
    required this.nombreUsuario,
    required this.correoUsuario,
    required this.dni,
    required this.licencia,
    required this.contrasena,
    required this.idTipoUsuario,
  }) : super(key: key);

  @override
  _CalendarioPageState createState() => _CalendarioPageState();
}

class _CalendarioPageState extends State<CalendarioPage> {
  List<Meeting> meetings = [];

  @override
  void initState() {
    super.initState();
    _fetchHolidays();
  }

  Future<void> _fetchHolidays() async {
    try {
      final url = Uri.parse(
        '${Config.baseUrl}calendario.php?IdUsuario=${widget.userId}',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          meetings.clear();
          meetings =
              data.map((item) {
                DateTime start = DateTime.parse(item['start']);
                DateTime end = DateTime(
                  start.year,
                  start.month,
                  start.day,
                  23,
                  59,
                  59,
                );
                return Meeting(
                  MediaQuery.of(context).orientation == Orientation.landscape
                      ? ''
                      : 'Festivo',
                  start,
                  end,
                  const Color(0xFFA42429),
                  true,
                  isHoliday: true,
                );
              }).toList();
        });
      } else {
        throw Exception('Error al cargar los festivos');
      }
    } catch (e) {
      print('Error al obtener los festivos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            nombreUsuario: widget.nombreUsuario,
            correoUsuario: widget.correoUsuario,
            currentRoute: 'calendario',
            onNavigate: (route) {
              if (route == 'dashboard') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => MyHomePage(
                          title: 'Panel de control',
                          dni: widget.dni,
                          nombre: widget.nombreUsuario,
                          correo: widget.correoUsuario,
                          id: widget.userId,
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
                          idUsuario: widget.userId,
                          onDocumentosContabilizadosChanged: () {},
                          dni: widget.dni,
                          licencia: widget.licencia,
                          contrasena: widget.contrasena,
                          nombre: widget.nombreUsuario,
                          correo: widget.correoUsuario,
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
                          id: widget.userId,
                          licencia: widget.licencia,
                          contrasena: widget.contrasena,
                          nombre: widget.nombreUsuario,
                          correo: widget.correoUsuario,
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
                          idUsuario: widget.userId,
                          dni: widget.dni,
                          nombre: widget.nombreUsuario,
                          correo: widget.correoUsuario,
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
                          id: widget.userId,
                          dni: widget.dni,
                          nombre: widget.nombreUsuario,
                          correo: widget.correoUsuario,
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
                          userId: widget.userId,
                          nombreUsuario: widget.nombreUsuario,
                          correoUsuario: widget.correoUsuario,
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
                          id: widget.userId,
                          nombre: widget.nombreUsuario,
                          correo: widget.correoUsuario,
                          dni: widget.dni,
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
            idUsuario: widget.userId,
            licencia: widget.licencia,
            contrasena: widget.contrasena,
            idTipoUsuario: widget.idTipoUsuario,
          ),
          Expanded(
            child: Container(
              color: const Color(0xFFFFFFFF),
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
                          Icons.calendar_month,
                          color: Color(0xFFA42429),
                          size: 32,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Calendario',
                          style: TextStyle(
                            color:
                                themeNotifier.isDarkMode
                                    ? Colors.white
                                    : Color(0xFF181C32),
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isLandscape) _buildLegend(),
                  Expanded(
                    child: SfCalendar(
                      view: CalendarView.month,
                      dataSource: MeetingDataSource(meetings),
                      backgroundColor: Colors.white,
                      monthCellBuilder: (
                        BuildContext context,
                        MonthCellDetails details,
                      ) {
                        final isHoliday = meetings.any(
                          (meeting) =>
                              meeting.isHoliday &&
                              details.date.year == meeting.from.year &&
                              details.date.month == meeting.from.month &&
                              details.date.day == meeting.from.day,
                        );
                        return Container(
                          decoration: BoxDecoration(
                            color: isHoliday ? Color(0xFFFFE5E5) : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${details.date.day}',
                                  style: TextStyle(
                                    color:
                                        isHoliday
                                            ? Color(0xFFA42429)
                                            : Colors.black,
                                    fontWeight:
                                        isHoliday
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                    fontSize: 16,
                                  ),
                                ),
                                if (isHoliday)
                                  Icon(
                                    Icons.celebration,
                                    color: Color(0xFFA42429),
                                    size: 18,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                      monthViewSettings: MonthViewSettings(
                        appointmentDisplayMode:
                            MonthAppointmentDisplayMode.none,
                      ),
                      headerStyle: CalendarHeaderStyle(
                        backgroundColor: Colors.white,
                      ),
                      timeSlotViewSettings: const TimeSlotViewSettings(
                        timeIntervalHeight: 19,
                      ),
                      firstDayOfWeek: 1,
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

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      color: Colors.white,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFFA42429),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Festivo',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}

class Meeting {
  String eventName;
  DateTime from;
  DateTime to;
  Color background;
  bool isAllDay;
  bool isHoliday;

  Meeting(
    this.eventName,
    this.from,
    this.to,
    this.background,
    this.isAllDay, {
    this.isHoliday = false,
  });
}

class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<Meeting> source) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) => appointments![index].from;
  @override
  DateTime getEndTime(int index) => appointments![index].to;
  @override
  bool isAllDay(int index) => appointments![index].isAllDay;
  @override
  String getSubject(int index) => appointments![index].eventName;
  @override
  Color getColor(int index) => appointments![index].background;
}
