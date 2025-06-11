import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';
import 'sidebar.dart';
import 'dashboard.dart';
import 'documentacion_page.dart';
import 'login.dart';

class AdminUsuariosPage extends StatefulWidget {
  final String adminId;
  final String adminName;
  final int idTipoUsuario;
  final String dni;
  final String correo;
  final String contrasena;

  const AdminUsuariosPage({
    Key? key,
    required this.adminId,
    required this.adminName,
    required this.idTipoUsuario,
    required this.dni,
    required this.correo,
    required this.contrasena,
  }) : super(key: key);

  @override
  _AdminUsuariosPageState createState() => _AdminUsuariosPageState();
}

class _AdminUsuariosPageState extends State<AdminUsuariosPage> {
  List<Map<String, dynamic>> usuarios = [];
  List<Map<String, dynamic>> tiposUsuario = [];
  List<Map<String, dynamic>> _filteredUsuarios = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _selectedTipoUsuario;
  String? _correoError;
  String? _selectedFiltroTipoUsuario;

  // Controladores para el formulario
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _codUsuarioController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _provinciaController = TextEditingController();
  final TextEditingController _codigoPostalController = TextEditingController();

  Map<String, dynamic>? _usuarioEditando;

  bool _isAdmin() {
    return widget.idTipoUsuario == 1 || widget.idTipoUsuario == 2;
  }

  @override
  void initState() {
    super.initState();
    _fetchUsuarios();
    _fetchTiposUsuario();
    _searchController.addListener(_filterUsuarios);
    _correoController.addListener(_validarCorreo);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isAdmin()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No tienes permisos para acceder a esta página'),
            backgroundColor: Colors.red,
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nombreController.dispose();
    _contrasenaController.dispose();
    _telefonoController.dispose();
    _dniController.dispose();
    _correoController.dispose();
    _codUsuarioController.dispose();
    _direccionController.dispose();
    _provinciaController.dispose();
    _codigoPostalController.dispose();
    super.dispose();
  }

  void _filterUsuarios() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      var usuariosFiltrados = usuarios;
      if (widget.idTipoUsuario == 2) {
        // Admin: solo conductores y clientes
        usuariosFiltrados =
            usuarios
                .where(
                  (usuario) =>
                      usuario['IdTipoUsuario'] != '1' &&
                      usuario['IdTipoUsuario'] != '2',
                )
                .toList();
      }
      // Filtro por tipo de usuario seleccionado
      if (_selectedFiltroTipoUsuario != null &&
          _selectedFiltroTipoUsuario != 'todos') {
        usuariosFiltrados =
            usuariosFiltrados
                .where(
                  (usuario) =>
                      usuario['IdTipoUsuario'].toString() ==
                      _selectedFiltroTipoUsuario,
                )
                .toList();
      }
      // Filtro de búsqueda por texto
      _filteredUsuarios =
          usuariosFiltrados.where((usuario) {
            final nombre = usuario['Nombre']?.toString().toLowerCase() ?? '';
            final dni = usuario['DNIUsuario']?.toString().toLowerCase() ?? '';
            final correo =
                usuario['CorreoUsuario']?.toString().toLowerCase() ?? '';
            return nombre.contains(query) ||
                dni.contains(query) ||
                correo.contains(query);
          }).toList();
    });
  }

  void _validarCorreo() {
    final correo = _correoController.text;
    if (correo.isEmpty) {
      setState(() => _correoError = null);
      return;
    }

    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
    );
    if (!emailRegExp.hasMatch(correo)) {
      setState(
        () => _correoError = 'Por favor, ingrese un correo electrónico válido',
      );
      return;
    }

    final correoExiste = usuarios.any((usuario) {
      if (_usuarioEditando != null) {
        final idActual =
            _usuarioEditando!['IdUsuario']?.toString() ??
            _usuarioEditando!['IdCliente']?.toString();
        final idUsuario =
            usuario['IdUsuario']?.toString() ??
            usuario['IdCliente']?.toString();
        if (idUsuario == idActual) {
          return false;
        }
      }
      return usuario['CorreoUsuario']?.toString().toLowerCase() ==
          correo.toLowerCase();
    });

    setState(() {
      _correoError =
          correoExiste ? 'Este correo electrónico ya está registrado' : null;
    });
  }

  Future<void> _fetchTiposUsuario() async {
    try {
      final response = await http.get(
        Uri.parse(
          '${Config.baseUrl}gestion_usuarios.php?action=fetch_tipos_usuario',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          setState(() {
            tiposUsuario =
                data.map((item) => Map<String, dynamic>.from(item)).toList();
          });
        }
      }
    } catch (e) {
      print('Error al obtener tipos de usuario: $e');
    }
  }

  Future<void> _fetchUsuarios() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}gestion_usuarios.php?action=fetch'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          if (mounted) {
            setState(() {
              usuarios =
                  data.map((item) => Map<String, dynamic>.from(item)).toList();
              _isLoading = false;
              _filterUsuarios();
            });
          }
        } else if (data is Map && data.containsKey('error')) {
          if (mounted) {
            setState(() {
              _errorMessage = data['error'];
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Error al conectar con el servidor';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _crearUsuario() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, complete todos los campos correctamente'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_selectedTipoUsuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe seleccionar un tipo de usuario'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}gestion_usuarios.php'),
        body:
            _selectedTipoUsuario ==
                    '4' // Si es cliente (tipo 4)
                ? {
                  // Cuerpo para crear cliente
                  'action': 'crear_cliente', // Nueva acción para clientes
                  'nombre': _nombreController.text.toString(),
                  'telefono': _telefonoController.text.toString(),
                  'dni': _dniController.text.toString(),
                  'correo': _correoController.text.toString(),
                  'codUsuario': _codUsuarioController.text.toString(),
                  'direccion': _direccionController.text.toString(),
                  'poblacion':
                      _provinciaController.text
                          .toString(), // Usamos Provincia temporalmente para Poblacion
                  'provincia': _provinciaController.text.toString(),
                  'codigoPostal': _codigoPostalController.text.toString(),
                  'idTipoUsuario': _selectedTipoUsuario ?? '',
                  'IdEmpresa': '1', // Asignar empresa 1 por defecto
                  'EstadoUsuario': '1', // Asignar estado 1 por defecto
                }
                : {
                  // Cuerpo para crear usuario (otros tipos)
                  'action': 'crear',
                  'nombre': _nombreController.text,
                  'telefono': _telefonoController.text,
                  'dni': _dniController.text,
                  'correo': _correoController.text,
                  'codUsuario': _codUsuarioController.text,
                  'direccion': _direccionController.text,
                  'provincia': _provinciaController.text,
                  'codigoPostal': _codigoPostalController.text,
                  'idTipoUsuario': _selectedTipoUsuario,
                },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuario creado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          if (mounted) {
            _limpiarFormulario();
            Navigator.pop(context);
          }
          await _fetchUsuarios();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Error al crear el usuario'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _limpiarFormulario() {
    _nombreController.clear();
    _contrasenaController.clear();
    _telefonoController.clear();
    _dniController.clear();
    _correoController.clear();
    _codUsuarioController.clear();
    _direccionController.clear();
    _provinciaController.clear();
    _codigoPostalController.clear();
    setState(() {
      _selectedTipoUsuario = null;
      _usuarioEditando = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          Sidebar(
            nombreUsuario: widget.adminName,
            correoUsuario: widget.correo,
            currentRoute: 'admin_usuarios',
            onNavigate: (route) {
              if (route == 'dashboard') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => MyHomePage(
                          title: 'Panel de control',
                          dni: widget.dni,
                          nombre: widget.adminName,
                          correo: widget.correo,
                          id: widget.adminId,
                          licencia: '',
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
                          idUsuario: widget.adminId,
                          onDocumentosContabilizadosChanged: () {},
                          dni: widget.dni,
                          licencia: '',
                          contrasena: widget.contrasena,
                          nombre: widget.adminName,
                          correo: widget.correo,
                          idTipoUsuario: widget.idTipoUsuario,
                        ),
                  ),
                );
              }
            },
            onLogout: () async {
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
                          await _handleLogout();
                        },
                      ),
                    ],
                  );
                },
              );
            },
            dni: widget.dni,
            idUsuario: widget.adminId,
            licencia: '',
            contrasena: widget.contrasena,
            idTipoUsuario: widget.idTipoUsuario,
          ),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                    : Column(
                      children: [
                        Container(
                          color: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal:
                                MediaQuery.of(context).size.width < 600
                                    ? 8.0
                                    : 16.0,
                            vertical: 16.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.admin_panel_settings,
                                      color: Color(0xFFA42429),
                                      size:
                                          MediaQuery.of(context).size.width <
                                                  600
                                              ? 20
                                              : 32,
                                    ),
                                    SizedBox(
                                      width:
                                          MediaQuery.of(context).size.width <
                                                  600
                                              ? 4
                                              : 12,
                                    ),
                                    Flexible(
                                      child: Text(
                                        'Administrar Usuarios',
                                        style: TextStyle(
                                          color:
                                              Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Color(0xFF181C32),
                                          fontWeight: FontWeight.bold,
                                          fontSize:
                                              MediaQuery.of(
                                                        context,
                                                      ).size.width <
                                                      600
                                                  ? 16
                                                  : 24,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Wrap(
                                alignment: WrapAlignment.end,
                                spacing:
                                    8.0, // Espacio entre los elementos del Wrap
                                runSpacing:
                                    8.0, // Espacio entre las líneas del Wrap
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _mostrarFormularioUsuario,
                                    icon: Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size:
                                          MediaQuery.of(context).size.width <
                                                  600
                                              ? 18
                                              : 24,
                                    ),
                                    label: Text(
                                      'Nuevo Usuario',
                                      style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width <
                                                    600
                                                ? 12
                                                : null,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFA42429),
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                        horizontal:
                                            MediaQuery.of(context).size.width <
                                                    600
                                                ? 8
                                                : 16,
                                        vertical:
                                            MediaQuery.of(context).size.width <
                                                    600
                                                ? 8
                                                : 12,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.refresh,
                                      color: Color(0xFFA42429),
                                      size:
                                          MediaQuery.of(context).size.width <
                                                  600
                                              ? 20
                                              : 24,
                                    ),
                                    tooltip: 'Actualizar lista',
                                    onPressed: _fetchUsuarios,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              labelText: 'Buscar usuario',
                              hintText: 'Buscar por nombre, DNI o correo...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon:
                                  _searchController.text.isNotEmpty
                                      ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _searchController.clear();
                                          _filterUsuarios();
                                        },
                                      )
                                      : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                          ),
                        ),
                        // Filtro por tipo de usuario
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              const Text('Filtrar por tipo: '),
                              const SizedBox(width: 8),
                              DropdownButton<String>(
                                value: _selectedFiltroTipoUsuario ?? 'todos',
                                items: [
                                  DropdownMenuItem(
                                    value: 'todos',
                                    child: Text('Todos'),
                                  ),
                                  if (widget.idTipoUsuario == 1)
                                    DropdownMenuItem(
                                      value: '2',
                                      child: Text('Admins'),
                                    ),
                                  DropdownMenuItem(
                                    value: '3',
                                    child: Text('Conductores'),
                                  ),
                                  DropdownMenuItem(
                                    value: '4',
                                    child: Text('Clientes'),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedFiltroTipoUsuario = value;
                                    _filterUsuarios();
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child:
                              _filteredUsuarios.isEmpty
                                  ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.search_off,
                                          size: 64,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No se encontraron usuarios',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  : ListView.builder(
                                    padding: const EdgeInsets.all(8),
                                    itemCount: _filteredUsuarios.length,
                                    itemBuilder: (context, index) {
                                      final usuario = _filteredUsuarios[index];
                                      return Card(
                                        elevation: 2,
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        color: Colors.white,
                                        child: ExpansionTile(
                                          leading: CircleAvatar(
                                            backgroundColor: const Color(
                                              0xFFA42429,
                                            ),
                                            child: Text(
                                              usuario['Nombre']?[0]
                                                      ?.toUpperCase() ??
                                                  '?',
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            usuario['Nombre'] ?? 'Sin nombre',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.badge,
                                                    size: 16,
                                                    color: Colors.grey,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      'DNI: ${usuario['DNIUsuario'] ?? 'N/A'}',
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.email,
                                                    size: 16,
                                                    color: Colors.grey,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      '${usuario['CorreoUsuario'] ?? 'N/A'}',
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: Icon(
                                                  Icons.edit,
                                                  color: Colors.orange,
                                                  size:
                                                      MediaQuery.of(
                                                                context,
                                                              ).size.width <
                                                              600
                                                          ? 20
                                                          : 24,
                                                ),
                                                tooltip: 'Editar usuario',
                                                onPressed:
                                                    () =>
                                                        _editarUsuario(usuario),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.delete,
                                                  color: Color(0xFFA42429),
                                                  size:
                                                      MediaQuery.of(
                                                                context,
                                                              ).size.width <
                                                              600
                                                          ? 20
                                                          : 24,
                                                ),
                                                tooltip: 'Eliminar usuario',
                                                onPressed:
                                                    () => _eliminarUsuario(
                                                      usuario['IdUsuario'],
                                                    ),
                                              ),
                                            ],
                                          ),
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.all(
                                                16.0,
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  _buildInfoRow(
                                                    'Teléfono',
                                                    usuario['TelefonoUsuario'],
                                                  ),
                                                  _buildInfoRow(
                                                    'Dirección',
                                                    usuario['Direccion'],
                                                  ),
                                                  _buildInfoRow(
                                                    'Provincia',
                                                    usuario['Provincia'],
                                                  ),
                                                  _buildInfoRow(
                                                    'Código Postal',
                                                    usuario['CodigoPostal'],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                        ),
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          Text(value ?? 'N/A'),
        ],
      ),
    );
  }

  void _mostrarFormularioUsuario() {
    _limpiarFormulario();

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 24,
            ),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              constraints: const BoxConstraints(maxWidth: 800),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA42429),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person_add,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Nuevo Usuario',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Información Personal',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF181C32),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildFormField(
                                    controller: _nombreController,
                                    label: 'Nombre Completo',
                                    icon: Icons.person,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildFormField(
                                    controller: _dniController,
                                    label: 'DNI',
                                    icon: Icons.badge,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildFormField(
                                    controller: _correoController,
                                    label: 'Correo',
                                    icon: Icons.email,
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildFormField(
                                    controller: _telefonoController,
                                    label: 'Teléfono',
                                    icon: Icons.phone,
                                    keyboardType: TextInputType.phone,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Información de Acceso',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF181C32),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildFormField(
                                    controller: _codUsuarioController,
                                    label: 'Código de Usuario',
                                    icon: Icons.numbers,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Información de Contacto',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF181C32),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildFormField(
                              controller: _direccionController,
                              label: 'Dirección',
                              icon: Icons.home,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildFormField(
                                    controller: _provinciaController,
                                    label: 'Provincia',
                                    icon: Icons.location_city,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildFormField(
                                    controller: _codigoPostalController,
                                    label: 'Código Postal',
                                    icon: Icons.local_post_office,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Tipo de Usuario',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF181C32),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Mostrar el campo solo si no es cliente
                            if (!(_selectedTipoUsuario == '4' ||
                                (_usuarioEditando != null &&
                                    _usuarioEditando!['IdTipoUsuario']
                                            ?.toString() ==
                                        '4')))
                              DropdownButtonFormField<String>(
                                value: _selectedTipoUsuario,
                                decoration: InputDecoration(
                                  labelText: 'Seleccionar tipo de usuario',
                                  prefixIcon: const Icon(Icons.person_outline),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                items:
                                    tiposUsuario
                                        .where((tipo) {
                                          if (widget.idTipoUsuario == 1) {
                                            return tipo['idTipoUsuario'] ==
                                                    '2' || // Admin
                                                tipo['idTipoUsuario'] ==
                                                    '3' || // Conductor
                                                tipo['idTipoUsuario'] ==
                                                    '4'; // Cliente
                                          } else if (widget.idTipoUsuario ==
                                              2) {
                                            return tipo['idTipoUsuario'] ==
                                                    '3' || // Conductor
                                                tipo['idTipoUsuario'] ==
                                                    '4'; // Cliente
                                          }
                                          return false;
                                        })
                                        .map((tipo) {
                                          return DropdownMenuItem<String>(
                                            value:
                                                tipo['idTipoUsuario']
                                                    .toString(),
                                            child: Text(
                                              tipo['DescripcionTipo'],
                                            ),
                                          );
                                        })
                                        .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedTipoUsuario = value;
                                  });
                                },
                                validator:
                                    (value) =>
                                        value == null
                                            ? 'Campo requerido'
                                            : null,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _limpiarFormulario();
                          },
                          icon: const Icon(Icons.cancel),
                          label: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            _crearUsuario();
                          },
                          icon: const Icon(Icons.save),
                          label: const Text('Guardar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFA42429),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey[50],
        hintText: hintText,
        errorText: label == 'Correo' ? _correoError : null,
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator:
          validator ??
          (value) {
            // Si es cliente, no validar nada (tanto en creación como edición)
            final esCliente =
                _selectedTipoUsuario == '4' ||
                (_usuarioEditando != null &&
                    (_usuarioEditando!['IdTipoUsuario']?.toString() == '4'));
            if (esCliente) {
              return null;
            }
            if (value == null || value.isEmpty) {
              return 'Este campo es obligatorio';
            }
            // Validaciones específicas según el tipo de campo
            if (label == 'DNI') {
              final RegExp dniNifRegExp = RegExp(
                r'^[0-9]{8}[a-zA-Z]$|^[XYZxyz][0-9]{7}[a-zA-Z]$|^[ABCDEFGHJNPQRSUVWabcdefghjnpqrsuvw][0-9]{7}[0-9A-Ja-j]$',
                caseSensitive: false,
              );
              if (!dniNifRegExp.hasMatch(value)) {
                return 'Por favor, ingrese un DNI/NIE/CIF válido';
              }
            } else if (label == 'Correo') {
              final emailRegExp = RegExp(
                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
              );
              if (!emailRegExp.hasMatch(value)) {
                return 'Por favor, ingrese un correo electrónico válido';
              }
              if (_correoError != null) {
                return _correoError;
              }
            } else if (label == 'Teléfono') {
              final phoneRegExp = RegExp(r'^[0-9]{9}$');
              if (!phoneRegExp.hasMatch(value)) {
                return 'Por favor, ingrese un teléfono válido (9 dígitos)';
              }
            } else if (label == 'Código Postal') {
              final postalCodeRegExp = RegExp(r'^[0-9]{5}$');
              if (!postalCodeRegExp.hasMatch(value)) {
                return 'Por favor, ingrese un código postal válido (5 dígitos)';
              }
            } else if (label == 'Nombre') {
              if (value.length < 2) {
                return 'El nombre debe tener al menos 2 caracteres';
              }
              if (value.length > 50) {
                return 'El nombre no puede tener más de 50 caracteres';
              }
            } else if (label == 'Código de Usuario') {
              if (value.length < 3) {
                return 'El código de usuario debe tener al menos 3 caracteres';
              }
              if (value.length > 20) {
                return 'El código de usuario no puede tener más de 20 caracteres';
              }
            } else if (label == 'Contraseña') {
              if (value.length < 8) {
                return 'La contraseña debe tener al menos 8 caracteres';
              }
              if (!RegExp(r'[A-Z]').hasMatch(value)) {
                return 'La contraseña debe contener al menos una mayúscula';
              }
              if (!RegExp(r'[a-z]').hasMatch(value)) {
                return 'La contraseña debe contener al menos una minúscula';
              }
              if (!RegExp(r'[0-9]').hasMatch(value)) {
                return 'La contraseña debe contener al menos un número';
              }
            }
            return null;
          },
    );
  }

  void _editarUsuario(Map<String, dynamic> usuario) {
    _limpiarFormulario();

    _usuarioEditando = usuario;

    _nombreController.text = usuario['Nombre'] ?? '';
    _telefonoController.text = usuario['TelefonoUsuario']?.toString() ?? '';
    _dniController.text = usuario['DNIUsuario'] ?? '';
    _correoController.text = usuario['CorreoUsuario'] ?? '';
    _codUsuarioController.text = usuario['CodUsuario']?.toString() ?? '';
    _direccionController.text = usuario['Direccion'] ?? '';
    _provinciaController.text = usuario['Provincia'] ?? '';
    _codigoPostalController.text = usuario['CodigoPostal'] ?? '';

    final idTipoUsuario = usuario['IdTipoUsuario']?.toString();
    if (idTipoUsuario != null &&
        tiposUsuario.any(
          (tipo) => tipo['idTipoUsuario'].toString() == idTipoUsuario,
        )) {
      setState(() {
        _selectedTipoUsuario = idTipoUsuario;
      });
    } else {
      setState(() {
        _selectedTipoUsuario = null;
      });
    }

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 24,
            ),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              constraints: const BoxConstraints(maxWidth: 800),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA42429),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.edit, color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          'Editar ${usuario['IdTipoUsuario'] == '4' ? 'Cliente' : 'Usuario'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Información Personal',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF181C32),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildFormField(
                                    controller: _nombreController,
                                    label: 'Nombre',
                                    icon: Icons.person,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildFormField(
                                    controller: _dniController,
                                    label: 'DNI',
                                    icon: Icons.badge,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildFormField(
                                    controller: _correoController,
                                    label: 'Correo',
                                    icon: Icons.email,
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildFormField(
                                    controller: _telefonoController,
                                    label: 'Teléfono',
                                    icon: Icons.phone,
                                    keyboardType: TextInputType.phone,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Información de Acceso',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF181C32),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildFormField(
                                    controller: _codUsuarioController,
                                    label: 'Código de Usuario',
                                    icon: Icons.numbers,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Información de Contacto',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF181C32),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildFormField(
                              controller: _direccionController,
                              label: 'Dirección',
                              icon: Icons.home,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildFormField(
                                    controller: _provinciaController,
                                    label: 'Provincia',
                                    icon: Icons.location_city,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildFormField(
                                    controller: _codigoPostalController,
                                    label: 'Código Postal',
                                    icon: Icons.local_post_office,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Tipo de Usuario',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF181C32),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Mostrar el campo solo si no es cliente
                            if (!(_selectedTipoUsuario == '4' ||
                                (_usuarioEditando != null &&
                                    _usuarioEditando!['IdTipoUsuario']
                                            ?.toString() ==
                                        '4')))
                              DropdownButtonFormField<String>(
                                value: _selectedTipoUsuario,
                                decoration: InputDecoration(
                                  labelText: 'Seleccionar tipo de usuario',
                                  prefixIcon: const Icon(Icons.person_outline),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                items:
                                    tiposUsuario
                                        .where((tipo) {
                                          if (widget.idTipoUsuario == 1) {
                                            return tipo['idTipoUsuario'] ==
                                                    '2' || // Admin
                                                tipo['idTipoUsuario'] ==
                                                    '3' || // Conductor
                                                tipo['idTipoUsuario'] ==
                                                    '4'; // Cliente
                                          } else if (widget.idTipoUsuario ==
                                              2) {
                                            return tipo['idTipoUsuario'] ==
                                                    '3' || // Conductor
                                                tipo['idTipoUsuario'] ==
                                                    '4'; // Cliente
                                          }
                                          return false;
                                        })
                                        .map((tipo) {
                                          return DropdownMenuItem<String>(
                                            value:
                                                tipo['idTipoUsuario']
                                                    .toString(),
                                            child: Text(
                                              tipo['DescripcionTipo'],
                                            ),
                                          );
                                        })
                                        .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedTipoUsuario = value;
                                  });
                                },
                                validator:
                                    (value) =>
                                        value == null
                                            ? 'Campo requerido'
                                            : null,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _limpiarFormulario();
                            _usuarioEditando = null;
                          },
                          icon: const Icon(Icons.cancel),
                          label: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              try {
                                final response = await http.post(
                                  Uri.parse(
                                    '${Config.baseUrl}gestion_usuarios.php',
                                  ),
                                  body:
                                      _selectedTipoUsuario == '4' ||
                                              (_usuarioEditando != null &&
                                                  _usuarioEditando!['IdTipoUsuario']
                                                          ?.toString() ==
                                                      '4')
                                          ? {
                                            'action': 'actualizar',
                                            'idUsuario':
                                                usuario['IdUsuario'] ??
                                                usuario['IdCliente'],
                                            'nombre':
                                                _nombreController.text
                                                    .toString(),
                                            'idTipoUsuario':
                                                usuario['IdTipoUsuario']
                                                    ?.toString() ??
                                                '4',
                                            'telefono':
                                                _telefonoController.text
                                                    .toString(),
                                            'dni':
                                                _dniController.text.toString(),
                                            'direccion':
                                                _direccionController.text
                                                    .toString(),
                                            'poblacion':
                                                _provinciaController.text
                                                    .toString(),
                                            'provincia':
                                                _provinciaController.text
                                                    .toString(),
                                            'codigoPostal':
                                                _codigoPostalController.text
                                                    .toString(),
                                            'correo':
                                                _correoController.text
                                                    .toString(),
                                            'IdEmpresa': '1',
                                            'codUsuario':
                                                _codUsuarioController.text
                                                    .toString(),
                                            'EstadoUsuario': '1',
                                          }
                                          : {
                                            'action': 'actualizar',
                                            'idUsuario': usuario['IdUsuario'],
                                            'nombre':
                                                _nombreController.text
                                                    .toString(),
                                            'telefono':
                                                _telefonoController.text
                                                    .toString(),
                                            'dni':
                                                _dniController.text.toString(),
                                            'correo':
                                                _correoController.text
                                                    .toString(),
                                            'codUsuario':
                                                _codUsuarioController.text
                                                    .toString(),
                                            'direccion':
                                                _direccionController.text
                                                    .toString(),
                                            'provincia':
                                                _provinciaController.text
                                                    .toString(),
                                            'codigoPostal':
                                                _codigoPostalController.text
                                                    .toString(),
                                            'idTipoUsuario':
                                                usuario['IdTipoUsuario']
                                                    ?.toString() ??
                                                '4',
                                          },
                                );

                                if (response.statusCode == 200) {
                                  final data = json.decode(response.body);
                                  if (data['success'] == true) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Usuario actualizado correctamente',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    Navigator.pop(context);
                                    _limpiarFormulario();
                                    _usuarioEditando = null;
                                    await _fetchUsuarios();
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          data['message'] ??
                                              'Error al actualizar el usuario',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          icon: const Icon(Icons.save),
                          label: const Text('Guardar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFA42429),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _eliminarUsuario(String idUsuario) async {
    // Buscar el usuario que se intenta eliminar
    final usuarioAEliminar = usuarios.firstWhere(
      (u) => u['IdUsuario'] == idUsuario,
      orElse: () => {},
    );

    // Verificar si el usuario que intenta eliminar es superadmin
    if (widget.idTipoUsuario != 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solo el superadmin puede eliminar usuarios'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Verificar si el usuario a eliminar es superadmin o admin
    if (usuarioAEliminar['IdTipoUsuario'] == '1' ||
        usuarioAEliminar['IdTipoUsuario'] == '2') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pueden eliminar usuarios superadmin o admin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmacion = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.warning, color: Colors.red),
                const SizedBox(width: 8),
                const Text('Confirmar eliminación'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.delete_forever, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  '¿Estás seguro de que deseas eliminar este usuario?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Esta acción no se puede deshacer.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton.icon(
                onPressed: () => Navigator.pop(context, false),
                icon: const Icon(Icons.cancel),
                label: const Text('Cancelar'),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA42429),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.delete),
                label: const Text('Eliminar'),
              ),
            ],
          ),
    );

    if (confirmacion == true) {
      try {
        final response = await http.post(
          Uri.parse('${Config.baseUrl}gestion_usuarios.php'),
          body: {'action': 'eliminar', 'idUsuario': idUsuario},
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Usuario eliminado correctamente'),
                backgroundColor: Colors.green,
              ),
            );
            await _fetchUsuarios();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  data['message'] ?? 'Error al eliminar el usuario',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _handleLogout() async {
    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}eliminar_token.php'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{'dni': widget.dni}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        print('Token eliminado correctamente');
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } catch (e) {
      print('Error en la solicitud: $e');
    }
  }
}
