extends CanvasLayer
class_name DesafioBase

## Classe base para todos os desafios matemáticos

signal desafio_concluido(acertos: int, total: int, moedas_ganhas: int)
signal desafio_cancelado

@export var titulo: String = "Desafio Matemático"
@export var descricao: String = "Resolva os problemas!"
@export var total_perguntas: int = 5
@export var moedas_por_acerto: int = 10
@export var tempo_por_pergunta: float = 30.0  # Segundos

# Referências UI (serão configuradas nas cenas filhas)
var _painel_principal: PanelContainer
var _titulo_label: Label
var _pergunta_label: Label
var _resposta_input: LineEdit
var _confirmar_btn: Button
var _pular_btn: Button
var _fechar_btn: Button
var _progresso_label: Label
var _tempo_label: Label
var _feedback_label: Label
var _opcoes_container: HBoxContainer  # Container para botões de múltipla escolha

# Estado do desafio
var pergunta_atual: int = 0
var acertos: int = 0
var resposta_correta: Variant  # Pode ser int ou float
var tempo_restante: float = 0.0
var desafio_ativo: bool = false
var usando_multipla_escolha: bool = false
var _player: CharacterBody2D = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_configurar_ui()
	# Mostrar ajuda primeiro, depois iniciar desafio
	_mostrar_ajuda()

func _process(delta: float) -> void:
	# Não processar timer se o jogo estiver pausado
	if get_tree().paused:
		return
	
	if desafio_ativo and tempo_restante > 0:
		tempo_restante -= delta
		_atualizar_tempo()
		
		if tempo_restante <= 0:
			_tempo_esgotado()

func _configurar_ui() -> void:
	# Criar estrutura UI base
	var fundo = ColorRect.new()
	fundo.name = "Fundo"
	fundo.color = Color(0, 0, 0, 0.8)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(fundo)
	
	_painel_principal = PanelContainer.new()
	_painel_principal.name = "PainelPrincipal"
	_painel_principal.set_anchors_preset(Control.PRESET_CENTER)
	_painel_principal.custom_minimum_size = Vector2(700, 500)
	_painel_principal.position = Vector2(-350, -250)
	_painel_principal.visible = false  # Esconder até a ajuda ser fechada
	
	# Estilizar o painel
	var estilo = StyleBoxFlat.new()
	estilo.bg_color = Color(0.15, 0.2, 0.15, 1.0)
	estilo.border_color = Color(0.4, 0.8, 0.4, 1.0)
	estilo.set_border_width_all(4)
	estilo.set_corner_radius_all(20)
	_painel_principal.add_theme_stylebox_override("panel", estilo)
	add_child(_painel_principal)
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.add_theme_constant_override("separation", 20)
	_painel_principal.add_child(vbox)
	
	# Criar margem
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 25)
	margin.add_theme_constant_override("margin_bottom", 25)
	vbox.add_child(margin)
	
	var content_vbox = VBoxContainer.new()
	content_vbox.add_theme_constant_override("separation", 15)
	margin.add_child(content_vbox)
	
	# Carregar fonte
	var font = load("res://Assets/Fonts/Silkscreen/Silkscreen-Regular.ttf")
	
	# Header com título e botão fechar
	var header = HBoxContainer.new()
	content_vbox.add_child(header)
	
	_titulo_label = Label.new()
	_titulo_label.text = titulo
	_titulo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_titulo_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if font:
		_titulo_label.add_theme_font_override("font", font)
	_titulo_label.add_theme_font_size_override("font_size", 32)
	_titulo_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4, 1.0))
	header.add_child(_titulo_label)
	
	_fechar_btn = Button.new()
	_fechar_btn.text = "✕"
	_fechar_btn.custom_minimum_size = Vector2(50, 50)
	if font:
		_fechar_btn.add_theme_font_override("font", font)
	_fechar_btn.add_theme_font_size_override("font_size", 24)
	_fechar_btn.pressed.connect(_fechar_desafio)
	header.add_child(_fechar_btn)
	
	# Linha de progresso e tempo
	var info_hbox = HBoxContainer.new()
	content_vbox.add_child(info_hbox)
	
	_progresso_label = Label.new()
	_progresso_label.text = "Pergunta: 1/%d" % total_perguntas
	_progresso_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if font:
		_progresso_label.add_theme_font_override("font", font)
	_progresso_label.add_theme_font_size_override("font_size", 20)
	_progresso_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.7, 1.0))
	info_hbox.add_child(_progresso_label)
	
	_tempo_label = Label.new()
	_tempo_label.text = "⏱ 30s"
	_tempo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if font:
		_tempo_label.add_theme_font_override("font", font)
	_tempo_label.add_theme_font_size_override("font_size", 20)
	_tempo_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3, 1.0))
	info_hbox.add_child(_tempo_label)
	
	# Separador
	var separator = HSeparator.new()
	separator.add_theme_constant_override("separation", 10)
	content_vbox.add_child(separator)
	
	# Pergunta
	_pergunta_label = Label.new()
	_pergunta_label.text = "Carregando pergunta..."
	_pergunta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pergunta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_pergunta_label.custom_minimum_size = Vector2(600, 80)
	if font:
		_pergunta_label.add_theme_font_override("font", font)
	_pergunta_label.add_theme_font_size_override("font_size", 28)
	_pergunta_label.add_theme_color_override("font_color", Color.WHITE)
	content_vbox.add_child(_pergunta_label)
	
	# Container para opções de múltipla escolha
	_opcoes_container = HBoxContainer.new()
	_opcoes_container.name = "OpcoesContainer"
	_opcoes_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_opcoes_container.add_theme_constant_override("separation", 15)
	_opcoes_container.visible = false
	content_vbox.add_child(_opcoes_container)
	
	# Container para input de texto
	var input_container = HBoxContainer.new()
	input_container.name = "InputContainer"
	input_container.alignment = BoxContainer.ALIGNMENT_CENTER
	input_container.add_theme_constant_override("separation", 10)
	content_vbox.add_child(input_container)
	
	_resposta_input = LineEdit.new()
	_resposta_input.placeholder_text = "Resposta..."
	_resposta_input.custom_minimum_size = Vector2(350, 55)
	_resposta_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_resposta_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if font:
		_resposta_input.add_theme_font_override("font", font)
	_resposta_input.add_theme_font_size_override("font_size", 26)
	
	# Estilizar o campo de input
	var input_style = StyleBoxFlat.new()
	input_style.bg_color = Color(0.1, 0.12, 0.1, 1.0)
	input_style.border_color = Color(0.3, 0.6, 0.3, 1.0)
	input_style.set_border_width_all(2)
	input_style.set_corner_radius_all(8)
	input_style.set_content_margin_all(10)
	_resposta_input.add_theme_stylebox_override("normal", input_style)
	
	var input_style_focus = input_style.duplicate()
	input_style_focus.border_color = Color(0.4, 0.9, 0.4, 1.0)
	_resposta_input.add_theme_stylebox_override("focus", input_style_focus)
	
	_resposta_input.add_theme_color_override("font_color", Color.WHITE)
	_resposta_input.add_theme_color_override("font_placeholder_color", Color(0.6, 0.6, 0.6, 0.8))
	_resposta_input.add_theme_color_override("caret_color", Color(0.4, 1.0, 0.4, 1.0))
	
	_resposta_input.text_submitted.connect(_on_resposta_confirmada)
	input_container.add_child(_resposta_input)
	
	_confirmar_btn = Button.new()
	_confirmar_btn.text = "OK"
	_confirmar_btn.custom_minimum_size = Vector2(80, 55)
	if font:
		_confirmar_btn.add_theme_font_override("font", font)
	_confirmar_btn.add_theme_font_size_override("font_size", 22)
	
	# Estilizar botão confirmar
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.2, 0.5, 0.2, 1.0)
	btn_style.border_color = Color(0.3, 0.7, 0.3, 1.0)
	btn_style.set_border_width_all(2)
	btn_style.set_corner_radius_all(8)
	_confirmar_btn.add_theme_stylebox_override("normal", btn_style)
	
	var btn_style_hover = btn_style.duplicate()
	btn_style_hover.bg_color = Color(0.3, 0.6, 0.3, 1.0)
	_confirmar_btn.add_theme_stylebox_override("hover", btn_style_hover)
	
	_confirmar_btn.add_theme_color_override("font_color", Color.WHITE)
	_confirmar_btn.pressed.connect(func(): _on_resposta_confirmada(_resposta_input.text))
	input_container.add_child(_confirmar_btn)
	
	# Feedback
	_feedback_label = Label.new()
	_feedback_label.text = ""
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font:
		_feedback_label.add_theme_font_override("font", font)
	_feedback_label.add_theme_font_size_override("font_size", 22)
	content_vbox.add_child(_feedback_label)
	
	# Botões
	var botoes_hbox = HBoxContainer.new()
	botoes_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	botoes_hbox.add_theme_constant_override("separation", 20)
	content_vbox.add_child(botoes_hbox)
	
	_pular_btn = Button.new()
	_pular_btn.text = "⏭ PULAR"
	_pular_btn.custom_minimum_size = Vector2(150, 50)
	if font:
		_pular_btn.add_theme_font_override("font", font)
	_pular_btn.add_theme_font_size_override("font_size", 20)
	_pular_btn.pressed.connect(_pular_pergunta)
	botoes_hbox.add_child(_pular_btn)

var _painel_ajuda: PanelContainer = null
var _ajuda_visivel: bool = false

func _mostrar_ajuda() -> void:
	# Criar painel de ajuda
	_ajuda_visivel = true
	_painel_ajuda = PanelContainer.new()
	_painel_ajuda.name = "PainelAjuda"
	_painel_ajuda.set_anchors_preset(Control.PRESET_CENTER)
	_painel_ajuda.custom_minimum_size = Vector2(800, 600)
	_painel_ajuda.position = Vector2(-400, -300)
	
	# Estilizar o painel de ajuda
	var estilo_ajuda = StyleBoxFlat.new()
	estilo_ajuda.bg_color = Color(0.1, 0.15, 0.2, 0.95)
	estilo_ajuda.border_color = Color(0.3, 0.6, 0.9, 1.0)
	estilo_ajuda.set_border_width_all(4)
	estilo_ajuda.set_corner_radius_all(20)
	_painel_ajuda.add_theme_stylebox_override("panel", estilo_ajuda)
	add_child(_painel_ajuda)
	
	var vbox_ajuda = VBoxContainer.new()
	vbox_ajuda.add_theme_constant_override("separation", 20)
	_painel_ajuda.add_child(vbox_ajuda)
	
	var margin_ajuda = MarginContainer.new()
	margin_ajuda.add_theme_constant_override("margin_left", 40)
	margin_ajuda.add_theme_constant_override("margin_right", 40)
	margin_ajuda.add_theme_constant_override("margin_top", 30)
	margin_ajuda.add_theme_constant_override("margin_bottom", 30)
	vbox_ajuda.add_child(margin_ajuda)
	
	var content_vbox_ajuda = VBoxContainer.new()
	content_vbox_ajuda.add_theme_constant_override("separation", 15)
	margin_ajuda.add_child(content_vbox_ajuda)
	
	# Carregar fonte
	var font = load("res://Assets/Fonts/Silkscreen/Silkscreen-Regular.ttf")
	
	# Título
	var titulo_ajuda = Label.new()
	titulo_ajuda.text = "📚 COMO RESOLVER"
	titulo_ajuda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font:
		titulo_ajuda.add_theme_font_override("font", font)
	titulo_ajuda.add_theme_font_size_override("font_size", 36)
	titulo_ajuda.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3, 1.0))
	content_vbox_ajuda.add_child(titulo_ajuda)
	
	# Conteúdo da ajuda (será preenchido pelas classes filhas)
	var ajuda_content = RichTextLabel.new()
	ajuda_content.name = "AjudaContent"
	ajuda_content.custom_minimum_size = Vector2(0, 400)
	ajuda_content.bbcode_enabled = true
	ajuda_content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if font:
		ajuda_content.add_theme_font_override("normal_font", font)
	ajuda_content.add_theme_font_size_override("normal_font_size", 22)
	ajuda_content.add_theme_color_override("default_color", Color(1, 1, 1, 1))
	content_vbox_ajuda.add_child(ajuda_content)
	
	# Botão para começar
	var btn_comecar = Button.new()
	btn_comecar.text = "COMEÇAR DESAFIO"
	btn_comecar.custom_minimum_size = Vector2(300, 60)
	if font:
		btn_comecar.add_theme_font_override("font", font)
	btn_comecar.add_theme_font_size_override("font_size", 28)
	
	# Estilizar botão
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.2, 0.6, 0.2, 1.0)
	btn_style.border_color = Color(0.3, 0.8, 0.3, 1.0)
	btn_style.set_border_width_all(3)
	btn_style.set_corner_radius_all(10)
	btn_comecar.add_theme_stylebox_override("normal", btn_style)
	
	var btn_style_hover = btn_style.duplicate()
	btn_style_hover.bg_color = Color(0.3, 0.7, 0.3, 1.0)
	btn_comecar.add_theme_stylebox_override("hover", btn_style_hover)
	
	btn_comecar.add_theme_color_override("font_color", Color.WHITE)
	btn_comecar.pressed.connect(_fechar_ajuda_e_iniciar)
	content_vbox_ajuda.add_child(btn_comecar)
	
	# Preencher conteúdo da ajuda (será sobrescrito pelas classes filhas)
	_obter_conteudo_ajuda(ajuda_content)

func _fechar_ajuda_e_iniciar() -> void:
	if _painel_ajuda:
		_painel_ajuda.queue_free()
		_painel_ajuda = null
	_ajuda_visivel = false
	# Mostrar painel principal do desafio
	if _painel_principal:
		_painel_principal.visible = true
	_iniciar_desafio()

func _obter_conteudo_ajuda(ajuda_label: RichTextLabel) -> void:
	# Esta função será sobrescrita pelas classes filhas
	ajuda_label.text = "[center]Conteúdo de ajuda será definido pelas classes filhas[/center]"

func _iniciar_desafio() -> void:
	pergunta_atual = 0
	acertos = 0
	desafio_ativo = true
	_proxima_pergunta()

func _proxima_pergunta() -> void:
	if pergunta_atual >= total_perguntas:
		_finalizar_desafio()
		return
	
	pergunta_atual += 1
	tempo_restante = tempo_por_pergunta
	_feedback_label.text = ""
	_resposta_input.text = ""
	_resposta_input.editable = true
	_atualizar_progresso()
	
	# Gerar nova pergunta (sobrescrever nas classes filhas)
	_gerar_pergunta()
	
	# Focar no input
	await get_tree().process_frame
	_resposta_input.grab_focus()

func _gerar_pergunta() -> void:
	# Método a ser sobrescrito pelas classes filhas
	_pergunta_label.text = "Pergunta de teste?"
	resposta_correta = 0

func _on_resposta_confirmada(resposta_texto: String) -> void:
	if not desafio_ativo or resposta_texto.strip_edges().is_empty():
		return
	
	_resposta_input.editable = false
	
	# Verificar resposta
	var resposta_numero = resposta_texto.strip_edges().to_float()
	var correto = _verificar_resposta(resposta_numero)
	
	if correto:
		acertos += 1
		_feedback_label.text = "✓ CORRETO!"
		_feedback_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1.0))
	else:
		_feedback_label.text = "✗ Errado! Resposta: %s" % str(resposta_correta)
		_feedback_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
	
	# Aguardar um pouco e ir para próxima
	await get_tree().create_timer(1.5).timeout
	_proxima_pergunta()

func _verificar_resposta(resposta: float) -> bool:
	# Verifica com margem de erro para números decimais
	if resposta_correta is float:
		return abs(resposta - resposta_correta) < 0.01
	else:
		return int(resposta) == resposta_correta

func _on_opcao_selecionada(valor: Variant) -> void:
	if not desafio_ativo:
		return
	
	# Desabilitar botões
	for child in _opcoes_container.get_children():
		if child is Button:
			child.disabled = true
	
	var correto = _verificar_resposta_multipla(valor)
	
	if correto:
		acertos += 1
		_feedback_label.text = "✓ CORRETO!"
		_feedback_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1.0))
	else:
		_feedback_label.text = "✗ Errado! Resposta: %s" % str(resposta_correta)
		_feedback_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
	
	await get_tree().create_timer(1.5).timeout
	_proxima_pergunta()

func _verificar_resposta_multipla(valor: Variant) -> bool:
	if valor is float and resposta_correta is float:
		return abs(valor - resposta_correta) < 0.01
	return valor == resposta_correta

func _pular_pergunta() -> void:
	_feedback_label.text = "Pergunta pulada! Resposta era: %s" % str(resposta_correta)
	_feedback_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3, 1.0))
	
	await get_tree().create_timer(1.0).timeout
	_proxima_pergunta()

func _tempo_esgotado() -> void:
	_feedback_label.text = "⏱ Tempo esgotado! Resposta: %s" % str(resposta_correta)
	_feedback_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.3, 1.0))
	_resposta_input.editable = false
	
	await get_tree().create_timer(1.5).timeout
	_proxima_pergunta()

func _atualizar_progresso() -> void:
	_progresso_label.text = "Pergunta: %d/%d | Acertos: %d" % [pergunta_atual, total_perguntas, acertos]

func _atualizar_tempo() -> void:
	var segundos = int(tempo_restante)
	# Mostrar em minutos se for maior que 60 segundos
	if segundos >= 60:
		var minutos = segundos / 60
		var segundos_resto = segundos % 60
		_tempo_label.text = "⏱ %dm %02ds" % [minutos, segundos_resto]
	else:
		_tempo_label.text = "⏱ %ds" % segundos
	
	if segundos <= 10:
		_tempo_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
	elif segundos < 60:
		_tempo_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3, 1.0))
	else:
		_tempo_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1.0))

func _finalizar_desafio() -> void:
	desafio_ativo = false
	var moedas_ganhas = acertos * moedas_por_acerto
	
	# Mostrar resultado
	_pergunta_label.text = "🎉 DESAFIO CONCLUÍDO! 🎉"
	_feedback_label.text = "Acertos: %d/%d\nMoedas ganhas: +%d 🪙" % [acertos, total_perguntas, moedas_ganhas]
	_feedback_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0, 1.0))
	
	_resposta_input.visible = false
	_confirmar_btn.visible = false
	_pular_btn.text = "FECHAR"
	_pular_btn.pressed.disconnect(_pular_pergunta)
	_pular_btn.pressed.connect(func(): 
		desafio_concluido.emit(acertos, total_perguntas, moedas_ganhas)
		queue_free()
	)
	_tempo_label.text = ""
	_opcoes_container.visible = false
	
	# Dar as moedas ao jogador
	if _player:
		_player.adicionar_moedas(moedas_ganhas)

func _fechar_desafio() -> void:
	desafio_ativo = false
	desafio_cancelado.emit()
	queue_free()

func set_player(player: CharacterBody2D) -> void:
	_player = player

# Funções auxiliares para múltipla escolha
func _configurar_multipla_escolha(opcoes: Array) -> void:
	usando_multipla_escolha = true
	_resposta_input.get_parent().visible = false
	_opcoes_container.visible = true
	
	# Limpar opções anteriores
	for child in _opcoes_container.get_children():
		child.queue_free()
	
	# Carregar fonte
	var font = load("res://Assets/Fonts/Silkscreen/Silkscreen-Regular.ttf")
	
	# Criar botões para cada opção
	for opcao in opcoes:
		var btn = Button.new()
		btn.text = str(opcao)
		btn.custom_minimum_size = Vector2(120, 60)
		if font:
			btn.add_theme_font_override("font", font)
		btn.add_theme_font_size_override("font_size", 24)
		btn.pressed.connect(func(): _on_opcao_selecionada(opcao))
		_opcoes_container.add_child(btn)

func _configurar_input_texto() -> void:
	usando_multipla_escolha = false
	_resposta_input.get_parent().visible = true
	_opcoes_container.visible = false

