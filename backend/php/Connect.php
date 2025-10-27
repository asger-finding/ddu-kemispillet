<?php
function OpenConnection() {
    $db_host = "kemispillet-mysql";
    $db_name = "kemispillet";
    $db_username = "root";
    $db_password = "SuperSecret";
    
    $conn = new mysqli($db_host, $db_username, $db_password, $db_name, 3306);
    
    if ($conn->connect_error) {
        die("Connection failed: " . $conn->connect_error);
    }
    
    return $conn;
}

function CloseConnection($conn) {
    $conn->close();
}
?>