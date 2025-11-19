# 🦁 Como Adicionar GIFs dos Animais

## 📁 Estrutura de Pastas

Cada animal tem sua própria pasta dentro de `Assets/Sprites/Animais/`:

```
Assets/Sprites/Animais/
├── leao/              ← Frames do leão
│   ├── frame_001.png
│   ├── frame_002.png
│   └── ...
├── leao.tres          ← SpriteFrames do leão (criado no Godot)
├── elefante/
│   └── ...
├── elefante.tres
├── macaco/
│   └── ...
├── macaco.tres
├── zebra/
│   └── ...
├── zebra.tres
├── girafa/
│   └── ...
├── girafa.tres
└── README.md
```

## 🔄 Passo a Passo: Convertendo GIF para SpriteFrames

### Passo 1: Extrair Frames do GIF

1. Use uma ferramenta para extrair os frames do GIF:
   - **Online:** [ezgif.com/split](https://ezgif.com/split) ou [cloudconvert.com](https://cloudconvert.com/gif-to-png)
   - **Software:** GIMP, Photoshop, ou qualquer editor de imagens

2. Salve os frames na pasta do animal:
   - Exemplo: `Assets/Sprites/Animais/leao/frame_001.png`, `frame_002.png`, etc.
   - **Dica:** Use nomes sequenciais para facilitar a organização

### Passo 2: Criar SpriteFrames no Godot

1. **No Godot Editor:**
   - Clique com botão direito na pasta `Assets/Sprites/Animais/`
   - Selecione **New Resource**
   - Escolha **SpriteFrames**
   - Salve como `[nome_animal].tres` (ex: `leao.tres`)

2. **Configurar a Animação:**
   - Com o arquivo `leao.tres` selecionado, você verá o painel **SpriteFrames** na parte inferior
   - Clique em **"default"** (ou crie uma nova animação com nome personalizado)
   - No painel **FileSystem**, navegue até a pasta do animal (`leao/`)
   - **Arraste todos os frames** para a área de animação na ordem correta
   - Ajuste o **Speed (FPS)** se necessário (padrão: 5 FPS)
   - Salve o recurso (Ctrl+S)

### Passo 3: Conectar ao AnimalTemplate

1. Abra o arquivo do animal em `Assets/DataModels/`:
   - Exemplo: `lion.tres`, `elephant.tres`, etc.

2. No Inspector, encontre o campo **"Animacao Sprite"**

3. **Arraste o arquivo `.tres`** do SpriteFrames que você criou:
   - Exemplo: Arraste `Assets/Sprites/Animais/leao.tres` para o campo

4. Salve o arquivo do animal

## 🎮 Usando a Animação no Código

Quando você implementar a renderização dos animais nas jaulas, use assim:

```gdscript
# Exemplo: Criar um sprite animado para o animal
func criar_sprite_animal(animal: Animal) -> AnimatedSprite2D:
    var sprite = AnimatedSprite2D.new()
    
    # Obtém o template do animal
    var template = animal.template as AnimalTemplate
    
    # Verifica se tem animação configurada
    if template and template.animacao_sprite:
        sprite.sprite_frames = template.animacao_sprite
        sprite.play("default")  # ou o nome da animação configurada
        sprite.autoplay = "default"  # Inicia automaticamente
    else:
        push_warning("Animal '%s' não tem animação configurada!" % template.nome_exibicao)
    
    return sprite
```

## ⚙️ Configurações Recomendadas

### SpriteFrames
- **Speed (FPS):** 5-10 FPS para animações suaves (ajuste conforme o GIF original)
- **Loop:** Ativado por padrão (ideal para animações de animais)
- **Nome da Animação:** Use "default" para simplicidade, ou nomes específicos como "idle", "walk", etc.

### Frames
- **Tamanho:** Todos os frames devem ter o mesmo tamanho
- **Formato:** PNG com transparência (RGBA) é recomendado
- **Resolução:** Mantenha consistente entre todos os animais (ex: 64x64, 128x128)

## 📋 Checklist

Antes de considerar um animal completo:

- [ ] Frames extraídos e organizados na pasta do animal
- [ ] SpriteFrames criado e configurado no Godot
- [ ] Animação testada e funcionando corretamente
- [ ] SpriteFrames conectado ao AnimalTemplate correspondente
- [ ] Velocidade (FPS) ajustada para parecer natural

## ⚠️ Problemas Comuns

**Animação não aparece:**
- Verifique se o SpriteFrames está conectado ao AnimalTemplate
- Confirme que os frames foram arrastados na ordem correta
- Verifique se o nome da animação está correto no código

**Animação muito rápida/lenta:**
- Ajuste o **Speed (FPS)** no SpriteFrames
- Valores menores = mais lento, valores maiores = mais rápido

**Frames desalinhados:**
- Certifique-se de que todos os frames têm o mesmo tamanho
- Use um editor de imagens para centralizar o conteúdo de cada frame

