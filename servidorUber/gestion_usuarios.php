<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Incluir el archivo de configuración que debe definir $servername, $username, $password, $dbname
include 'config.php';

// Configuración de la base de datos usando variables de config.php
$host = $servername; // Asumiendo que $servername es tu host
$dbname = $dbname;
$username = $username;
$password = $password;

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    // Asegurarse de que el mensaje de error también sea JSON
    echo json_encode(['error' => 'Error de conexión a la base de datos: ' . $e->getMessage()]);
    exit;
}

// Obtener el método de la petición
$method = $_SERVER['REQUEST_METHOD'];

// Obtener la acción desde el parámetro 'action' para POST, o desde el parámetro 'action' en la URL para GET
$action = isset($_POST['action']) ? $_POST['action'] : (isset($_GET['action']) ? $_GET['action'] : '');

switch($method) {
    case 'GET':
        // Obtener todos los usuarios
        if ($action === 'fetch') { // Usar una acción específica para GET si es necesario, o simplemente obtener todos
            try {
                // Obtener usuarios
                $stmtUsuarios = $pdo->query("SELECT *, IdUsuario as id, 'usuario' as origen FROM usuario");
                $usuarios = $stmtUsuarios->fetchAll(PDO::FETCH_ASSOC);

                // Obtener clientes
                $stmtClientes = $pdo->query("SELECT *, IdCliente as id, 'cliente' as origen FROM clientes");
                $clientes = $stmtClientes->fetchAll(PDO::FETCH_ASSOC);

                // Unir ambos arrays
                $todos = array_merge($usuarios, $clientes);
                // Convertir IdTipoUsuario a string en todos los elementos
                foreach ($todos as &$item) {
                    if (isset($item['IdTipoUsuario'])) {
                        $item['IdTipoUsuario'] = strval($item['IdTipoUsuario']);
                    }
                }
                echo json_encode($todos);
            } catch(PDOException $e) {
                echo json_encode(['error' => 'Error al obtener usuarios: ' . $e->getMessage()]);
            }
        } else if ($action === 'fetch_tipos_usuario') {
            try {
                // Obtener todos los tipos de usuario excepto Superadmin (idTipoUsuario = 1)
                $stmt = $pdo->query("SELECT idTipoUsuario, DescripcionTipo FROM tipousuario WHERE idTipoUsuario NOT IN (1, 4)");
                $tipos = $stmt->fetchAll(PDO::FETCH_ASSOC);
                echo json_encode($tipos);
            } catch(PDOException $e) {
                echo json_encode(['error' => 'Error al obtener tipos de usuario: ' . $e->getMessage()]);
            }
        } else {
             // Si no se especifica acción en GET, o acción no reconocida para GET
            echo json_encode(['error' => 'Acción GET no válida']);
        }
        break;

    case 'POST':
        switch($action) {
            case 'crear_cliente':
                try {
                    $nombre = $_POST['nombre'] ?? '';
                    $telefono = $_POST['telefono'] ?? '';
                    $dni = $_POST['dni'] ?? '';
                    $correo = $_POST['correo'] ?? '';
                    $codUsuario = $_POST['codUsuario'] ?? '';
                    $direccion = $_POST['direccion'] ?? '';
                    $poblacion = $_POST['poblacion'] ?? '';
                    $provincia = $_POST['provincia'] ?? '';
                    $codigoPostal = $_POST['codigoPostal'] ?? '';
                    $idTipoUsuario = $_POST['idTipoUsuario'] ?? '';
                    $idEmpresa = $_POST['IdEmpresa'] ?? '1';
                    $estadoUsuario = $_POST['EstadoUsuario'] ?? '1';

                    // Validar campos requeridos
                    if (empty($nombre) || empty($dni) || empty($correo)) {
                        echo json_encode(['success' => false, 'message' => 'Campos requeridos faltantes']);
                        exit;
                    }

                    $stmt = $pdo->prepare("INSERT INTO clientes (Nombre, Contrasena, IdTipoUsuario, TelefonoUsuario, DNIUsuario, Direccion, Poblacion, Provincia, CodigoPostal, CorreoUsuario, IdEmpresa, CodUsuario, EstadoUsuario) VALUES (?, NULL, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");

                    if($stmt->execute([$nombre, $idTipoUsuario, $telefono, $dni, $direccion, $poblacion, $provincia, $codigoPostal, $correo, $idEmpresa, $codUsuario, $estadoUsuario])) {
                        echo json_encode(['success' => true, 'message' => 'Cliente creado correctamente']);
                    } else {
                        echo json_encode(['success' => false, 'message' => 'Error al crear el cliente']);
                    }
                } catch(PDOException $e) {
                    echo json_encode(['success' => false, 'message' => 'Error en la creación: ' . $e->getMessage()]);
                }
                break;

            case 'crear':
                // Crear nuevo usuario
                try {
                    $nombre = $_POST['nombre'] ?? '';
                    $contrasena = $_POST['contrasena'] ?? '';
                    $telefono = $_POST['telefono'] ?? '';
                    $dni = $_POST['dni'] ?? '';
                    $correo = $_POST['correo'] ?? '';
                    $codUsuario = $_POST['codUsuario'] ?? '';
                    $direccion = $_POST['direccion'] ?? '';
                    $provincia = $_POST['provincia'] ?? '';
                    $codigoPostal = $_POST['codigoPostal'] ?? '';
                    $idTipoUsuario = $_POST['idTipoUsuario'] ?? '';

                    // Validar campos requeridos
                    if (empty($nombre) || empty($dni) || empty($correo) || empty($idTipoUsuario)) {
                        echo json_encode(['success' => false, 'message' => 'Campos requeridos faltantes']);
                        exit;
                    }

                    // Validar que el tipo de usuario no sea Superadmin (1)
                    if ($idTipoUsuario == 1) {
                        echo json_encode(['success' => false, 'message' => 'No se puede crear un usuario Superadmin']);
                        exit;
                    }

                    $hashed_contrasena = password_hash($contrasena, PASSWORD_DEFAULT);
                    $idEmpresa = 1; // Asignar automáticamente idEmpresa 1

                    $stmt = $pdo->prepare("INSERT INTO usuario (Nombre, Contrasena, TelefonoUsuario, DNIUsuario, CorreoUsuario, CodUsuario, Direccion, Provincia, CodigoPostal, IdTipoUsuario, EstadoUsuario, IdEmpresa) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?)");

                    if($stmt->execute([$nombre, $hashed_contrasena, $telefono, $dni, $correo, $codUsuario, $direccion, $provincia, $codigoPostal, $idTipoUsuario, $idEmpresa])) {
                        echo json_encode(['success' => true, 'message' => 'Usuario creado correctamente']);
                    } else {
                        echo json_encode(['success' => false, 'message' => 'Error al crear el usuario']);
                    }
                } catch(PDOException $e) {
                    echo json_encode(['success' => false, 'message' => 'Error en la creación: ' . $e->getMessage()]);
                }
                break;

            case 'actualizar':
                // Actualizar usuario o cliente existente
                try {
                    $idUsuario = $_POST['idUsuario'] ?? '';
                    $nombre = $_POST['nombre'] ?? '';
                    $telefono = $_POST['telefono'] ?? '';
                    $dni = $_POST['dni'] ?? '';
                    $correo = $_POST['correo'] ?? '';
                    $codUsuario = $_POST['codUsuario'] ?? '';
                    $direccion = $_POST['direccion'] ?? '';
                    $provincia = $_POST['provincia'] ?? '';
                    $codigoPostal = $_POST['codigoPostal'] ?? '';
                    $nueva_contrasena = $_POST['contrasena'] ?? '';
                    $idTipoUsuario = $_POST['idTipoUsuario'] ?? '';
                    $poblacion = $_POST['poblacion'] ?? '';
                    $idEmpresa = $_POST['IdEmpresa'] ?? null;
                    $estadoUsuario = $_POST['EstadoUsuario'] ?? null;

                    if (empty($idUsuario)) {
                        echo json_encode(['success' => false, 'message' => 'ID para actualización faltante']);
                        exit;
                    }

                    if ($idTipoUsuario == '4') {
                        // Actualizar cliente
                        $sql = "UPDATE clientes SET
                                    Nombre = ?,
                                    IdTipoUsuario = ?,
                                    TelefonoUsuario = ?,
                                    DNIUsuario = ?,
                                    Direccion = ?,
                                    Poblacion = ?,
                                    Provincia = ?,
                                    CodigoPostal = ?,
                                    CorreoUsuario = ?,
                                    IdEmpresa = ?,
                                    CodUsuario = ?,
                                    EstadoUsuario = ?
                                WHERE IdCliente = ?";
                        $params = [
                            $nombre,           // Nombre
                            $idTipoUsuario,    // IdTipoUsuario
                            $telefono,         // TelefonoUsuario
                            $dni,              // DNIUsuario
                            $direccion,        // Direccion
                            $poblacion,        // Poblacion
                            $provincia,        // Provincia
                            $codigoPostal,     // CodigoPostal
                            $correo,           // CorreoUsuario
                            $idEmpresa,        // IdEmpresa
                            $codUsuario,       // CodUsuario
                            $estadoUsuario,    // EstadoUsuario
                            $idUsuario         // IdCliente (WHERE)
                        ];
                        $stmt = $pdo->prepare($sql);
                    } else {
                        // Actualizar usuario normal
                        $sql = "UPDATE usuario SET
                                    Nombre = ?,
                                    TelefonoUsuario = ?,
                                    DNIUsuario = ?,
                                    CorreoUsuario = ?,
                                    CodUsuario = ?,
                                    Direccion = ?,
                                    Provincia = ?,
                                    CodigoPostal = ?";
                        $params = [$nombre, $telefono, $dni, $correo, $codUsuario, $direccion, $provincia, $codigoPostal];
                        if(!empty($nueva_contrasena)) {
                            $hashed_nueva_contrasena = password_hash($nueva_contrasena, PASSWORD_DEFAULT);
                            $sql .= ", Contrasena = ?";
                            $params[] = $hashed_nueva_contrasena;
                        }
                        $sql .= " WHERE IdUsuario = ?";
                        $params[] = $idUsuario;
                        $stmt = $pdo->prepare($sql);
                    }

                    if($stmt->execute($params)) {
                        echo json_encode(['success' => true, 'message' => 'Usuario actualizado correctamente']);
                    } else {
                        echo json_encode(['success' => false, 'message' => 'Error al actualizar el usuario']);
                    }
                } catch(PDOException $e) {
                    echo json_encode(['success' => false, 'message' => 'Error en la actualización: ' . $e->getMessage()]);
                }
                break;

            case 'eliminar':
                // Eliminar usuario
                try {
                    $idUsuario = $_POST['idUsuario'] ?? '';

                    if (empty($idUsuario)) {
                         echo json_encode(['success' => false, 'message' => 'ID de usuario para eliminar faltante']);
                         exit;
                    }

                    // Verificar si el usuario existe y no es superadmin
                    $stmt = $pdo->prepare("SELECT IdTipoUsuario FROM usuario WHERE IdUsuario = ?");
                    $stmt->execute([$idUsuario]);
                    $usuario = $stmt->fetch(PDO::FETCH_ASSOC);

                    if($usuario && $usuario['IdTipoUsuario'] != 1) { // No permitir eliminar superadmin (IdTipoUsuario = 1)
                        $stmt = $pdo->prepare("DELETE FROM usuario WHERE IdUsuario = ?");
                        if($stmt->execute([$idUsuario])) {
                            echo json_encode(['success' => true, 'message' => 'Usuario eliminado correctamente']);
                        } else {
                            echo json_encode(['success' => false, 'message' => 'Error al eliminar el usuario']);
                        }
                    } else {
                        echo json_encode(['success' => false, 'message' => 'No se puede eliminar este usuario (puede ser superadmin o no existir)']);
                    }
                } catch(PDOException $e) {
                    echo json_encode(['success' => false, 'message' => 'Error en la eliminación: ' . $e->getMessage()]);
                }
                break;

            default:
                echo json_encode(['error' => 'Acción POST no válida']);
                break;
        }
        break;

    default:
        // Método HTTP no permitido
        echo json_encode(['error' => 'Método no permitido']);
        break;
}
?>