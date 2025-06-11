import 'package:flutter/material.dart';
import 'upload_pdf_page.dart';
import 'factura_servicio_uberneta_page.dart';
import 'calendario.dart';
import 'settings_page.dart';
import 'estado_facturas_page.dart';
import 'factura_abono_page.dart';
import 'listado_facturas_page.dart';

class Sidebar extends StatefulWidget {
  final String nombreUsuario;
  final String correoUsuario;
  final String currentRoute;
  final Function(String) onNavigate;
  final VoidCallback onLogout;
  final String dni;
  final String idUsuario;
  final String licencia;
  final String contrasena;
  final int idTipoUsuario;

  const Sidebar({
    Key? key,
    required this.nombreUsuario,
    required this.correoUsuario,
    required this.currentRoute,
    required this.onNavigate,
    required this.onLogout,
    required this.dni,
    required this.idUsuario,
    required this.licencia,
    required this.contrasena,
    required this.idTipoUsuario,
  }) : super(key: key);

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final sidebarWidth = isMobile ? 64.0 : 240.0;
    final background = Colors.white;
    final accent = const Color(0xFFA42429);
    final selectedColor = Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: sidebarWidth,
      height: double.infinity,
      decoration: BoxDecoration(
        color: background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo y nombre de la cooperativa
          Container(
            padding: EdgeInsets.symmetric(
              vertical: 16,
              horizontal: isMobile ? 8 : 16,
            ),
            child: Row(
              mainAxisAlignment:
                  isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'img/logo-uberneta-limpia.png',
                    width: isMobile ? 32 : 36,
                    height: isMobile ? 32 : 36,
                    fit: BoxFit.contain,
                  ),
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'Uberneta',
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isMobile)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: CircleAvatar(
                backgroundColor: accent,
                child: Icon(Icons.person, color: Colors.white),
              ),
            )
          else
            ListTile(
              leading: CircleAvatar(
                backgroundColor: accent,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(
                widget.nombreUsuario,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                widget.correoUsuario,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const SizedBox(height: 8),
          // Opciones
          Expanded(
            child: ListView(
              children: [
                _SidebarItem(
                  icon: Icons.dashboard,
                  label: 'Panel de control',
                  selected: widget.currentRoute == 'dashboard',
                  onTap: () => widget.onNavigate('dashboard'),
                  accent: accent,
                  selectedColor: selectedColor,
                ),
                _SidebarItem(
                  icon: Icons.description,
                  label: 'Documentación',
                  selected: widget.currentRoute == 'documentacion',
                  onTap: () => widget.onNavigate('documentacion'),
                  accent: accent,
                  selectedColor: selectedColor,
                ),
                _SidebarItem(
                  icon: Icons.announcement,
                  label: 'Tablón de anuncios',
                  selected: widget.currentRoute == 'tablon',
                  onTap: () => widget.onNavigate('tablon'),
                  accent: accent,
                  selectedColor: selectedColor,
                ),
                _SidebarItem(
                  icon: Icons.upload_file,
                  label: 'Subir facturas',
                  selected: widget.currentRoute == 'subir_facturas',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Subir Facturas'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: Icon(Icons.upload_file, color: accent),
                                title: Text('Subir nueva factura'),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => UploadPdfPage(
                                            idUsuario: widget.idUsuario,
                                            dni: widget.dni,
                                            nombre: widget.nombreUsuario,
                                            correo: widget.correoUsuario,
                                            licencia: widget.licencia,
                                            contrasena: widget.contrasena,
                                            idTipoUsuario: widget.idTipoUsuario,
                                          ),
                                    ),
                                  );
                                },
                              ),
                              ListTile(
                                leading: Icon(Icons.list_alt, color: accent),
                                title: Text('Estado de facturas'),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => EstadoFacturasPage(
                                            idUsuario: widget.idUsuario,
                                            nombreUsuario: widget.nombreUsuario,
                                            correoUsuario: widget.correoUsuario,
                                            dni: widget.dni,
                                            licencia: widget.licencia,
                                            contrasena: widget.contrasena,
                                            idTipoUsuario: widget.idTipoUsuario,
                                          ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  accent: accent,
                  selectedColor: selectedColor,
                ),
                _SidebarItem(
                  icon: Icons.receipt,
                  label: 'Generar factura',
                  selected: widget.currentRoute == 'generar_factura',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Generar Factura'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: Icon(
                                  Icons.directions_car,
                                  color: accent,
                                ),
                                title: Text('Factura Servicio Uberneta'),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (
                                            context,
                                          ) => FacturaServicioUbernetaPage(
                                            id: widget.idUsuario,
                                            dni: widget.dni,
                                            nombre: widget.nombreUsuario,
                                            correo: widget.correoUsuario,
                                            contrasena: widget.contrasena,
                                            licencia: widget.licencia,
                                            tipoFactura: 'Servicio Uberneta',
                                            idTipoUsuario: widget.idTipoUsuario,
                                            token: '',
                                          ),
                                    ),
                                  );
                                },
                              ),
                              ListTile(
                                leading: Icon(Icons.payment, color: accent),
                                title: Text('Factura Abono'),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => FacturaAbonoPage(
                                            id: widget.idUsuario,
                                            dni: widget.dni,
                                            nombre: widget.nombreUsuario,
                                            correo: widget.correoUsuario,
                                            contrasena: widget.contrasena,
                                            licencia: widget.licencia,
                                            tipoFactura: 'Abono',
                                            idTipoUsuario: widget.idTipoUsuario,
                                            token: '',
                                          ),
                                    ),
                                  );
                                },
                              ),
                              ListTile(
                                leading: Icon(Icons.list_alt, color: accent),
                                title: Text('Listado de Facturas'),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => ListadoFacturasPage(
                                            id: widget.idUsuario,
                                            dni: widget.dni,
                                            nombre: widget.nombreUsuario,
                                            correo: widget.correoUsuario,
                                            licencia: widget.licencia,
                                            contrasena: widget.contrasena,
                                            idTipoUsuario: widget.idTipoUsuario,
                                          ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  accent: accent,
                  selectedColor: selectedColor,
                ),
                _SidebarItem(
                  icon: Icons.calendar_today,
                  label: 'Calendario',
                  selected: widget.currentRoute == 'calendario',
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => CalendarioPage(
                              userId: widget.idUsuario,
                              nombreUsuario: widget.nombreUsuario,
                              correoUsuario: widget.correoUsuario,
                              dni: widget.dni,
                              licencia: widget.licencia,
                              contrasena: widget.contrasena,
                              idTipoUsuario: widget.idTipoUsuario,
                            ),
                      ),
                    );
                  },
                  accent: accent,
                  selectedColor: selectedColor,
                ),
                _SidebarItem(
                  icon: Icons.settings,
                  label: 'Configuración',
                  selected: widget.currentRoute == 'configuracion',
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => SettingsPage(
                              id: widget.idUsuario,
                              dni: widget.dni,
                              nombre: widget.nombreUsuario,
                              correo: widget.correoUsuario,
                              contrasena: widget.contrasena,
                              licencia: widget.licencia,
                              idTipoUsuario: widget.idTipoUsuario,
                            ),
                      ),
                    );
                  },
                  accent: accent,
                  selectedColor: selectedColor,
                ),
              ],
            ),
          ),
          // Cerrar sesión
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 8 : 16,
              vertical: 16,
            ),
            child:
                isMobile
                    ? IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      onPressed: widget.onLogout,
                      tooltip: 'Cerrar sesión',
                      color: accent,
                      iconSize: 28,
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                          accent,
                        ),
                        shape: MaterialStateProperty.all<CircleBorder>(
                          CircleBorder(),
                        ),
                      ),
                    )
                    : ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.logout),
                      label: const Text('Cerrar sesión'),
                      onPressed: widget.onLogout,
                    ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color accent;
  final Color selectedColor;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.accent,
    required this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Material(
      color: selected ? selectedColor : Colors.transparent,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: accent),
              if (!isMobile) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color:
                          selected
                              ? accent
                              : (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black87),
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
