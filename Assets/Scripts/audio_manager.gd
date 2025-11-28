extends Node

## Gerenciador de áudio global do jogo (Autoload Singleton)

signal volume_changed(new_volume: float)

var music_volume: float = 1.0:
	set(value):
		music_volume = clamp(value, 0.0, 1.0)
		volume_changed.emit(music_volume)
		_save_volume()

var _menu_music_player: AudioStreamPlayer = null
var _game_music_player: AudioStreamPlayer = null

# Músicas do menu
const MUSICA_MENU_1 = preload("res://Assets/Musica/MusicaMenuInicial.mp3")
const MUSICA_MENU_2 = preload("res://Assets/Musica/MusicaMenuInicial2.mp3")

# Músicas do jogo
const MUSICA_JOGO_1 = preload("res://Assets/Musica/Musicajogo1.mp3")
const MUSICA_JOGO_2 = preload("res://Assets/Musica/Musicajogo2.mp3")

func _ready() -> void:
	_load_volume()
	_create_music_players()

func _create_music_players() -> void:
	# Player para música do menu
	_menu_music_player = AudioStreamPlayer.new()
	_menu_music_player.name = "MenuMusicPlayer"
	_menu_music_player.volume_db = linear_to_db(music_volume)
	_menu_music_player.bus = "Master"
	add_child(_menu_music_player)
	
	# Player para música do jogo
	_game_music_player = AudioStreamPlayer.new()
	_game_music_player.name = "GameMusicPlayer"
	_game_music_player.volume_db = linear_to_db(music_volume)
	_game_music_player.bus = "Master"
	add_child(_game_music_player)
	
	# Conectar sinal de término para loop
	_menu_music_player.finished.connect(_on_menu_music_finished)
	_game_music_player.finished.connect(_on_game_music_finished)

func play_menu_music() -> void:
	if not _menu_music_player:
		return
	
	# Parar música do jogo se estiver tocando
	stop_game_music()
	
	# Escolher música aleatória do menu
	var musicas_menu = [MUSICA_MENU_1, MUSICA_MENU_2]
	var musica_escolhida = musicas_menu[randi() % musicas_menu.size()]
	
	_menu_music_player.stream = musica_escolhida
	_menu_music_player.play()
	print("Tocando música do menu: ", musica_escolhida.resource_path.get_file())

func stop_menu_music() -> void:
	if _menu_music_player and _menu_music_player.playing:
		_menu_music_player.stop()

func play_game_music() -> void:
	if not _game_music_player:
		return
	
	# Parar música do menu se estiver tocando
	stop_menu_music()
	
	# Escolher música aleatória do jogo
	var musicas_jogo = [MUSICA_JOGO_1, MUSICA_JOGO_2]
	var musica_escolhida = musicas_jogo[randi() % musicas_jogo.size()]
	
	_game_music_player.stream = musica_escolhida
	_game_music_player.play()
	print("Tocando música do jogo: ", musica_escolhida.resource_path.get_file())

func stop_game_music() -> void:
	if _game_music_player and _game_music_player.playing:
		_game_music_player.stop()

func _on_menu_music_finished() -> void:
	# Quando a música do menu terminar, tocar a outra
	if _menu_music_player and _menu_music_player.stream == MUSICA_MENU_1:
		_menu_music_player.stream = MUSICA_MENU_2
	else:
		_menu_music_player.stream = MUSICA_MENU_1
	_menu_music_player.play()

func _on_game_music_finished() -> void:
	# Quando a música do jogo terminar, tocar a outra
	if _game_music_player and _game_music_player.stream == MUSICA_JOGO_1:
		_game_music_player.stream = MUSICA_JOGO_2
	else:
		_game_music_player.stream = MUSICA_JOGO_1
	_game_music_player.play()

func set_volume(new_volume: float) -> void:
	music_volume = new_volume
	if _menu_music_player:
		_menu_music_player.volume_db = linear_to_db(music_volume)
	if _game_music_player:
		_game_music_player.volume_db = linear_to_db(music_volume)

func _save_volume() -> void:
	var config = ConfigFile.new()
	config.set_value("audio", "music_volume", music_volume)
	var error = config.save("user://audio_settings.cfg")
	if error != OK:
		push_error("Erro ao salvar volume: %d" % error)

func _load_volume() -> void:
	var config = ConfigFile.new()
	var error = config.load("user://audio_settings.cfg")
	if error == OK:
		music_volume = config.get_value("audio", "music_volume", 1.0)
	else:
		music_volume = 1.0  # Volume padrão
