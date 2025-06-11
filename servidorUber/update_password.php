<?php
require 'header.php';

// Incluir el archivo de configuración
require 'config.php';

// Conexión a la base de datos
$conn = new mysqli($servername, $username, $password, $dbname);

// Verificar la conexión
if ($conn->connect_error) {
    die("Conexión fallida: " . $conn->connect_error);
}

// Obtener la nueva contraseña y el IdUsuario desde la solicitud POST
$data = json_decode(file_get_contents("php://input"), true);
$newPassword = $data['newPassword'];
$idUsuario = $data['idUsuario']; // Asegúrate de que este dato se envíe desde Flutter

// Preparar la consulta para actualizar la contraseña
$sql = "UPDATE usuario SET Contrasena = ? WHERE IdUsuario = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("si", password_hash($newPassword, PASSWORD_BCRYPT), $idUsuario);

// Ejecutar la consulta y verificar el resultado
if ($stmt->execute()) {
    echo json_encode(["message" => "Contraseña actualizada con éxito"]);
} else {
    echo json_encode(["message" => "Error al actualizar la contraseña"]);
}

// Cerrar la declaración y la conexión
$stmt->close();
$conn->close();
?>