extends DesafioBase
class_name DesafioGirafa

## Desafio da Jaula da Girafa: Regra de Três Simples
## Nível: 7º ao 9º ano do Ensino Fundamental

@export var dificuldade: int = 1  # 1 = fácil, 2 = médio, 3 = difícil

func _ready() -> void:
	titulo = "🦒 DESAFIO DA GIRAFA"
	descricao = "Resolva os problemas de Regra de Três Simples!"
	total_perguntas = 5
	moedas_por_acerto = 25
	tempo_por_pergunta = 600.0  # 10 minutos
	super._ready()

func _obter_conteudo_ajuda(ajuda_label: RichTextLabel) -> void:
	ajuda_label.text = """[center][font_size=32]🦒 REGRA DE TRÊS SIMPLES[/font_size][/center]

[font_size=24]O QUE É:[/font_size]
[font_size=20]Usada quando temos 2 grandezas relacionadas diretamente.[/font_size]

[font_size=24]FÓRMULA:[/font_size]
[font_size=20]a está para b, assim como c está para x[/font_size]
[font_size=20]a/b = c/x  →  x = (b × c) ÷ a[/font_size]

[font_size=24]COMO RESOLVER - PASSO A PASSO:[/font_size]

[font_size=20]1. ORGANIZE OS DADOS:[/font_size]
   Escreva o que você sabe e o que quer descobrir.

[font_size=20]2. MONTE A PROPORÇÃO:[/font_size]
   Coloque as grandezas na mesma ordem:
   Primeira situação → Segunda situação

[font_size=20]3. MULTIPLIQUE EM CRUZ:[/font_size]
   Multiplique os valores que estão na diagonal.

[font_size=20]4. ISOLE O X:[/font_size]
   Divida o resultado pelo número que está com o x.

[font_size=24]EXEMPLO PRÁTICO:[/font_size]

[font_size=20]Problema:[/font_size]
Se 3 girafas comem 12 kg de folhas por dia,
quantos kg 5 girafas comerão?

[font_size=20]Solução:[/font_size]
1. Organize: 3 girafas → 12 kg
             5 girafas → x kg

2. Monte: 3/12 = 5/x

3. Multiplique em cruz: 3 × x = 12 × 5
                       3x = 60

4. Isole o x: x = 60 ÷ 3 = 20 kg

[font_size=20]RESPOSTA: 5 girafas comerão 20 kg de folhas[/font_size]"""

func _gerar_pergunta() -> void:
	# Regra de três simples: a está para b assim como c está para x
	# a/b = c/x  ->  x = (b * c) / a
	
	var a: int
	var b: int
	var c: int
	
	# Ajustar números baseado na dificuldade para resultados inteiros
	match dificuldade:
		1:  # Fácil: números pequenos e divisões exatas
			a = randi_range(2, 5)
			var multiplicador_b = randi_range(2, 6)
			b = a * multiplicador_b
			var multiplicador_c = randi_range(2, 4)
			c = a * multiplicador_c
		2:  # Médio
			a = randi_range(3, 8)
			var multiplicador_b = randi_range(3, 8)
			b = a * multiplicador_b
			var multiplicador_c = randi_range(2, 6)
			c = a * multiplicador_c
		3:  # Difícil
			a = randi_range(5, 12)
			var multiplicador_b = randi_range(4, 10)
			b = a * multiplicador_b
			var multiplicador_c = randi_range(3, 8)
			c = a * multiplicador_c
		_:
			a = randi_range(2, 5)
			var multiplicador_b = randi_range(2, 5)
			b = a * multiplicador_b
			var multiplicador_c = randi_range(2, 4)
			c = a * multiplicador_c
	
	# Calcular resposta: x = (b * c) / a
	resposta_correta = (b * c) / a
	
	# Contextos divertidos de regra de três direta
	var problema = _gerar_contexto_regra_tres(a, b, c, int(resposta_correta))
	_pergunta_label.text = problema
	
	# Configurar múltipla escolha com 4 opções
	var opcoes = _gerar_opcoes(int(resposta_correta))
	_configurar_multipla_escolha(opcoes)
	
	print("Regra de Três: %d -> %d | %d -> %d" % [a, b, c, resposta_correta])

func _gerar_contexto_regra_tres(a: int, b: int, c: int, resposta: int) -> String:
	var tipo = randi() % 6
	
	match tipo:
		0:  # Girafas e folhas
			return "Se %d girafas comem %d kg de folhas por dia,\nquantos kg %d girafas comerão?" % [a, b, c]
		1:  # Visitantes e ingressos
			return "Se %d visitantes pagam R$ %d em ingressos,\nquanto pagarão %d visitantes?" % [a, b, c]
		2:  # Tempo e distância
			return "Se a girafa anda %d metros em %d minutos,\nquantos metros andará em %d minutos?" % [a, b, c]
		3:  # Tratadores e animais
			return "Se %d tratadores cuidam de %d animais,\nquantos animais %d tratadores cuidarão?" % [a, b, c]
		4:  # Ração
			return "Se %d sacos de ração alimentam animais por %d dias,\npor quantos dias %d sacos durarão?" % [a, b, c]
		5:  # Litros de água
			return "Se %d girafas bebem %d litros de água,\nquantos litros %d girafas beberão?" % [a, b, c]
		_:
			return "Se %d unidades produzem %d resultados,\nquantos resultados %d unidades produzirão?" % [a, b, c]

func _gerar_opcoes(resposta_correta_int: int) -> Array:
	var opcoes: Array = [resposta_correta_int]
	
	# Gerar 3 opções incorretas próximas à resposta correta
	var variacoes = [-3, -2, -1, 1, 2, 3, 4, 5]
	variacoes.shuffle()
	
	var tentativas = 0
	while opcoes.size() < 4 and tentativas < 20:
		var variacao = variacoes[tentativas % variacoes.size()]
		var nova_opcao = resposta_correta_int + variacao
		
		# Garantir que a opção é positiva e única
		if nova_opcao > 0 and not nova_opcao in opcoes:
			opcoes.append(nova_opcao)
		
		tentativas += 1
	
	# Se ainda não tem 4 opções, adicionar valores diferentes
	while opcoes.size() < 4:
		var nova_opcao = randi_range(max(1, resposta_correta_int - 10), resposta_correta_int + 10)
		if nova_opcao > 0 and not nova_opcao in opcoes:
			opcoes.append(nova_opcao)
	
	# Embaralhar opções
	opcoes.shuffle()
	return opcoes

