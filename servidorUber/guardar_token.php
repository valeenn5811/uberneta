<?php
require 'header.php';

include 'config.php'; // Incluir el archivo de configuración para la conexión a la base de datos

// Establecer el tipo de contenido a JSON
header('Content-Type: application/json');

// Obtener los datos enviados en el cuerpo de la solicitud
$data = json_decode(file_get_contents('php://input'), true);

// Verificar que se hayan recibido los datos necesarios
if (!isset($data['dni'])) {
    echo json_encode(['status' => 'error', 'message' => 'DNI no proporcionado']);
    exit;
}

$dni = $data['dni'];

// Si la acción es obtener el token
if (isset($data['accion']) && $data['accion'] === 'obtener_token') {
    $sql_select = "SELECT Token FROM usuario WHERE DNIUsuario = ?";
    $stmt_select = $conn->prepare($sql_select);

    if ($stmt_select === false) {
        echo json_encode(['status' => 'error', 'message' => 'Error en la preparación de la consulta: ' . $conn->error]);
        exit;
    }

    $stmt_select->bind_param('s', $dni);

    if ($stmt_select->execute()) {
        $result = $stmt_select->get_result();
        if ($result->num_rows > 0) {
            $row = $result->fetch_assoc();
            echo json_encode(['status' => 'success', 'token' => $row['Token']]);
        } else {
            echo json_encode(['status' => 'error', 'message' => 'Usuario no encontrado']);
        }
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Error al obtener el token: ' . $stmt_select->error]);
    }

    $stmt_select->close();
    $conn->close();
    exit;
}

// Si la acción es actualizar el token, verificamos que el token también esté presente
if (!isset($data['token'])) {
    echo json_encode(['status' => 'error', 'message' => 'Token no proporcionado']);
    exit;
}

$token = $data['token'];

// Verificar si el token ya está asignado a otro usuario
$sql_check = "SELECT DNIUsuario FROM usuario WHERE Token = ?";
$stmt_check = $conn->prepare($sql_check);

if ($stmt_check === false) {
    echo json_encode(['status' => 'error', 'message' => 'Error en la preparación de la consulta: ' . $conn->error]);
    exit;
}

$stmt_check->bind_param('s', $token);
$stmt_check->execute();
$result_check = $stmt_check->get_result();

if ($result_check->num_rows > 0) {
    $row = $result_check->fetch_assoc();
    $dni_existing = $row['DNIUsuario'];

    // Si el token está asignado a otro usuario, lo eliminamos
    if ($dni_existing !== $dni) {
        $sql_delete = "UPDATE usuario SET Token = NULL WHERE DNIUsuario = ?";
        $stmt_delete = $conn->prepare($sql_delete);

        if ($stmt_delete === false) {
            echo json_encode(['status' => 'error', 'message' => 'Error en la preparación de la consulta de eliminación: ' . $conn->error]);
            exit;
        }

        $stmt_delete->bind_param('s', $dni_existing);
        $stmt_delete->execute();
        $stmt_delete->close();
    }
}

$stmt_check->close();

// Preparar y ejecutar la consulta para actualizar el token del usuario actual
$sql_update = "UPDATE usuario SET Token = ? WHERE DNIUsuario = ?";
$stmt_update = $conn->prepare($sql_update);

if ($stmt_update === false) {
    echo json_encode(['status' => 'error', 'message' => 'Error en la preparación de la consulta: ' . $conn->error]);
    exit;
}

$stmt_update->bind_param('ss', $token, $dni);

if ($stmt_update->execute()) {
    echo json_encode(['status' => 'success', 'message' => 'Token actualizado correctamente']);
} else {
    echo json_encode(['status' => 'error', 'message' => 'Error al actualizar el token: ' . $stmt_update->error]);
}

// Cerrar las conexiones
$stmt_update->close();
$conn->close();
?>
