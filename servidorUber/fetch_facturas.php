<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);
header('Content-Type: application/json');

require 'header.php';

// Incluir el archivo de configuración
include 'config.php';

// Crear conexión usando las variables de config.php
$conn = new mysqli($servername, $username, $password, $dbname);

// Verificar conexión
if ($conn->connect_error) {
    echo json_encode(["error" => "Conexión fallida: " . $conn->connect_error]);
    exit;
}

// Consulta SQL para obtener todas las facturas
$sql = "SELECT 
            df.IdDocumentoFactura,
            df.IdUsuario,
            df.IdConductor,
            u.IdUsuario AS IdConductor,
            df.TituloDocumento,
            df.DescripcionDocumento,
            df.URLDocumento,
            df.FechaPublicacionDocumento,
            df.IdEstadoDocumento,
            df.ObservacionesFactura
        FROM documentosfacturas df
        LEFT JOIN usuario u ON df.IdConductor = u.IdUsuario
        WHERE df.URLDocumento LIKE '/uploads/facturas/%'
        ORDER BY df.FechaPublicacionDocumento DESC";

$result = $conn->query($sql);

if (!$result) {
    echo json_encode(["error" => "Error en la consulta: " . $conn->error]);
    $conn->close();
    exit;
}

$facturas = array();
if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        $facturas[] = $row;
    }
}

// Imprimir las facturas para depuración
error_log(print_r($facturas, true));

$conn->close();
echo json_encode($facturas);
?> 