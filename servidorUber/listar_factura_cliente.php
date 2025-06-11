<?php
require 'header.php';

include 'config.php'; // Incluir el archivo de configuración

// Verificar conexión
if ($conn->connect_error) {
    die(json_encode(['error' => 'Error de conexión a la base de datos']));
}

// Obtener el idUsuarioCondcutor desde la solicitud
$idUsuarioConductor = $_GET['idUsuarioConductor'] ?? '';

// Validar que idUsuarioConductor sea un número
if (!is_numeric($idUsuarioConductor)) {
    echo json_encode(['error' => 'El parámetro idUsuarioConductor debe ser un número']);
    exit;
}

if (empty($idUsuarioConductor)) {
    echo json_encode(['error' => 'Falta el parámetro idUsuarioConductor']);
    exit;
}

// Consulta SQL para obtener las facturas del usuario, incluyendo los datos del cliente y del conductor
$sql = "SELECT f.IdFactura, f.IdCliente, f.IdUsuarioConductor, f.Precio, f.FechaFactura, f.RazonSocial, f.Enlace, f.ObservacionesFactura, f.IVA, f.Concepto,
        c.Nombre AS NombreCliente, c.TelefonoUsuario AS TelefonoCliente, c.DNIUsuario AS DNICliente, c.Direccion AS DireccionCliente, 
        c.Poblacion AS PoblacionCliente, c.Provincia AS ProvinciaCliente, c.CodigoPostal AS CodigoPostalCliente, c.CorreoUsuario AS CorreoCliente,
        u.Nombre AS NombreConductor, u.TelefonoUsuario AS TelefonoConductor, u.DNIUsuario AS DNIConductor, u.CorreoUsuario AS CorreoConductor, 
        u.Direccion AS DireccionConductor, u.Provincia AS ProvinciaConductor, u.CodigoPostal AS CodigoPostalConductor, u.CodUsuario AS CodUsuarioConductor
        FROM facturas f
        JOIN clientes c ON f.IdCliente = c.IdCliente
        JOIN usuario u ON f.IdUsuarioConductor = u.IdUsuario
        WHERE f.IdUsuarioConductor = ?";

$stmt = $conn->prepare($sql);

if ($stmt === false) {
    echo json_encode(['error' => 'Error al preparar la consulta SQL: ' . $conn->error]);
    exit;
}

mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

$stmt->bind_param('i', $idUsuarioConductor);
$stmt->execute();
$result = $stmt->get_result();

// Verificar si hay resultados
if ($result->num_rows > 0) {
    $facturas = [];
    while ($row = $result->fetch_assoc()) {
        // Eliminar la extensión .pdf del campo Enlace
        if (isset($row['Enlace'])) {
            $row['Enlace'] = preg_replace('/\.pdf$/i', '', $row['Enlace']);
        }
        $facturas[] = $row;
    }
    echo json_encode($facturas);
} else {
    echo json_encode([]);
}

// Cerrar conexión
$stmt->close();
$conn->close();
?>