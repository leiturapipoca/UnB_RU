# frozen_string_literal: true

class EstudantesController < ApplicationController
  before_action :definir_estudante_extrato, only: %i[extrato historico exportar_historico]

  def new
    @estudante = Estudante.new
  end

  def create
    @estudante = Estudante.new(estudante_params)


    @estudante.grupo_tarifario = GrupoTarifario.first || GrupoTarifario.create!(nome: "Padrão")


    if estudante_params.values.all?(&:blank?)
      flash.now[:alert] = "Preencha todos os campos"
      render :new, status: :unprocessable_entity
      return
    end

    if @estudante.save
      redirect_to new_estudante_path, notice: "Usuário cadastrado com sucesso"
    else
      if @estudante.errors[:matricula].include?("has already been taken") || @estudante.errors[:matricula].include?("já está em uso")
        flash.now[:alert] = "Estudante já cadastrado"
      elsif @estudante.errors[:matricula].include?("is invalid") || @estudante.errors[:matricula].include?("não é válido")
        flash.now[:alert] = "A matrícula deve conter exatamente 9 dígitos numéricos"
      end

      render :new, status: :unprocessable_entity
    end
  end

  def historico
    carregar_dados_extrato

    if params[:exportar].present? && @quantidade_refeicoes.zero?
      flash.now[:alert] = "Nenhum registro no histórico"
    end

    render :extrato
  end

  def extrato
    carregar_dados_extrato

    if params[:exportar].present? && @quantidade_refeicoes.zero?
      flash.now[:alert] = "Nenhum registro no histórico"
    end
  end

  def exportar_historico
    carregar_dados_extrato

    if @quantidade_refeicoes.zero?
      redirect_to historico_refeicoes_path, alert: "Nenhum registro no histórico"
      return
    end

    if params[:formato].to_s.upcase == "PDF"
      pdf_conteudo = gerar_pdf_historico(@estudante, @movimentacoes)
      send_data pdf_conteudo,
                filename: "extrato_refeicoes.pdf",
                type: "application/pdf",
                disposition: "attachment"
    else
      redirect_to historico_refeicoes_path, alert: "Formato inválido."
    end
  end

  private

  def estudante_params
    params.require(:estudante).permit(:matricula, :nome, :senha_hash)
  end

  def definir_estudante_extrato
    unless current_estudante
      redirect_to login_path, alert: "Faça login para visualizar seu extrato"
      return
    end


    @estudante = params[:id].present? ? Estudante.find_by(id: params[:id]) : current_estudante
  end

  def carregar_dados_extrato
    @movimentacoes = []
    @total_recarregado = 0
    @total_gasto = 0
    @quantidade_refeicoes = 0
    return unless @estudante


    @movimentacoes = Extrato.where(estudante_id: @estudante.id).order(data_hora: :desc).to_a
    @total_recarregado = @movimentacoes.select { |m| m.tipo == "RECARGA" }.sum(&:valor)
    @total_gasto = @movimentacoes.select { |m| m.tipo == "REFEICAO" }.sum { |m| m.valor.abs }
    @quantidade_refeicoes = @movimentacoes.count { |m| m.tipo == "REFEICAO" }
  end

  def gerar_pdf_historico(estudante, movimentacoes)
    linhas = [
      "Extrato de Refeicoes - #{estudante.nome} (#{estudante.matricula.strip})",
      "------------------------------------------------------------"
    ]

    movimentacoes.each do |m|
      data = m.data_hora&.strftime("%d/%m/%Y %H:%M")
      linhas << "#{data} | #{m.tipo} | #{m.descricao} | R$ #{format('%.2f', m.valor)}"
    end

    texto_pdf = linhas.map.with_index do |linha, idx|
      escapado = linha.gsub("\\", "\\\\\\\\").gsub("(", "\\(").gsub(")", "\\)")
      idx.zero? ? "(#{escapado}) Tj" : "0 -16 Td (#{escapado}) Tj"
    end.join("\n")

    stream = "BT\n/F1 10 Tf\n40 780 Td\n#{texto_pdf}\nET"

    objetos = [
      "1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj",
      "2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj",
      "3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>\nendobj",
      "4 0 obj\n<< /Length #{stream.bytesize} >>\nstream\n#{stream}\nendstream\nendobj",
      "5 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj"
    ]

    pdf = +"%PDF-1.4\n"
    offsets = [ 0 ]

    objetos.each do |obj|
      offsets << pdf.bytesize
      pdf << "#{obj}\n"
    end

    xref_pos = pdf.bytesize
    pdf << "xref\n0 #{objetos.size + 1}\n"
    pdf << "0000000000 65535 f \n"
    offsets[1..].each do |offset|
      pdf << "#{format('%010d', offset)} 00000 n \n"
    end

    pdf << "trailer\n<< /Size #{objetos.size + 1} /Root 1 0 R >>\nstartxref\n#{xref_pos}\n%%EOF"
    pdf
  end
end
