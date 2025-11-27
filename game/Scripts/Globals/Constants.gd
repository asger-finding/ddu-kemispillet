extends Node

# Scenes
const DEFAULT_SCENE = "Menu/ConfigureConnectionMenu"

# World
const GRAVITY := 6500.0
const SPAWN_POSITION := Vector2(7953.0, -961.0)
const COUNTDOWN_TIME := 5.0 # s

# Connection states
const OFFLINE = "offline"
const ONLINE = "online"
const HANDSHAKED = "handshaked"
const SERVER = "server"
