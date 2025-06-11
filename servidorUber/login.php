<?php
require 'header.php';

header('Content-Type: application/json');
// Mostrar todos los errores de PHP para depuración
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Incluir el archivo de configuración
require 'config.php';

// Iniciar sesión
session_start();

// Verificar la conexión a la base de datos
if ($conn->connect_error) {
    die(json_encode(array("status" => "error", "message" => "Connection failed: " . $conn->connect_error)));
}

// Obtener datos del POST
$data = json_decode(file_get_contents("php://input"), true);

// Verificar si los datos necesarios están presentes
if (!isset($data['dni']) || !isset($data['password'])) {
    die(json_encode(array("status" => "error", "message" => "Faltan datos")));
}

$dniUsuario = $data['dni'];
$contrasena = $data['password'];

// Preparar la consulta SQL para obtener la contraseña hasheada
$sql = "SELECT DNIUsuario, Nombre, CorreoUsuario, IdUsuario, Contrasena, CodUsuario, Token, IdTipoUsuario FROM usuario WHERE DNIUsuario = ?";
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
    $user = $result->fetch_assoc(); // Obtener los datos del usuario
    $hashedPasswordFromDB = $user['Contrasena'];

    // Verificar la contraseña ingresada con la hasheada
    if (password_verify($contrasena, $hashedPasswordFromDB)) {
        // Usuario autenticado correctamente
        $_SESSION['dni'] = $dniUsuario;

        // Enviar una respuesta de éxito con los datos del usuario y la contraseña original
        echo json_encode(array(
            "status" => "success",
            "dni" => $user['DNIUsuario'],
            "nombre" => $user['Nombre'], 
            "correo" => $user['CorreoUsuario'], 
            "id" => $user['IdUsuario'],
            "licencia" => $user['CodUsuario'],
            "token" => $user['Token'],
            "contrasena" => $contrasena, // Añadir la contraseña original
            "idTipoUsuario" => $user['IdTipoUsuario']
        ));
    } else {
        // Credenciales incorrectas
        echo json_encode(array("status" => "error", "message" => "Credenciales incorrectas"));
    }
} else {
    // Credenciales incorrectas
    echo json_encode(array("status" => "error", "message" => "Credenciales incorrectas"));
}

// Cerrar la declaración y la conexión
$stmt->close();
$conn->close();
?>
