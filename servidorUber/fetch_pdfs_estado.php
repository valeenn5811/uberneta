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

// Obtener el IdConductor desde la solicitud
$IdConductor = $_GET['idUsuario'] ?? null;

if (!$IdConductor) {
    die(json_encode(["error" => "IdConductor no proporcionado"]));
}

$sql = "SELECT IdDocumentoFactura, IdConductor, TituloDocumento, DescripcionDocumento, URLDocumento, FechaPublicacionDocumento, IdEstadoDocumento, ObservacionesFactura FROM documentosfacturas WHERE URLDocumento LIKE CONCAT('/uploads/facturas/', ?, '/%') AND IdConductor = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("si", $IdConductor, $IdConductor);
$stmt->execute();
$result = $stmt->get_result();

$documents = array();
if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        $documents[] = $row;
    }
}

// Imprimir los documentos para depuración
error_log(print_r($documents, true));

$conn->close();

header('Content-Type: application/json');
echo json_encode($documents);
?>
