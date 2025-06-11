<?php
require 'header.php';

// Incluir el archivo de configuración
include 'config.php';

// Verificar si se ha proporcionado el DNI
if (isset($_GET['dni'])) {
    $dni = $_GET['dni'];

    // Preparar la consulta SQL para obtener la razón social
    $stmt = $conn->prepare("SELECT Nombre FROM clientes WHERE DNIUsuario = ?");
    $stmt->bind_param("s", $dni);

    // Ejecutar la consulta
    $stmt->execute();
    $result = $stmt->get_result();

    // Verificar si se encontró un resultado
    if ($result->num_rows > 0) {
        $row = $result->fetch_assoc();
        echo json_encode(['razon_social' => $row['Nombre']]);
    } else {
        echo json_encode(['error' => 'No se encontró la razón social para el DNI proporcionado']);
    }

    // Cerrar la declaración
    $stmt->close();
} else {
    echo json_encode(['error' => 'DNI no proporcionado']);
}

// Cerrar la conexión
$conn->close();
?>