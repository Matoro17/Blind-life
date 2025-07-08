from PIL import Image, ImageDraw, ImageFont
import os

# CONFIGURAÇÕES
palavras = [
    # 🎭 Coisas do Cotidiano
    "Travesseiro",
    "Guarda-chuva",
    "Escada",
    "Janela",
    "Lâmpada",
    "Relógio",
    "Chave",
    "Espelho",
    "Armário",
    "Vela",

    # 🐾 Animais
    "Camaleão",
    "Morcego",
    "Coruja",
    "Pinguim",
    "Cavalo",
    "Polvo",
    "Lobo",
    "Tatu",
    "Gato",
    "Jacaré",

    # 🍎 Comida & Bebida
    "Pizza",
    "Melancia",
    "Sorvete",
    "Pipoca",
    "Chocolate",
    "Limão",
    "Ovo",
    "Batata",
    "Café",
    "Hambúrguer",

    # 🌍 Lugares
    "Castelo",
    "Caverna",
    "Praia",
    "Cemitério",
    "Biblioteca",
    "Escola",
    "Floresta",
    "Estádio",
    "Circo",
    "Torre",

    # 🧙‍♂️ Fantasia e Misticismo
    "Bruxa",
    "Dragão",
    "Poção",
    "Fada",
    "Fantasma",
    "Vampiro",
    "Varinha",
    "Espada",
    "Feitiço",
    "Caverna",  # repetida na categoria

    # 💡 Conceitos Abstratos (pra dificultar um pouco!)
    "Medo",
    "Tempo",
    "Alegria",
    "Mentira",
    "Sonho",
    "Silêncio",
    "Segredo",
    "Esperança",
    "Liberdade",
    "Sombra",

    # 🚀 Coisas Tecnológicas / Futuristas
    "Robô",
    "Satélite",
    "Celular",
    "Computador",
    "Raio laser",
    "Drone",
    "Controle remoto",
    "Fone de ouvido",
    "Teclado",
    "Antena",

    # ⏳ Coisas com Ação
    "Corrida",
    "Mergulho",
    "Pintura",
    "Beijo",
    "Dança",
    "Assobio",
    "Choro",
    "Abraço",
    "Espirro",
    "Grito",

    # 🎁 Diversos / Surpresa
    "Máscara",
    "Cofre",
    "Sereia",
    "Boneca",
    "Pipa",
    "Escorregador",
    "Balão",
    "Ovo de Páscoa",
    "Labirinto",
    "Camuflagem",
]
fundo_path = "cardback.png"  # imagem de fundo (deve ter pelo menos o tamanho da carta)
fonte_path = "Pixellari.ttf"  # substitua pelo caminho da sua fonte
tamanho_fonte_inicial = 300
pasta_saida = "cards"
dimensoes_cm = (6.35, 8.8)  # largura x altura em cm
dpi = 300

# CONVERSÃO PARA PIXELS
cm_para_px = lambda cm: int((cm / 2.54) * dpi)
largura_px = cm_para_px(dimensoes_cm[0])
altura_px = cm_para_px(dimensoes_cm[1])

# CRIA A PASTA DE SAÍDA
os.makedirs(pasta_saida, exist_ok=True)

def ajustar_tamanho_fonte(draw, palavra, fonte_path, max_largura, max_altura):
    tamanho = tamanho_fonte_inicial
    while tamanho > 10:
        fonte = ImageFont.truetype(fonte_path, tamanho)
        bbox = draw.textbbox((0, 0), palavra, font=fonte)
        largura_texto = bbox[2] - bbox[0]
        altura_texto = bbox[3] - bbox[1]
        if largura_texto <= max_largura * 0.9 and altura_texto <= max_altura * 0.9:
            return fonte
        tamanho -= 2
    return ImageFont.truetype(fonte_path, 10)

def gerar_carta(palavra):
    # Passo 1: abrir fundo original e redimensionar como retrato
    fundo = Image.open(fundo_path).convert("RGBA")
    fundo = fundo.resize((largura_px, altura_px))

    # Passo 2: rotacionar fundo para paisagem
    fundo = fundo.rotate(90, expand=True)

    # Passo 3: desenhar sobre a nova imagem paisagem
    draw = ImageDraw.Draw(fundo)
    fonte = ajustar_tamanho_fonte(draw, palavra, fonte_path, altura_px, largura_px)  # altura/largura trocados porque giramos

    bbox = draw.textbbox((0, 0), palavra, font=fonte)
    texto_largura = bbox[2] - bbox[0]
    texto_altura = bbox[3] - bbox[1]
    pos_x = (altura_px - texto_largura) // 2  # largura agora é altura por conta da rotação
    pos_y = (largura_px - texto_altura) // 2

    draw.text((pos_x, pos_y), palavra, font=fonte, fill=(255, 0, 0))  # vermelho

    # Salva imagem final
    caminho = os.path.join(pasta_saida, f"{palavra}.png")
    fundo.save(caminho)
    print(f"Carta salva: {caminho}")

# GERAR TODAS
for palavra in palavras:
    gerar_carta(palavra)