<?php
require_once 'ValidationUtils.php';
require_once 'ResponseUtils.php';

function update_player($conn, $data) {
    error_log("Received data: " . print_r($data, true));
    [$valid, $error] = validate_player_id($data, 'player_id');
    if (!$valid) {
        error_log("Validation failed: $error");
        response(0, [], $error);
        return;
    }
    
    $player_id = intval($data['player_id']);
    $updates = [];
    $params = [];
    $types = "";
    
    if (isset($data['questions_answered'])) {
        $updates[] = "questions_answered = ?";
        $params[] = intval($data['questions_answered']);
        $types .= "i";
    }
    
    if (isset($data['questions_correct'])) {
        $updates[] = "questions_correct = ?";
        $params[] = intval($data['questions_correct']);
        $types .= "i";
    }
    
    if (isset($data['runs'])) {
        $updates[] = "runs = ?";
        $params[] = intval($data['runs']);
        $types .= "i";
    }
    
    if (isset($data['victories'])) {
        $updates[] = "victories = ?";
        $params[] = intval($data['victories']);
        $types .= "i";
    }
    
    if (empty($updates)) {
        response(0, [], "no_updates_provided");
        return;
    }
    
    $params[] = $player_id;
    $types .= "i";
    
    $sql = "UPDATE players SET " . implode(", ", $updates) . " WHERE player_id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param($types, ...$params);
    
    if ($stmt->execute()) {
        if ($stmt->affected_rows > 0) {
            response(1, ['updated' => true]);
        } else {
            response(0, [], "player_not_found");
        }
    } else {
        response(0, [], "db_error");
    }
    $stmt->close();
}
?>