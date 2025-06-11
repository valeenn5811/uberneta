<?php
// Asegurarnos de que no haya salida antes de los headers
ob_start();

header('Content-Type: application/json');
ini_set('display_errors', 0); // Desactivar la salida de errores
error_reporting(E_ALL);

// Incluir el archivo de configuración de la base de datos
include 'config.php';
require 'header.php';

// Función para enviar respuesta JSON y terminar
function sendJsonResponse($success, $message) {
    ob_clean(); // Limpiar cualquier salida anterior
    echo json_encode([
        'success' => $success,
        'message' => $message
    ]);
    exit;
}

// Crear conexión usando las variables de config.php
$conn = new mysqli($servername, $username, $password, $dbname);

// Verificar conexión
if ($conn->connect_error) {
    sendJsonResponse(false, "Conexión fallida: " . $conn->connect_error);
}

// Verificar que los parámetros necesarios existen
if (!isset($_POST['idFactura']) || !isset($_POST['nuevoEstado'])) {
    sendJsonResponse(false, "Parámetros incompletos.");
}

$idFactura = $_POST['idFactura'];
$nuevoEstado = (int)$_POST['nuevoEstado'];
$observaciones = isset($_POST['observaciones']) ? $_POST['observaciones'] : null;

// Validar el nuevo estado
if (!in_array($nuevoEstado, [2, 3, 4])) {
    sendJsonResponse(false, "Estado inválido.");
}

// Iniciar una transacción para asegurar que las operaciones se completen juntas
$conn->begin_transaction();

try {
    if ($nuevoEstado == 3) {
        // --- Lógica para estado Aceptado (3) ---
        // (Esta parte no necesita cambios según tu último requerimiento)

        // 1. Seleccionar los datos de la factura a mover
        // Incluimos IdConductor que se mapeará a IdUsuario en la tabla documentos
        $sql_select = "SELECT IdConductor, TituloDocumento, DescripcionDocumento, URLDocumento, FechaPublicacionDocumento FROM documentosfacturas WHERE IdDocumentoFactura = ?";
        $stmt_select = $conn->prepare($sql_select);
        $stmt_select->bind_param("i", $idFactura);
        $stmt_select->execute();
        $result_select = $stmt_select->get_result();

        if ($result_select->num_rows == 0) {
            throw new Exception("Factura no encontrada.");
        }

        $factura_data = $result_select->fetch_assoc();
        $IdConductor = $factura_data['IdConductor']; // Este será IdUsuario en la tabla documentos
        $tituloDocumento = $factura_data['TituloDocumento'];
        $descripcionDocumento = $factura_data['DescripcionDocumento'];
        $urlDocumento = $factura_data['URLDocumento'];
        $fechaPublicacion = $factura_data['FechaPublicacionDocumento'];

        $stmt_select->close();

        // Calcular AnioDocumento
        $anioDocumento = date('Y', strtotime($fechaPublicacion));

        // 2. Mover el archivo PDF
        $old_path_relative = $urlDocumento; // e.g., /uploads/facturas/3/archivo.pdf
        // Asegúrate de que __DIR__ apunte a la raíz de tu servidor o ajusta la ruta
        $old_path_absolute = __DIR__ . $old_path_relative; // Construir ruta absoluta en el servidor

        // Construir nueva ruta relativa
        $file_name = basename($old_path_relative); // Obtener solo el nombre del archivo
        $new_path_relative = "/uploads/" . $IdConductor . "/" . $file_name;
        $new_path_absolute = __DIR__ . $new_path_relative;

        // Asegurarse de que el directorio de destino exista
        $new_directory = dirname($new_path_absolute);
        if (!is_dir($new_directory)) {
            // 0755 o 0775 suelen ser permisos más seguros que 0777
            if (!mkdir($new_directory, 0755, true)) {
                 throw new Exception("Error al crear el directorio de destino: " . $new_directory);
            }
        }

        // Verificar si el archivo original existe antes de intentar moverlo
        if (!file_exists($old_path_absolute)) {
             // Puedes decidir si esto es un error fatal o si se puede continuar
             // Por ahora, lo tratamos como error para no insertar un registro sin archivo
             throw new Exception("El archivo PDF original no existe: " . $old_path_absolute);
        }


        if (!rename($old_path_absolute, $new_path_absolute)) {
            throw new Exception("Error al mover el archivo PDF. Verifica permisos y rutas.");
        }

        // 3. Insertar en la tabla documentos
        // Asumo un valor específico para TipoDocumento para identificar facturas contabilizadas.
        // *** NECESITAS CAMBIAR 'F' POR EL VALOR CORRECTO EN TU BASE DE DATOS ***
        $tipoDocumento = 'F'; // <-- **AJUSTA ESTE VALOR**

        $sql_insert = "INSERT INTO documentos (IdUsuario, TituloDocumento, DescripcionDocumento, URLDocumento, FechaPublicacionDocumento, AnioDocumento, TipoDocumento, IdEstadoDocumento) VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
        $stmt_insert = $conn->prepare($sql_insert);
        // Para las facturas contabilizadas en la tabla documentos, el IdEstadoDocumento podría ser diferente,
        // o quizás uses el mismo sistema de estados que documentosfacturas.
        // Aquí, asumiré que el estado en la tabla documentos podría ser 3 (aceptado/contabilizado)
        // **AJUSTA ESTE VALOR SI ES NECESARIO**
        $idEstadoDocumentoDocumentos = 3;

        $stmt_insert->bind_param("issssssi", $IdConductor, $tituloDocumento, $descripcionDocumento, $new_path_relative, $fechaPublicacion, $anioDocumento, $tipoDocumento, $idEstadoDocumentoDocumentos);

        if (!$stmt_insert->execute()) {
            throw new Exception("Error al insertar en documentos: " . $stmt_insert->error);
        }
        $stmt_insert->close();

        // 4. Eliminar de la tabla documentosfacturas
        $sql_delete = "DELETE FROM documentosfacturas WHERE IdDocumentoFactura = ?";
        $stmt_delete = $conn->prepare($sql_delete);
        $stmt_delete->bind_param("i", $idFactura);
         if (!$stmt_delete->execute()) {
            throw new Exception("Error al eliminar de documentosfacturas: " . $stmt_delete->error);
        }
        $stmt_delete->close();


    } else {
        // --- Lógica para estados Leido (2) o Rechazado (4) ---

        // Base de la consulta de actualización
        $sql_update = "UPDATE documentosfacturas SET IdEstadoDocumento = ?";
        $params = [$nuevoEstado]; // Array para los parámetros de bind

        // Si el estado es 4 (Rechazado) y se recibieron observaciones, añadirlas a la consulta
        if ($nuevoEstado == 4 && $observaciones !== null) {
            $sql_update .= ", ObservacionesFactura = ?";
            $params[] = $observaciones;
        }

        $sql_update .= " WHERE IdDocumentoFactura = ?";
        $params[] = $idFactura;

        $stmt_update = $conn->prepare($sql_update);

        // Determinar el string de tipos para bind_param
        $types = 'i'; // Para IdEstadoDocumento
        if ($nuevoEstado == 4 && $observaciones !== null) {
            $types .= 's'; // Para ObservacionesFactura (string)
        }
        $types .= 'i'; // Para IdDocumentoFactura

        // Llamar a bind_param usando call_user_func_array para manejar el número variable de parámetros
        call_user_func_array([$stmt_update, 'bind_param'], array_merge([$types], $params));


        if (!$stmt_update->execute()) {
            throw new Exception("Error al actualizar el estado/observaciones: " . $stmt_update->error);
        }
        $stmt_update->close();
    }

    // Confirmar la transacción
    $conn->commit();
    sendJsonResponse(true, "Estado actualizado correctamente.");

} catch (Exception $e) {
    // Revertir la transacción en caso de error
    $conn->rollback();

    // Considera añadir logging detallado en producción para depurar errores
    // error_log("Error en actualizar_estado_factura.php: " . $e->getMessage());

    sendJsonResponse(false, "Error en la operación: " . $e->getMessage());

} finally {
    // Cerrar la conexión
    if ($conn) {
        $conn->close();
    }
}

?>