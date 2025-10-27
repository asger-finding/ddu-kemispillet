SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";

CREATE DATABASE IF NOT EXISTS kemispillet;
USE kemispillet;

-- Accounts (login layer)
CREATE TABLE accounts (
    player_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    username VARCHAR(40) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL DEFAULT NULL,
    status TINYINT NOT NULL DEFAULT 1,
    PRIMARY KEY (player_id),
    UNIQUE KEY (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Player state (game layer)
CREATE TABLE players (
    player_id INT UNSIGNED NOT NULL,
    filling INT NOT NULL DEFAULT 0,
    scrap INT NOT NULL DEFAULT 0,
    inventory VARCHAR(500) DEFAULT NULL,
    PRIMARY KEY (player_id),
    CONSTRAINT fk_players_account
        FOREIGN KEY (player_id) REFERENCES accounts(player_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
