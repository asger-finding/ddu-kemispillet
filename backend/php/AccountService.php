<?php
require_once 'ValidationUtils.php';
require_once 'ResponseUtils.php';

function register($conn, $data) {
    [$valid, $error] = validate_credentials($data);
    if (!$valid) {
        response(0, [], $error);
        return;
    }

    $username = trim($data['username']);
    $password = $data['password'];

    [$valid, $error] = validate_username($username);
    if (!$valid) {
        response(0, [], $error);
        return;
    }

    [$valid, $error] = validate_password($password);
    if (!$valid) {
        response(0, [], $error);
        return;
    }

    $password_hash = password_hash($password, PASSWORD_DEFAULT);

    $conn->begin_transaction();
    try {
        // Create account
        $stmt = $conn->prepare("INSERT INTO accounts (username, password_hash) VALUES (?, ?)");
        if (!$stmt) {
            response(0, [], "db_error");
            $conn->rollback();
            return;
        }
        
        $stmt->bind_param("ss", $username, $password_hash);
        $stmt->execute();
        
        $player_id = $conn->insert_id;
        $stmt->close();

        // Create player
        $stmt = $conn->prepare("INSERT INTO players (player_id) VALUES (?)");
        $stmt->bind_param("i", $player_id);
        $stmt->execute();
        $stmt->close();

        $conn->commit();

        // Return the created player
        $player = [
            'player_id' => $player_id,
            'username' => $username,
            'filling' => 0,
            'scrap' => 0,
            'inventory' => null
        ];

        response(1, $player);

    } catch (Exception $e) {
        $conn->rollback();
        
        // Check if it's a duplicate entry error
        if ($conn->errno === 1062 || strpos($e->getMessage(), 'Duplicate entry') !== false) {
            response(0, [], "username_taken");
        } else {
            error_log("Account creation error: " . $e->getMessage());
            response(0, [], "db_error");
        }
    }
}

function login($conn, $data) {
    [$valid, $error] = validate_credentials($data);
    if (!$valid) {
        response(0, [], $error);
        return;
    }

    $username = trim($data['username']);
    $password = $data['password'];

    // Get account and player data
    $stmt = $conn->prepare("
        SELECT a.player_id, a.username, a.password_hash, a.status, 
               p.filling, p.scrap, p.inventory
        FROM accounts a
        INNER JOIN players p ON a.player_id = p.player_id
        WHERE a.username = ?
    ");
    $stmt->bind_param("s", $username);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows === 0) {
        response(0, [], "invalid_credentials");
        $stmt->close();
        return;
    }

    $row = $result->fetch_assoc();
    $stmt->close();

    if ($row['status'] !== 1) {
        response(0, [], "account_disabled");
        return;
    }

    if (!password_verify($password, $row['password_hash'])) {
        response(0, [], "invalid_credentials");
        return;
    }

    // Update last login
    $stmt = $conn->prepare("UPDATE accounts SET last_login = CURRENT_TIMESTAMP WHERE player_id = ?");
    $stmt->bind_param("i", $row['player_id']);
    $stmt->execute();
    $stmt->close();

    // Return player data
    $player = [
        'player_id' => $row['player_id'],
        'username' => $row['username'],
        'filling' => $row['filling'],
        'scrap' => $row['scrap'],
        'inventory' => $row['inventory']
    ];

    response(1, $player);
}

function update_account($conn, $data) {
    [$valid, $error] = validate_id($data);
    if (!$valid) {
        response(0, [], "missing_player_id");
        return;
    }

    $player_id = intval($data['player_id']);
    $updates = [];
    $params = [];
    $types = "";

    // Check for password update
    if (isset($data['password']) && !empty($data['password'])) {
        [$valid, $error] = validate_password($data['password']);
        if (!$valid) {
            response(0, [], $error);
            return;
        }
        $password_hash = password_hash($data['password'], PASSWORD_DEFAULT);
        $updates[] = "password_hash = ?";
        $params[] = $password_hash;
        $types .= "s";
    }

    // Check for status update
    if (isset($data['status'])) {
        $updates[] = "status = ?";
        $params[] = intval($data['status']);
        $types .= "i";
    }

    if (empty($updates)) {
        response(0, [], "no_updates_provided");
        return;
    }

    $params[] = $player_id;
    $types .= "i";

    $sql = "UPDATE accounts SET " . implode(", ", $updates) . " WHERE player_id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param($types, ...$params);

    if ($stmt->execute()) {
        if ($stmt->affected_rows > 0) {
            response(1, ['updated' => true]);
        } else {
            response(0, [], "account_not_found");
        }
    } else {
        response(0, [], "db_error");
    }
    $stmt->close();
}
?>