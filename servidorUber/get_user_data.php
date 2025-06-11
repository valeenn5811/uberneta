<?php
require 'header.php';

header('Content-Type: application/json');

// Mostrar todos los errores de PHP para depuración
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Incluir el archivo de configuración
require 'config.php';

// Verificar la conexión a la base de datos
if ($conn->connect_error) {
    die(json_encode(array("status" => "error", "message" => "Connection failed: " . $conn->connect_error)));
}

// Obtener datos del POST
$data = json_decode(file_get_contents("php://input"), true);

// Verificar si los datos necesarios están presentes
if (!isset($data['dni'])) {
    die(json_encode(array("status" => "error", "message" => "Faltan datos")));
}

$dniUsuario = $data['dni'];

// Preparar la consulta SQL
$sql = "SELECT Nombre, CorreoUsuario, TelefonoUsuario, Direccion, Provincia, CodigoPostal FROM usuario WHERE DNIUsuario = ?";
$stmt = $conn->prepare($sql);

// Verificar si la preparación de la consulta falló
if (!$stmt) {
    die(json_encode(array("status" => "error", "message" => "Error en la consulta SQL: " . $conn->error)));
}

$stmt->bind_param("s", $dniUsuario);
$stmt->execute();
$result = $stmt->get_result();

// Verificar si hay algún resultado
if ($result->num_rows > 0) {
    // Usuario encontrado
    $user = $result->fetch_assoc(); // Obtener los datos del usuario

    // Enviar una respuesta de éxito con los datos del usuario
    echo json_encode(array(
        "status" => "success",
        "data" => $user
    ));
} else {
    // Usuario no encontrado
    echo json_encode(array("status" => "error", "message" => "Usuario no encontrado"));
}

// Cerrar la declaración y la conexión
$stmt->close();
$conn->close();
?>