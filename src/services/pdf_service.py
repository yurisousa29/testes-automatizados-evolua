from PIL import Image
from reportlab.pdfgen import canvas
from reportlab.lib.colors import white


def gerar_pdf(
    numero_instalacao,
    cpf,
    nome,
    endereco,
    referencia,
    vencimento,
    valor,
    classe,
    subclasse,
    tipo_tarifa,
    arquivo_saida="./src/docs/Fatura-Cliente.pdf"
):
    template = "./src/templates/template-fatura-mg.jpg"

    # Largura e altura de imagem
    largura, altura = Image.open(template).size

    # Criar PDF com o mesmo tamanho da imagem
    pdf = canvas.Canvas(arquivo_saida, pagesize=(largura, altura))

    # Desenha a imagem ocupando a página inteira
    pdf.drawImage(
        template,
        0,
        0,
        width=largura,
        height=altura
    )

    # Nome
    pdf.setFont("Helvetica-Bold", 18)  
    pdf.drawString(46, altura - 165, nome)

    # CPF
    pdf.setFont("Helvetica", 18)
    pdf.drawString(84, altura - 245, cpf)

    # Numero de instalação 1
    pdf.setFont("Helvetica-Bold", 30)
    pdf.drawString(355, altura - 375, numero_instalacao)

    # Numero de instalação 2
    pdf.setFont("Helvetica", 18)
    pdf.drawString(645, altura - 1808, numero_instalacao)

    # Referente a:
    pdf.setFont("Helvetica-Bold", 30)
    pdf.drawString(700, altura - 180, referencia)

    # Vencimento: #1
    pdf.drawString(910, altura - 180, vencimento)

    # Vencimento: #2
    pdf.setFont("Helvetica", 18)
    pdf.drawString(850, altura - 1808, vencimento)

    # Valor: #1
    pdf.setFont("Helvetica-Bold", 30)
    pdf.drawString(1180, altura - 180, valor)

    # Valor: #2
    pdf.setFont("Helvetica", 18)
    pdf.drawString(1120, altura - 1808, valor)

    # Classe
    pdf.setFillColor(white)
    pdf.setFont("Helvetica-Bold", 20)
    pdf.drawString(185, altura - 460, classe)

    # Subclasse
    pdf.setFillColor(white)
    pdf.setFont("Helvetica-Bold", 20)
    pdf.drawString(460, altura - 460, subclasse)

    # Tipo de tarifa
    pdf.setFillColor(white)
    pdf.setFont("Helvetica-Bold", 20)
    pdf.drawString(710, altura - 460, tipo_tarifa)

    pdf.save()

    return arquivo_saida