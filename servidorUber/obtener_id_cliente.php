<?php
require 'header.php';

header('Content-Type: application/json');

// Incluir el archivo de configuración
include 'config.php';

// Obtener el DNI desde la solicitud
$dni = isset($_GET['dni']) ? $conn->real_escape_string($_GET['dni']) : '';

if (empty($dni)) {
    echo json_encode(['error' => 'DNI no proporcionado']);
    exit;
}

// Consulta para obtener el idCliente
$sql = "SELECT IdCliente FROM clientes WHERE DNIUsuario = '$dni'";
$result = $conn->query($sql);

if ($result->num_rows > 0) {
    $row = $result->fetch_assoc();
    echo json_encode(['id_cliente' => $row['IdCliente']]);
} else {
    echo json_encode(['error' => 'Cliente no encontrado']);
}

// Cerrar la conexión
$conn->close();
?>