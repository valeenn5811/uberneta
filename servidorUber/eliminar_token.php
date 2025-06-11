<?php
require 'header.php';

include 'config.php'; // Conexión a la base de datos

// Obtener los datos de la solicitud
$data = json_decode(file_get_contents("php://input"), true);

// Verificar que se haya enviado el DNI
if (isset($data['dni'])) {
    $dni = $data['dni'];

    // Consulta para eliminar el token del usuario con el DNI dado
    $query = "UPDATE usuario SET Token = NULL WHERE DNIUsuario = ?";
    $stmt = $conn->prepare($query);
    $stmt->bind_param("s", $dni);
    $stmt->execute();

    // Verificar si la actualización fue exitosa
    if ($stmt->affected_rows > 0) {
        echo json_encode(["status" => "success", "message" => "Token eliminado correctamente."]);
    } else {
        echo json_encode(["status" => "error", "message" => "No se pudo eliminar el token."]);
    }

    // Cerrar la conexión
    $stmt->close();
    $conn->close();
} else {
    // Si no se ha proporcionado el DNI
    echo json_encode(["status" => "error", "message" => "DNI no proporcionado."]);
}
?>
