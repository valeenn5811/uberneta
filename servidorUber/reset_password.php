<?php
    require 'header.php';

    // No enviar Content-Type JSON si es una solicitud GET para mostrar HTML
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        header("Content-Type: application/json");
    }

    // Responder rápido si es una solicitud OPTIONS
    if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
        http_response_code(200);
        exit();
    }

    require 'config.php';

    // Registro de depuración
    error_log("Método de solicitud: " . $_SERVER['REQUEST_METHOD']);
    error_log("Token recibido: " . (isset($_GET['token']) ? $_GET['token'] : 'No token'));

    if ($_SERVER['REQUEST_METHOD'] == 'GET' && isset($_GET['token'])) {
        $token = $_GET['token'];

        // Verificar si el token es válido y no ha expirado
        $sql = "SELECT IdUsuario FROM usuario WHERE Recordatorio = ? AND reset_expiry > NOW()";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("s", $token);
        $stmt->execute();
        $result = $stmt->get_result();

        if ($result->num_rows > 0) {
            // Mostrar formulario para ingresar nueva contraseña con estilos CSS
            echo '<!DOCTYPE html>
            <html lang="es">
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>Restablecer Contraseña</title>
                <style>
                        body {
                            font-family: Arial, sans-serif;
                            background-color: #f4f4f9;
                            display: flex;
                            justify-content: center;
                            align-items: center;
                            height: 100vh;
                            margin: 0;
                        }
                        form {
                            background-color: #fff;
                            max-width: 400px;
                            margin: auto;
                            padding: 2em;
                            border-radius: 1em;
                            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
                        }
                        label {
                            font-weight: bold;
                            margin-bottom: 0.5em;
                            display: block;
                        }
                        input[type="password"] {
                            width: 100%;
                            padding: 0.8em;
                            margin-bottom: 1em;
                            border: 1px solid #ddd;
                            border-radius: 0.5em;
                            box-sizing: border-box;
                        }
                        button {
                            padding: 0.8em;
                            color: #fff;
                            background-color: #e53935; 
                            border: none;
                            border-radius: 0.5em;
                            cursor: pointer;
                            width: 100%;
                            font-size: 1em;
                            transition: background-color 0.3s ease;
                        }
                        button:hover {
                            background-color: #d32f2f; 
                        }
                      </style>
                      </head>
                      <body>
                      <form method="POST">
                        <input type="hidden" name="token" value="' . htmlspecialchars($token) . '">
                        <label for="new_password">Nueva Contraseña:</label>
                        <input type="password" name="new_password" required>
                        <button type="submit">Restablecer Contraseña</button>
                      </form>
                      </body>
                      </html>';
        } else {
            echo "Token inválido o expirado.";
        }

        $stmt->close();
    } elseif ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['token']) && isset($_POST['new_password'])) {
        $token = $_POST['token'];
        $newPassword = password_hash($_POST['new_password'], PASSWORD_BCRYPT);

        // Verificar si el token es válido y no ha expirado
        $sql = "SELECT IdUsuario FROM usuario WHERE Recordatorio = ? AND reset_expiry > NOW()";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("s", $token);
        $stmt->execute();
        $result = $stmt->get_result();

        if ($result->num_rows > 0) {
            $user = $result->fetch_assoc();
            $userId = $user['IdUsuario'];

            // Actualizar la contraseña en la base de datos
            $updateSql = "UPDATE usuario SET Contrasena = ?, Recordatorio = NULL, reset_expiry = NULL WHERE IdUsuario = ?";
            $updateStmt = $conn->prepare($updateSql);
            $updateStmt->bind_param("si", $newPassword, $userId);
            $updateStmt->execute();

            echo "Contraseña restablecida con éxito.";
            $updateStmt->close();
        } else {
            echo "Token inválido o expirado.";
        }

        $stmt->close();
        $conn->close();
    } else {
        // Detalle adicional sobre la solicitud inválida
        if ($_SERVER['REQUEST_METHOD'] != 'GET' && $_SERVER['REQUEST_METHOD'] != 'POST') {
            echo "Método de solicitud no permitido. Se esperaba GET o POST.";
        } elseif (!isset($_GET['token']) && !isset($_POST['token'])) {
            echo "Token no proporcionado en la solicitud.";
        } else {
            echo "Solicitud inválida.";
        }
    }
    ?>