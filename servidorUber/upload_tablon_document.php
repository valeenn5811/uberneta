<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

require_once 'config.php';

// Crear conexión usando las variables de config.php
$conn = new mysqli($servername, $username, $password, $dbname);

// Verificar conexión
if ($conn->connect_error) {
    echo json_encode([
        "success" => false,
        "error" => "Conexión fallida: " . $conn->connect_error
    ]);
    exit;
}

// Verificar si el usuario es administrador
function verificarAdmin($admin_id) {
    global $conn;
    $stmt = $conn->prepare("SELECT IdTipoUsuario FROM usuarios WHERE IdUsuario = ?");
    $stmt->bind_param("i", $admin_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $row = $result->fetch_assoc();
    // Verificar si el usuario es Superadmin (1) o Admin (2)
    return $row && ($row['IdTipoUsuario'] == 1 || $row['IdTipoUsuario'] == 2);
}

// Validar datos recibidos
if (
    !isset($_POST['admin_id']) ||
    !isset($_POST['descripcionDocumento']) ||
    !isset($_FILES['file'])
) {
    echo json_encode(['success' => false, 'error' => 'Faltan datos']);
    exit;
}

$idUsuario = intval($_POST['admin_id']);
$descripcion = $conn->real_escape_string($_POST['descripcionDocumento']);

// Procesar archivo
$anio = date('Y');
$fecha = date('Y-m-d H:i:s');
$nombreArchivoOriginal = $_FILES['file']['name'];
$nombreArchivo = uniqid() . "_" . basename($nombreArchivoOriginal);
$rutaCarpeta = __DIR__ . "/uploads/todos/";
if (!file_exists($rutaCarpeta)) {
    mkdir($rutaCarpeta, 0777, true);
}
$rutaDestino = $rutaCarpeta . $nombreArchivo;
$urlDocumento = "/uploads/todos/" . $nombreArchivo;

if (!move_uploaded_file($_FILES['file']['tmp_name'], $rutaDestino)) {
    echo json_encode(['success' => false, 'error' => 'Error al guardar el archivo']);
    exit;
}

// Insertar en la base de datos
// TituloDocumento = nombre completo del archivo incluyendo el prefijo único
$sql = "INSERT INTO documentos 
    (IdUsuario, TituloDocumento, DescripcionDocumento, URLDocumento, FechaPublicacionDocumento, AnioDocumento, TipoDocumento, IdEstadoDocumento)
    VALUES (?, ?, ?, ?, ?, ?, '', 0)";

$stmt = $conn->prepare($sql);
$stmt->bind_param("issssi", $idUsuario, $nombreArchivo, $descripcion, $urlDocumento, $fecha, $anio);

if ($stmt->execute()) {
    echo json_encode(['success' => true, 'message' => 'Documento subido correctamente']);
} else {
    echo json_encode(['success' => false, 'error' => 'Error al insertar en la base de datos: ' . $stmt->error]);
}

$stmt->close();
$conn->close();
?>