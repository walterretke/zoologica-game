extends Node

# Singleton para gerenciar salvamento do jogo
const SAVE_FILE_PATH = "user://game_save.cfg"

# Verifica se existe um save
static func has_save() -> bool:
	var config = ConfigFile.new()
	var error = config.load(SAVE_FILE_PATH)
	return error == OK

# Salva que o jogo foi iniciado
static func save_game_started() -> void:
	var config = ConfigFile.new()
	config.set_value("game", "started", true)
	config.save(SAVE_FILE_PATH)
	print("Jogo salvo: iniciado")

# Limpa o save (quando iniciar novo jogo)
static func clear_save() -> void:
	var dir = DirAccess.open("user://")
	if dir:
		dir.remove(SAVE_FILE_PATH)
		print("Save limpo")

