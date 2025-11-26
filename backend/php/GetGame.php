<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Content-Type: application/octet-stream');
header('Content-Disposition: attachment; filename="index.pck"');

$url = 'https://github.com/asger-finding/ddu-kemispillet/raw/refs/heads/netlify/game/index.pck';

// Use cURL for better control
$ch = curl_init($url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, false);
curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, true);

// Stream directly to output
curl_exec($ch);

if (curl_errno($ch)) {
    http_response_code(500);
    echo 'Error fetching game: ' . curl_error($ch);
}

curl_close($ch);
?>