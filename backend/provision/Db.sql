SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";
CREATE DATABASE IF NOT EXISTS kemispillet;
USE kemispillet;

-- Accounts (login layer)
CREATE TABLE IF NOT EXISTS accounts (
    player_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    username VARCHAR(40) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    auth_token CHAR(64) NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL DEFAULT NULL,
    status TINYINT NOT NULL DEFAULT 1,
    PRIMARY KEY (player_id),
    UNIQUE KEY (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Player state (game layer)
CREATE TABLE IF NOT EXISTS players (
    player_id INT UNSIGNED NOT NULL,
    questions_answered INT NOT NULL DEFAULT 0,
    questions_correct INT NOT NULL DEFAULT 0,
    runs INT NOT NULL DEFAULT 0,
    victories INT NOT NULL DEFAULT 0,
    PRIMARY KEY (player_id),
    CONSTRAINT fk_players_account
        FOREIGN KEY (player_id) REFERENCES accounts(player_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;