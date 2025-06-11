<?php
require 'header.php';

// Ruta base donde se guardarán los archivos
$baseDir = "C:/xampp/htdocs/servidorUber/uploads/facturas/";

// Obtener el idUsuario y el nombre del archivo desde el formulario
$idUsuario = isset($_POST['userId']) ? $_POST['userId'] : null;
$fileName = isset($_POST['fileName']) ? $_POST['fileName'] : null;

// Verificar si se recibió el archivo y el idUsuario
if (isset($_FILES['file']) && $idUsuario && $fileName) {
    // Crear la carpeta del usuario si no existe
    $userDir = $baseDir . $idUsuario . "/";
    if (!file_exists($userDir)) {
        if (!mkdir($userDir, 0777, true)) {
            http_response_code(500);
            echo "No se pudo crear la carpeta del usuario.";
            exit;
        }
    }

    // Ruta final del archivo
    $targetFile = $userDir . basename($fileName);

    // Mover el archivo subido a la carpeta del usuario
    if (move_uploaded_file($_FILES['file']['tmp_name'], $targetFile)) {
        echo "Archivo subido correctamente.";
    } else {
        http_response_code(500);
        echo "Error al mover el archivo.";
    }
} else {
    http_response_code(400);
    echo "No se recibió el archivo, el idUsuario o el nombre del archivo.";
}
?>