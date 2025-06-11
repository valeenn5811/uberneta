<?php 
require 'header.php';

require 'config.php';

if (array_key_exists("IdUsuario", $_GET) && isset($_GET['IdUsuario']) && !empty($_GET['IdUsuario'])) {
    $IdUsuario = $_GET['IdUsuario'];
} else {
    exit();
}

// Datos de los DÍAS FESTIVOS
$sql = "SELECT calendariofestivos.TtitleFestivo, calendariofestivos.FechaFestivo, calendariofestivos.Color 
        FROM calendariofestivos 
        JOIN usuario ON calendariofestivos.IdFestivo = usuario.IdFestivo 
        WHERE calendariofestivos.Festivo = 1 AND usuario.IdUsuario = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $IdUsuario);
$stmt->execute();
$result = $stmt->get_result();

// Crea un arreglo de objetos JSON que coincida con el formato de tu ejemplo
$json = [];
while ($row = $result->fetch_assoc()) {
    $item = [];
    $item['title'] = $row['TtitleFestivo'] ?? 'Sin título'; // Asegúrate de que el nombre no sea null
    $item['start'] = $row['FechaFestivo'] ?? '0000-00-00'; // Asegúrate de que la fecha no sea null
    $item['display'] = 'background';
    $item['color'] = $row['Color'] ?? '#FFFFFF'; // Asegúrate de que el color no sea null

    $json[] = $item;
}

// Codifica el resultado como un objeto JSON
echo json_encode($json);

$stmt->close();
$conn->close();
