<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

// Incluir el archivo de configuración de la base de datos
require_once 'config.php';

// Verificar si es una solicitud POST
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Obtener los datos del POST
    $nombre = $_POST['nombre'] ?? '';
    $dni = $_POST['dni'] ?? '';
    $correo = $_POST['correo'] ?? '';

    // Validar que los campos no estén vacíos
    if (empty($nombre) || empty($dni) || empty($correo)) {
        echo json_encode([
            'success' => false,
            'message' => 'Todos los campos son obligatorios'
        ]);
        exit;
    }

    try {
        // Verificar si el cliente ya existe
        $stmt = $conn->prepare("SELECT IdCliente FROM clientes WHERE DNIUsuario = ?");
        $stmt->bind_param("s", $dni);
        $stmt->execute();
        $result = $stmt->get_result();

        if ($result->num_rows > 0) {
            echo json_encode([
                'success' => false,
                'message' => 'El cliente ya existe'
            ]);
            exit;
        }

        
        // Insertar el nuevo cliente
        $stmt = $conn->prepare("INSERT INTO clientes (Nombre, DNIUsuario, CorreoUsuario, IdTipoUsuario, IdEmpresa, EstadoUsuario) VALUES (?, ?, ?, 4, 1, 1)");
        $stmt->bind_param("sss", $nombre, $dni, $correo);
                
        if ($stmt->execute()) {
            echo json_encode([
                'success' => true,
                'message' => 'Cliente dado de alta correctamente'
            ]);
        } else {
            echo json_encode([
                'success' => false,
                'message' => 'Error al dar de alta el cliente'
            ]);
        }
    } catch (Exception $e) {
        echo json_encode([
            'success' => false,
            'message' => 'Error en el servidor: ' . $e->getMessage()
        ]);
    }
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Método no permitido'
    ]);
}
?>