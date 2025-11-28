extends RefCounted
class_name GameUtils

## Classe utilitária com funções auxiliares para o jogo

## Formata um número de moedas/preço para exibição
## Exemplos: 500 -> "500", 1500 -> "1.500", 12500 -> "12.500"
static func format_currency(value: int) -> String:
	if value < 0:
		# Para valores negativos (ganho de moedas), mostra com sinal +
		return "+%s" % format_currency(abs(value))
	
	if value == 0:
		return "0"
	
	if value < 1000:
		return str(value)
	
	# Formatar com separador de milhar
	var milhares = value / 1000
	var resto = value % 1000
	
	if resto == 0:
		return "%d.000" % milhares
	else:
		return "%d.%03d" % [milhares, resto]

## Formata moedas para o HUD (com prefixo "MOEDAS: ")
static func format_moedas_hud(value: int) -> String:
	return "MOEDAS: %s" % format_currency(value)

## Retorna uma cor baseada no nível de dificuldade (1-5)
static func get_difficulty_color(difficulty: int) -> Color:
	match difficulty:
		1:
			return Color(0.4, 1, 0.4, 1)  # Verde - fácil
		2:
			return Color(1, 1, 0.4, 1)  # Amarelo
		3:
			return Color(1, 0.7, 0.2, 1)  # Laranja
		4:
			return Color(1, 0.5, 0.2, 1)  # Laranja escuro
		5:
			return Color(1, 0.3, 0.3, 1)  # Vermelho - difícil
		_:
			return Color(1, 1, 0.8, 1)  # Padrão

## Retorna uma cor baseada no espaço disponível na jaula
static func get_space_color(current: int, max_animals: int) -> Color:
	var space_available = max_animals - current
	if space_available == 0:
		return Color(1, 0.3, 0.3, 1)  # Vermelho - cheio
	elif space_available <= 2:
		return Color(1, 0.8, 0.3, 1)  # Laranja - pouco espaço
	else:
		return Color(0.3, 1, 0.3, 1)  # Verde - espaço suficiente
