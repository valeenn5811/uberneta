<?php
// Configuración de CORS y headers
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept');

// Manejar preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Evitar cualquier salida antes del JSON
ob_start();

// Incluir archivos necesarios
require_once 'config.php';
require_once 'vendor/autoload.php';

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;
use PHPMailer\PHPMailer\SMTP;

try {
    // Validar datos requeridos
    $required_fields = ['from', 'to', 'subject', 'text', 'pdf', 'filename', 
                       'smtp_host', 'smtp_port', 'smtp_secure', 'smtp_auth', 
                       'smtp_username', 'smtp_password'];
    
    foreach ($required_fields as $field) {
        if (!isset($_POST[$field]) || empty($_POST[$field])) {
            throw new Exception("Campo requerido faltante: $field");
        }
    }

    // Limpiar cualquier salida anterior
    ob_clean();
    
    $mail = new PHPMailer(true);
    
    // Configuración del servidor
    $mail->SMTPDebug = 0; // Desactivar debug para evitar salida no deseada
    $mail->isSMTP();
    $mail->Host = $_POST['smtp_host'];
    $mail->SMTPAuth = $_POST['smtp_auth'] === 'true';
    $mail->Username = $_POST['smtp_username'];
    $mail->Password = $_POST['smtp_password'];
    $mail->SMTPSecure = $_POST['smtp_secure'];
    $mail->Port = intval($_POST['smtp_port']);
    
    // Configuración SSL
    $mail->SMTPOptions = array(
        'ssl' => array(
            'verify_peer' => $_POST['verify_peer'] === 'true',
            'verify_peer_name' => $_POST['verify_peer_name'] === 'true',
            'allow_self_signed' => true
        )
    );

    // Configuración del correo
    $mail->setFrom($_POST['from']);
    
    // Validar y procesar destinatarios
    $to = json_decode($_POST['to'], true);
    if (!is_array($to)) {
        throw new Exception("Formato inválido de destinatarios");
    }
    
    foreach ($to as $recipient) {
        if (filter_var($recipient, FILTER_VALIDATE_EMAIL)) {
            $mail->addAddress($recipient);
        } else {
            throw new Exception("Email inválido: $recipient");
        }
    }
    
    $mail->Subject = $_POST['subject'];
    $mail->Body = $_POST['text'];
    
    // Validar y adjuntar PDF
    $pdf_data = base64_decode($_POST['pdf']);
    if ($pdf_data === false) {
        throw new Exception("Error al decodificar el PDF");
    }
    
    $mail->addStringAttachment(
        $pdf_data, 
        $_POST['filename'], 
        PHPMailer::ENCODING_BASE64, 
        'application/pdf'
    );

    // Enviar correo
    if (!$mail->send()) {
        throw new Exception("Error al enviar el correo: " . $mail->ErrorInfo);
    }
    
    // Limpiar cualquier salida antes de enviar la respuesta JSON
    ob_clean();
    
    // Respuesta exitosa
    echo json_encode([
        'success' => true,
        'message' => 'Correo enviado correctamente'
    ]);

} catch (Exception $e) {
    // Limpiar cualquier salida antes de enviar la respuesta JSON
    ob_clean();
    
    // Log del error
    error_log("Error en enviar_correo.php: " . $e->getMessage());
    
    // Respuesta de error
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => "Error al enviar el correo: " . $e->getMessage()
    ]);
}

// Asegurarse de que no haya más salida después del JSON
exit;
?>