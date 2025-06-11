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

// Obtener datos del POST
$idUsuario = $_POST['IdUsuario'];
$IdConductor = $_POST['IdConductor'];
$tituloDocumento = $_POST['TituloDocumento'];
$descripcionDocumento = $_POST['DescripcionDocumento'];
$urlDocumento = $_POST['URLDocumento'];
$fechaPublicacionDocumento = $_POST['FechaPublicacionDocumento'];
$idEstadoDocumento = $_POST['IdEstadoDocumento'];
$observacionesFactura = $_POST['ObservacionesFactura'];

// Establecer NULL si el campo observaciones está vacío
if (empty($observacionesFactura)) {
    $observacionesFactura = null;
}

// Preparar y ejecutar la consulta SQL
$sql = "INSERT INTO documentosfacturas (IdUsuario, IdConductor, TituloDocumento, DescripcionDocumento, URLDocumento, FechaPublicacionDocumento, IdEstadoDocumento, ObservacionesFactura)
VALUES (?, ?, ?, ?, ?, ?, ?, ?)";

$stmt = $conn->prepare($sql);
$stmt->bind_param("iissssis", $idUsuario, $IdConductor, $tituloDocumento, $descripcionDocumento, $urlDocumento, $fechaPublicacionDocumento, $idEstadoDocumento, $observacionesFactura);

if ($stmt->execute()) {
    echo "Registro insertado exitosamente";
} else {
    echo "Error: " . $sql . "<br>" . $conn->error;
}

// Cerrar conexión
$stmt->close();
$conn->close();
?>