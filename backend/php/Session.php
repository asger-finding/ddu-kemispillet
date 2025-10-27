<?php
ini_set('display_errors', 0);
ini_set('log_errors', 1);
ini_set('error_log', '/var/www/html/php_errors.log');
ob_start();

require_once 'Connect.php';
require_once 'ValidationUtils.php';
require_once 'ResponseUtils.php';
require_once 'AccountService.php';
require_once 'PlayerService.php';

$conn = OpenConnection();
if ($conn->connect_error) {
    ob_end_clean();
    response(0, [], "db_login_error");
    die();
}

[$error_message, $data] = validate_command();
if ($error_message !== "") {
    ob_end_clean();
    response(0, [], $error_message);
    die();
}

switch ($_REQUEST['command']) {
    case "register":
        register($conn, $data);
        break;
    case "login":
        login($conn, $data);
        break;
    case "update_account":
        update_account($conn, $data);
        break;
    case "update_player":
        update_player($conn, $data);
        break;
    default:
        ob_end_clean();
        response(0, [], "invalid_command");
        break;
}

$conn->close();
ob_end_clean();
?>