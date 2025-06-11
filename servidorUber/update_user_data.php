<?php
require 'header.php';

header('Content-Type: application/json');

// Mostrar todos los errores de PHP para depuración
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Incluir el archivo de configuración para la conexión a la base de datos
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

$dni = $data['dni'];
$nombre = $data['Nombre'];
$correo = $data['CorreoUsuario'];
$telefono = $data['TelefonoUsuario'];
$direccion = $data['Direccion'];
$provincia = $data['Provincia'];
$codigoPostal = $data['CodigoPostal'];

// Preparar la consulta SQL para actualizar los datos del usuario
$sql = "UPDATE usuario SET Nombre=?, CorreoUsuario=?, TelefonoUsuario=?, Direccion=?, Provincia=?, CodigoPostal=? WHERE DNIUsuario=?";

$stmt = $conn->prepare($sql);
if ($stmt === false) {
    die(json_encode(array("status" => "error", "message" => "Error en la preparación de la consulta SQL: " . $conn->error)));
}

$stmt->bind_param("sssssss", $nombre, $correo, $telefono, $direccion, $provincia, $codigoPostal, $dni);

if ($stmt->execute()) {
    echo json_encode(array("status" => "success", "message" => "Datos actualizados correctamente"));
} else {
    echo json_encode(array("status" => "error", "message" => "Error al actualizar los datos: " . $stmt->error));
}

// Cerrar la declaración y la conexión
$stmt->close();
$conn->close();
?>