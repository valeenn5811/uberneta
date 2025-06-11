<?php
require 'header.php';

include 'config.php';
require 'vendor/autoload.php';
use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $inputPassword = $_POST['password'];
    $userId = $_POST['user_id'];

    // Verificar que se recibieron los datos correctamente
    if (empty($inputPassword) || empty($userId)) {
        echo json_encode(['success' => false, 'error' => 'Datos incompletos']);
        exit;
    }

    // Preparar la consulta SQL para obtener la contraseña y otros datos del usuario
    $stmt = $conn->prepare("SELECT Contrasena, Nombre, DNIUsuario, CorreoUsuario, TelefonoUsuario FROM usuario WHERE IdUsuario = ?");
    $stmt->bind_param("i", $userId);
    $stmt->execute();
    $stmt->bind_result($storedPassword, $nombre, $dni, $correo, $telefono);
    $stmt->fetch();
    $stmt->close();

    // Verificar la contraseña
    if (password_verify($inputPassword, $storedPassword)) {
        $mail = new PHPMailer(true);

        try {
            // Configuración del servidor SMTP
            $mail->isSMTP();
            $mail->Host = 'smtp.gmail.com';
            $mail->SMTPAuth = true;
            $mail->Username = 'vlopeztapiagomez@gmail.com'; 
            $mail->Password = 'ihbh tmef dwyq ykrm'; 
            $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
            // Opciones para deshabilitar la verificación SSL (SOLO PARA PRUEBAS)
            $mail->SMTPOptions = array(
                'ssl' => array(
                    'verify_peer' => false,
                    'verify_peer_name' => false,
                    'allow_self_signed' => true
                )
            );
            $mail->Port = 587;

            // Remitente y destinatario
            $mail->setFrom('vlopeztapiagomez@gmail.com', 'Uberneta');
            $mail->addAddress('valeenn811@gmail.com');

            // Contenido del correo
            $mail->CharSet = 'UTF-8';
            $mail->isHTML(true);
            $mail->Subject = 'Solicitud de eliminación de cuenta de Uberneta';
            $mail->Body = "
                <p>El usuario con los siguientes detalles ha solicitado eliminar su cuenta:</p>
                <ul>
                    <li><strong>ID:</strong> $userId</li>
                    <li><strong>Nombre:</strong> $nombre</li>
                    <li><strong>DNI:</strong> $dni</li>
                    <li><strong>Correo:</strong> $correo</li>
                    <li><strong>Teléfono:</strong> $telefono</li>
                </ul>
            ";

            // Enviar correo
            $mail->send();
            echo json_encode(['success' => true]);
        } catch (Exception $e) {
            echo json_encode(['success' => false, 'error' => 'No se pudo enviar el correo. Error: ' . $mail->ErrorInfo]);
        }
    } else {
        echo json_encode(['success' => false, 'error' => 'Contraseña incorrecta']);
    }
}
?>