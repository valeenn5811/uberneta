<?php
// Establecer los headers antes de cualquier salida
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

// Activar el reporte de errores para debugging
ini_set('display_errors', 1);
error_reporting(E_ALL);

// Incluir el archivo de configuración
require_once 'config.php';

// Función para enviar respuesta JSON y terminar la ejecución
function sendJsonResponse($data) {
    echo json_encode($data, JSON_UNESCAPED_UNICODE);
    exit;
}

// Función para manejar errores de PHP
function handleError($errno, $errstr, $errfile, $errline) {
    error_log("Error [$errno] $errstr en $errfile:$errline");
    sendJsonResponse(['error' => 'Error interno del servidor: ' . $errstr]);
    return true;
}

// Establecer el manejador de errores
set_error_handler('handleError');

// Verificar si es una solicitud POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendJsonResponse(['error' => 'Método no permitido']);
}

// Obtener el valor del IVA desde la tabla de opciones
$iva = null;
$sqlIva = "SELECT value FROM options WHERE `group` = ? AND item = ?";
$stmtIva = $conn->prepare($sqlIva);

if ($stmtIva === false) {
    error_log("Error al preparar la consulta del IVA: " . $conn->error);
    sendJsonResponse(['error' => 'Error al preparar la consulta del IVA: ' . $conn->error]);
}

$grupo = 'opc';
$item = 'iva';
$stmtIva->bind_param("ss", $grupo, $item);

if (!$stmtIva->execute()) {
    error_log("Error al ejecutar la consulta del IVA: " . $stmtIva->error);
    sendJsonResponse(['error' => 'Error al ejecutar la consulta del IVA: ' . $stmtIva->error]);
}

$resultIva = $stmtIva->get_result();

if ($resultIva === false) {
    error_log("Error al obtener el resultado del IVA: " . $conn->error);
    sendJsonResponse(['error' => 'Error al obtener el resultado del IVA: ' . $conn->error]);
}

if ($resultIva->num_rows > 0) {
    $row = $resultIva->fetch_assoc();
    $iva = $row['value'];
} else {
    // Si no se encuentra el IVA, usar un valor por defecto
    $iva = 21; // IVA por defecto del 21%
}

$stmtIva->close();

// Verificar si se recibieron todos los datos necesarios
if (!isset($_POST['idCliente'], $_POST['fechaFactura'], $_POST['idUsuarioConductor'], 
    $_POST['concepto'], $_POST['razonSocial'], $_POST['observacionesFactura'], 
    $_POST['precio'], $_POST['enlace'])) {
    sendJsonResponse(['error' => 'Datos incompletos']);
}

$idCliente = $_POST['idCliente'];
$fechaFactura = $_POST['fechaFactura'];
$idUsuarioConductor = $_POST['idUsuarioConductor'];
$concepto = $_POST['concepto'];
$razonSocial = $_POST['razonSocial'];
$observacionesFactura = $_POST['observacionesFactura'];
$precio = $_POST['precio'];
$enlace = $_POST['enlace'];

// Verificar si el concepto es "Abono" y hacer el precio negativo
if ($concepto === 'Abono') {
    $precio = -abs($precio);
}

try {
    // Obtener el número máximo de factura para el usuario, concepto y razón social especificados
    $maximo = null;
    $sqlMaximo = "SELECT MAX(CAST(NumeroFactura AS UNSIGNED)) AS maximo FROM facturas WHERE IdUsuarioConductor = ? AND Concepto = ?";
    $stmtMaximo = $conn->prepare($sqlMaximo);
    
    if ($stmtMaximo === false) {
        error_log("Error al preparar la consulta de máximo: " . $conn->error);
        sendJsonResponse(['error' => 'Error al preparar la consulta de máximo: ' . $conn->error]);
    }
    
    $stmtMaximo->bind_param("is", $idUsuarioConductor, $concepto);
    
    if (!$stmtMaximo->execute()) {
        error_log("Error al ejecutar la consulta de máximo: " . $stmtMaximo->error);
        sendJsonResponse(['error' => 'Error al ejecutar la consulta de máximo: ' . $stmtMaximo->error]);
    }
    
    $resultMaximo = $stmtMaximo->get_result();

    if ($resultMaximo === false) {
        error_log("Error al obtener el resultado de máximo: " . $conn->error);
        sendJsonResponse(['error' => 'Error al obtener el resultado de máximo: ' . $conn->error]);
    }

    if ($resultMaximo->num_rows > 0) {
        $rowMaximo = $resultMaximo->fetch_assoc();
        $maximo = $rowMaximo['maximo'];
    }

    $numeroFactura = $maximo ? str_pad(intval($maximo) + 1, 4, '0', STR_PAD_LEFT) : '0001';
    $stmtMaximo->close();

    // Obtener el código de usuario desde la tabla usuario
    $codigoUsuario = null;
    $sqlCodigoUsuario = "SELECT CodUsuario FROM usuario WHERE IdUsuario = ?";
    $stmtCodigoUsuario = $conn->prepare($sqlCodigoUsuario);
    
    if ($stmtCodigoUsuario === false) {
        error_log("Error al preparar la consulta de código usuario: " . $conn->error);
        sendJsonResponse(['error' => 'Error al preparar la consulta de código usuario: ' . $conn->error]);
    }
    
    $stmtCodigoUsuario->bind_param("i", $idUsuarioConductor);
    
    if (!$stmtCodigoUsuario->execute()) {
        error_log("Error al ejecutar la consulta de código usuario: " . $stmtCodigoUsuario->error);
        sendJsonResponse(['error' => 'Error al ejecutar la consulta de código usuario: ' . $stmtCodigoUsuario->error]);
    }
    
    $resultCodigoUsuario = $stmtCodigoUsuario->get_result();

    if ($resultCodigoUsuario === false) {
        error_log("Error al obtener el resultado de código usuario: " . $conn->error);
        sendJsonResponse(['error' => 'Error al obtener el resultado de código usuario: ' . $conn->error]);
    }

    if ($resultCodigoUsuario->num_rows > 0) {
        $rowCodigoUsuario = $resultCodigoUsuario->fetch_assoc();
        $codigoUsuario = $rowCodigoUsuario['CodUsuario'];
    } else {
        sendJsonResponse(['error' => 'No se pudo obtener el código de usuario']);
    }

    $stmtCodigoUsuario->close();

    // Construir el nombre del archivo PDF
    $anio = date('Y', strtotime($fechaFactura));
    $codigoUsuarioPadded = str_pad($codigoUsuario, 4, '0', STR_PAD_LEFT);
    $nombreArchivoPDF = ($concepto === 'Abono') 
        ? 'AB' . $anio . '-' . $codigoUsuarioPadded . '-' . $numeroFactura . '.pdf'
        : $anio . '-' . $codigoUsuarioPadded . '-' . $numeroFactura . '.pdf';

    // Preparar y ejecutar la consulta de inserción
    $sql = "INSERT INTO facturas (IdCliente, FechaFactura, NumeroFactura, IdUsuarioConductor, Concepto, RazonSocial, ObservacionesFactura, Precio, IVA, Enlace) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
    $stmt = $conn->prepare($sql);
    
    if ($stmt === false) {
        error_log("Error al preparar la consulta de inserción: " . $conn->error);
        sendJsonResponse(['error' => 'Error al preparar la consulta de inserción: ' . $conn->error]);
    }
    
    $stmt->bind_param("ississsdis", $idCliente, $fechaFactura, $numeroFactura, $idUsuarioConductor, $concepto, $razonSocial, $observacionesFactura, $precio, $iva, $nombreArchivoPDF);

    if (!$stmt->execute()) {
        error_log("Error al insertar la factura: " . $stmt->error);
        sendJsonResponse(['error' => 'Error al insertar la factura: ' . $stmt->error]);
    }

    // Obtener la información de la factura recién insertada
    $facturaId = $stmt->insert_id;
    $sqlFactura = "SELECT IdFactura, IdCliente, FechaFactura, NumeroFactura, IdUsuarioConductor, Concepto, RazonSocial, ObservacionesFactura, Precio, IVA, Enlace FROM facturas WHERE IdFactura = ?";
    $stmtFactura = $conn->prepare($sqlFactura);
    
    if ($stmtFactura === false) {
        error_log("Error al preparar la consulta de factura: " . $conn->error);
        sendJsonResponse(['error' => 'Error al preparar la consulta de factura: ' . $conn->error]);
    }
    
    $stmtFactura->bind_param("i", $facturaId);
    
    if (!$stmtFactura->execute()) {
        error_log("Error al ejecutar la consulta de factura: " . $stmtFactura->error);
        sendJsonResponse(['error' => 'Error al ejecutar la consulta de factura: ' . $stmtFactura->error]);
    }
    
    $resultFactura = $stmtFactura->get_result();

    if ($resultFactura === false) {
        error_log("Error al obtener el resultado de factura: " . $conn->error);
        sendJsonResponse(['error' => 'Error al obtener el resultado de factura: ' . $conn->error]);
    }

    $facturaInfo = $resultFactura->fetch_assoc();

    // Obtener la información del Conductor
    $sqlConductor = "SELECT IdUsuario, Nombre, IdTipoUsuario, TelefonoUsuario, DNIUsuario, CorreoUsuario, IdEmpresa, CodUsuario, Direccion, Provincia, CodigoPostal FROM usuario WHERE IdUsuario = ?";
    $stmtConductor = $conn->prepare($sqlConductor);
    
    if ($stmtConductor === false) {
        error_log("Error al preparar la consulta de conductor: " . $conn->error);
        sendJsonResponse(['error' => 'Error al preparar la consulta de conductor: ' . $conn->error]);
    }
    
    $stmtConductor->bind_param("i", $idUsuarioConductor);
    
    if (!$stmtConductor->execute()) {
        error_log("Error al ejecutar la consulta de conductor: " . $stmtConductor->error);
        sendJsonResponse(['error' => 'Error al ejecutar la consulta de conductor: ' . $stmtConductor->error]);
    }
    
    $resultConductor = $stmtConductor->get_result();

    if ($resultConductor === false) {
        error_log("Error al obtener el resultado de conductor: " . $conn->error);
        sendJsonResponse(['error' => 'Error al obtener el resultado de conductor: ' . $conn->error]);
    }

    $conductorInfo = $resultConductor->fetch_assoc();

    // Obtener la información del cliente
    $sqlCliente = "SELECT IdCliente, Nombre, IdTipoUsuario, TelefonoUsuario, DNIUsuario, Direccion, Poblacion, Provincia, CodigoPostal, CorreoUsuario FROM clientes WHERE IdCliente = ?";
    $stmtCliente = $conn->prepare($sqlCliente);
    
    if ($stmtCliente === false) {
        error_log("Error al preparar la consulta de cliente: " . $conn->error);
        sendJsonResponse(['error' => 'Error al preparar la consulta de cliente: ' . $conn->error]);
    }
    
    $stmtCliente->bind_param("i", $idCliente);
    
    if (!$stmtCliente->execute()) {
        error_log("Error al ejecutar la consulta de cliente: " . $stmtCliente->error);
        sendJsonResponse(['error' => 'Error al ejecutar la consulta de cliente: ' . $stmtCliente->error]);
    }
    
    $resultCliente = $stmtCliente->get_result();

    if ($resultCliente === false) {
        error_log("Error al obtener el resultado de cliente: " . $conn->error);
        sendJsonResponse(['error' => 'Error al obtener el resultado de cliente: ' . $conn->error]);
    }

    $clienteInfo = $resultCliente->fetch_assoc();

    // Cerrar todas las conexiones
    $stmtFactura->close();
    $stmtConductor->close();
    $stmtCliente->close();
    $stmt->close();
    $conn->close();

    // Enviar respuesta exitosa
    sendJsonResponse([
        'success' => 'Factura insertada con éxito',
        'factura' => $facturaInfo,
        'conductor' => $conductorInfo,
        'cliente' => $clienteInfo
    ]);

} catch (Exception $e) {
    error_log("Error en el servidor: " . $e->getMessage());
    sendJsonResponse(['error' => 'Error en el servidor: ' . $e->getMessage()]);
}
?>