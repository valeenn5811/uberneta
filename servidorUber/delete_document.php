<?php
require 'header.php';

error_reporting(E_ALL);
ini_set('display_errors', 1);

// Incluir el archivo de configuración de la base de datos
include 'config.php';

// Verificar si se ha recibido el ID del documento
if (!isset($_POST['documentId']) || empty($_POST['documentId'])) {
    error_log("Error: ID del documento no proporcionado");
    die(json_encode(['error' => 'ID del documento no proporcionado']));
}

$documentId = $_POST['documentId'] ?? $_GET['documentId'];
error_log("ID recibido: $documentId");

// Eliminar el documento de la base de datos
$sqlDelete = "DELETE FROM documentosfacturas WHERE IdDocumentoFactura = ?";
$stmtDelete = $conn->prepare($sqlDelete);
$stmtDelete->bind_param('i', $documentId);

if ($stmtDelete->execute()) {
    echo json_encode(['success' => 'Factura eliminada con éxito']);
    error_log("Documento eliminado correctamente: ID $documentId");
} else {
    echo json_encode(['error' => 'Error al eliminar el documento de la base de datos']);
    error_log("Error al eliminar el documento en la base de datos");
}

// Cerrar la conexión
$stmtDelete->close();
$conn->close();
?>
