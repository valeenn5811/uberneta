<?php
require 'header.php';
include 'config.php';

// Crear conexión usando las variables de config.php
$conn = new mysqli($servername, $username, $password, $dbname);

// Verificar conexión
if ($conn->connect_error) {
    die(json_encode(["success" => false, "error" => "Conexión fallida: " . $conn->connect_error]));
}

// Consulta para obtener solo los documentos del tablón (TipoDocumento = 'T')
$sql = "SELECT IdDocumento as id, TituloDocumento as titulo, DescripcionDocumento as descripcion, URLDocumento as archivo, FechaPublicacionDocumento as fecha_subida 
        FROM documentos 
        ORDER BY FechaPublicacionDocumento DESC";
$result = $conn->query($sql);

$documentos = [];
if ($result && $result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $documentos[] = [
            'id' => $row['id'],
            'titulo' => $row['titulo'],
            'descripcion' => $row['descripcion'],
            'archivo' => $row['archivo'],
            'fecha_subida' => $row['fecha_subida'],
        ];
    }
}

echo json_encode([
    'success' => true,
    'documentos' => $documentos
]);

$conn->close();
?>