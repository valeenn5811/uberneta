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

// Obtener el idUsuario desde la solicitud y validar
$idUsuario = isset($_GET['idUsuario']) ? intval($_GET['idUsuario']) : null;

if (!$idUsuario) {
    die(json_encode(["error" => "idUsuario no proporcionado o no válido"]));
}

// Modificar la consulta SQL para incluir IdEstadoDocumento en la selección
$sql = "SELECT TituloDocumento, DescripcionDocumento, FechaPublicacionDocumento, URLDocumento, IDUsuario, IdEstadoDocumento, AnioDocumento, TipoDocumento 
        FROM documentos 
        WHERE URLDocumento LIKE CONCAT('/uploads/', ?, '/%') AND IDUsuario = ? AND (IdEstadoDocumento = 3 OR IdEstadoDocumento = 0)";

$stmt = $conn->prepare($sql);
if ($stmt === false) {
    die(json_encode(["error" => "Error al preparar la consulta: " . $conn->error]));
}

$stmt->bind_param("ii", $idUsuario, $idUsuario);
$stmt->execute();
$result = $stmt->get_result();

if (!$result) {
    die(json_encode(["error" => "Error en la consulta: " . $conn->error]));
}

$descriptions_and_dates = array();
$other_data = array();

if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        $descriptions_and_dates[] = [
            'DescripcionDocumento' => $row['DescripcionDocumento'],
            'FechaPublicacionDocumento' => $row['FechaPublicacionDocumento']
        ];
        $other_data[] = [
            'TituloDocumento' => $row['TituloDocumento'],
            'URLDocumento' => $row['URLDocumento'],
            'IDUsuario' => $row['IDUsuario'],
            'IdEstadoDocumento' => $row['IdEstadoDocumento'],
            'AnioDocumento' => $row['AnioDocumento'],
            'TipoDocumento' => $row['TipoDocumento']
        ];
    }
}

// Imprimir los documentos para depuración
error_log(print_r($descriptions_and_dates, true));
error_log(print_r($other_data, true));

$stmt->close(); // Cerrar la declaración
$conn->close();

header('Content-Type: application/json');
echo json_encode([
    'descriptions_and_dates' => $descriptions_and_dates,
    'other_data' => $other_data
]);
?>