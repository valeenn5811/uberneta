<?php
// Deshabilitar la visualización de errores
error_reporting(0);
ini_set('display_errors', 0);

// Configurar headers
header("Content-Type: application/json");
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Responder rápido si es una solicitud OPTIONS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require 'vendor/autoload.php';
use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

// Configuración de la base de datos
require 'config.php';

try {
    $input = json_decode(file_get_contents("php://input"), true);
    if (!isset($input['email'])) {
        throw new Exception("Falta el correo electrónico");
    }

    $email = $input['email'];

    // Buscar el usuario en la base de datos
    $sql = "SELECT IdUsuario FROM usuario WHERE CorreoUsuario = ?";
    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        throw new Exception("Error en la consulta SQL: " . $conn->error);
    }

    $stmt->bind_param("s", $email);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        $user = $result->fetch_assoc();
        $token = bin2hex(random_bytes(50)); // Genera un token aleatorio

        // Almacenar el token en la base de datos
        $expiry = date("Y-m-d H:i:s", strtotime('+1 hour')); // Expira en 1 hora
        $updateSql = "UPDATE usuario SET Recordatorio = ?, reset_expiry = ? WHERE IdUsuario = ?";
        $updateStmt = $conn->prepare($updateSql);
        if (!$updateStmt) {
            throw new Exception("Error al actualizar el token: " . $conn->error);
        }

        $updateStmt->bind_param("ssi", $token, $expiry, $user['IdUsuario']);
        $updateStmt->execute();

        // Configurar la URL base
        $url = "http://" . $_SERVER['HTTP_HOST'] . "/servidorUber";
        
        // Enviar el correo de recuperación
        $mail = new PHPMailer(true);
        try {
            $mail->isSMTP();
            $mail->Host = 'smtp.gmail.com';
            $mail->SMTPAuth = true;
            $mail->Username = 'vlopeztapiagomez@gmail.com';
            $mail->Password = 'ihbh tmef dwyq ykrm';
            $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
            $mail->Port = 587;
            
            // Configurar el certificado SSL
            $mail->SMTPOptions = array(
                'ssl' => array(
                    'verify_peer' => false,
                    'verify_peer_name' => false,
                    'allow_self_signed' => true
                )
            );

            $mail->setFrom('vlopeztapiagomez@gmail.com', 'Uberneta');
            $mail->addAddress($email);

            $mail->isHTML(true);
            $mail->Subject = '=?UTF-8?B?' . base64_encode('Recuperación de Contraseña') . '?=';
            $mail->Body    = "Haz clic en el siguiente enlace para recuperar tu contraseña: <a href='$url/reset_password.php?token=$token'>Restablecer Contraseña</a>";
            $mail->AltBody = "Haz clic en el siguiente enlace para recuperar tu contraseña: $url/reset_password.php?token=$token";

            $mail->send();
            echo json_encode(['status' => 'success', 'message' => 'Correo enviado']);
        } catch (Exception $e) {
            throw new Exception("El correo no pudo ser enviado. Error: {$mail->ErrorInfo}");
        }

        $updateStmt->close();
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Correo no encontrado']);
    }

    $stmt->close();
    $conn->close();
} catch (Exception $e) {
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
?>