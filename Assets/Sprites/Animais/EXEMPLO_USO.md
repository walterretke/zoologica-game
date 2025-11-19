# 📖 Exemplo de Uso das Animações dos Animais

Este arquivo mostra exemplos práticos de como usar as animações dos animais no código.

## 🎯 Exemplo Básico: Criar Sprite Animado

```gdscript
# Função para criar um sprite animado a partir de um Animal
func criar_sprite_animal(animal: Animal) -> AnimatedSprite2D:
    var sprite = AnimatedSprite2D.new()
    
    # Obtém o template do animal
    var template = animal.template as AnimalTemplate
    
    # Verifica se tem animação configurada
    if template and template.animacao_sprite:
        sprite.sprite_frames = template.animacao_sprite
        sprite.play("default")
        sprite.autoplay = "default"
    else:
        push_warning("Animal '%s' não tem animação configurada!" % template.nome_exibicao)
        # Pode criar um sprite estático como fallback
        var fallback_texture = load("res://Assets/Sprites/placeholder.png")
        if fallback_texture:
            var static_sprite = Sprite2D.new()
            static_sprite.texture = fallback_texture
            return static_sprite
    
    return sprite
```

## 🏗️ Exemplo: Renderizar Animais em uma Jaula

```gdscript
extends Node2D

# Referência à jaula
@export var cage: Cage

# Container para os sprites dos animais
var animal_sprites: Array[AnimatedSprite2D] = []

func _ready():
    if cage:
        atualizar_animais_na_jaula()

func atualizar_animais_na_jaula():
    # Remove sprites antigos
    for sprite in animal_sprites:
        if is_instance_valid(sprite):
            sprite.queue_free()
    animal_sprites.clear()
    
    # Cria sprites para cada animal
    for i in range(cage.animals.size()):
        var animal = cage.animals[i]
        var sprite = criar_sprite_animal(animal)
        
        if sprite:
            # Posiciona o animal na jaula (ajuste conforme necessário)
            sprite.position = calcular_posicao_animal(i, cage.animals.size())
            add_child(sprite)
            animal_sprites.append(sprite)

func calcular_posicao_animal(index: int, total: int) -> Vector2:
    # Exemplo: distribui os animais em uma grade
    var colunas = 3
    var espacamento = Vector2(64, 64)
    var inicio = Vector2(-64, -64)
    
    var col = index % colunas
    var linha = index / colunas
    
    return inicio + Vector2(col * espacamento.x, linha * espacamento.y)

func criar_sprite_animal(animal: Animal) -> AnimatedSprite2D:
    var template = animal.template as AnimalTemplate
    if not template or not template.animacao_sprite:
        return null
    
    var sprite = AnimatedSprite2D.new()
    sprite.sprite_frames = template.animacao_sprite
    sprite.play("default")
    return sprite
```

## 🔄 Exemplo: Atualizar Animais Quando Comprados

```gdscript
# No script da jaula ou do player
func _on_animal_comprado(animal: Animal, cage: Cage):
    # Atualiza a visualização da jaula
    atualizar_animais_na_jaula()
    
    # Ou emite um sinal para outros sistemas atualizarem
    animal_adicionado.emit(animal, cage)
```

## 🎨 Exemplo: Múltiplas Animações (Idle, Walk, etc.)

Se você configurar múltiplas animações no SpriteFrames:

```gdscript
func criar_sprite_animal_com_estados(animal: Animal) -> AnimatedSprite2D:
    var template = animal.template as AnimalTemplate
    if not template or not template.animacao_sprite:
        return null
    
    var sprite = AnimatedSprite2D.new()
    sprite.sprite_frames = template.animacao_sprite
    
    # Verifica quais animações estão disponíveis
    var animacoes = template.animacao_sprite.get_animation_names()
    print("Animações disponíveis para %s: %s" % [template.nome_exibicao, animacoes])
    
    # Inicia com a animação "idle" se disponível, senão usa "default"
    if "idle" in animacoes:
        sprite.play("idle")
    else:
        sprite.play("default")
    
    return sprite

# Mudar animação baseado em estado
func mudar_animacao_animal(sprite: AnimatedSprite2D, nome_animacao: String):
    if sprite.sprite_frames.has_animation(nome_animacao):
        sprite.play(nome_animacao)
    else:
        push_warning("Animação '%s' não encontrada!" % nome_animacao)
```

## 📍 Exemplo: Integração com Sistema de Jaulas

```gdscript
# No script que gerencia as jaulas no mapa
extends Node2D

var jaulas_visuais: Dictionary = {}  # {Cage: Node2D}

func adicionar_jaula_visual(cage: Cage, posicao: Vector2):
    var container = Node2D.new()
    container.position = posicao
    add_child(container)
    
    # Renderiza todos os animais da jaula
    for animal in cage.animals:
        var sprite = criar_sprite_animal(animal)
        if sprite:
            # Posiciona aleatoriamente dentro da área da jaula
            sprite.position = Vector2(
                randf_range(-50, 50),
                randf_range(-50, 50)
            )
            container.add_child(sprite)
    
    jaulas_visuais[cage] = container

func atualizar_jaula_visual(cage: Cage):
    if cage in jaulas_visuais:
        var container = jaulas_visuais[cage]
        
        # Remove animais antigos
        for child in container.get_children():
            child.queue_free()
        
        # Adiciona animais atuais
        for animal in cage.animals:
            var sprite = criar_sprite_animal(animal)
            if sprite:
                sprite.position = Vector2(
                    randf_range(-50, 50),
                    randf_range(-50, 50)
                )
                container.add_child(sprite)
```

## ⚡ Dicas de Performance

1. **Reutilizar Sprites:** Se possível, reutilize sprites ao invés de criar novos
2. **Occlusion Culling:** Desative animações de animais fora da tela
3. **Pool de Sprites:** Use object pooling para animais que aparecem/desaparecem frequentemente

```gdscript
# Exemplo simples de pool
var sprite_pool: Array[AnimatedSprite2D] = []

func obter_sprite_do_pool() -> AnimatedSprite2D:
    if sprite_pool.is_empty():
        return AnimatedSprite2D.new()
    return sprite_pool.pop_back()

func devolver_sprite_ao_pool(sprite: AnimatedSprite2D):
    sprite.stop()
    sprite.visible = false
    sprite_pool.append(sprite)
```

