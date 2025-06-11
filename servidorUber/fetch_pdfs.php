<?php
require 'header.php';

// Incluir el archivo de configuración
include 'config.php';

// Crear conexión usando las variables de config.php
$conn = new mysqli($servername, $username, $password, $dbname);

// Verificar conexión
if ($conn->connect_error) {
    die(json_encode(["error" => "Conexión fallida: " . $conn->connect_error]));
}

// Modificar la consulta para incluir AnioDocumento
$sql = "SELECT TituloDocumento, DescripcionDocumento, FechaPublicacionDocumento, URLDocumento, AnioDocumento FROM documentos WHERE URLDocumento LIKE '/uploads/todos/%'";
$result = $conn->query($sql);

if (!$result) {
    die(json_encode(["error" => "Error en la consulta: " . $conn->error]));
}

$documentsByYear = array();
if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        $anio = $row['AnioDocumento'];
        if (!isset($documentsByYear[$anio])) {
            $documentsByYear[$anio] = array();
        }
        $documentsByYear[$anio][] = $row;
    }
}

// Imprimir los documentos para depuración
error_log(print_r($documentsByYear, true));

$conn->close();

// Asegurarse de que siempre se devuelve un objeto, incluso si está vacío
if (empty($documentsByYear)) {
    $documentsByYear = new stdClass();
}

header('Content-Type: application/json');
echo json_encode($documentsByYear);
?>