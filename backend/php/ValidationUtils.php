<?php
function validate_command() {
    if (!isset($_REQUEST['command']) || $_REQUEST['command'] === null) {
        return ["missing_command", null];
    }
    if (!isset($_REQUEST['data']) || $_REQUEST['data'] === null) {
        return ["missing_data", null];
    }
    
    $data = json_decode($_REQUEST['data'], true);
    if (json_last_error() !== JSON_ERROR_NONE) {
        return ["mangled_json", null];
    }
    
    return ["", $data];
}

function validate_username($username) {
    $username = trim($username);
    if (strlen($username) < 3 || strlen($username) > 40) {
        return [false, "invalid_username_length"];
    }
    return [true, ""];
}

function validate_password($password) {
    if (strlen($password) < 6) {
        return [false, "password_too_short"];
    }
    return [true, ""];
}

function validate_credentials($data) {
    if (!isset($data['username']) || !isset($data['password'])) {
        return [false, "missing_credentials"];
    }
    return [true, ""];
}

function validate_player_id($data, $field = 'player_id') {
    if (!isset($data[$field])) {
        return [false, "missing_{$field}"];
    }
    return [true, ""];
}
?>