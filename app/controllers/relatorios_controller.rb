# frozen_string_literal: true

require "prawn"
require "prawn/table"

class RelatoriosController < ApplicationController
  # O relatório global mostra nomes e horários de entrada dos estudantes: só para quem está
  # logado e tem perfil de gestor ou administrador.
  before_action :exigir_login, only: :acessos
  before_action :exigir_gestor_ou_administrador, only: :acessos
  before_action :require_gestor, only: %i[index exportar]

  def acessos
    @restaurantes = Restaurante.order(:nome)
    @catracas_opcoes = Catraca.where.not(descricao: [ nil, "" ]).distinct.order(:descricao).pluck(:descricao)

    @acessos = Acesso.includes(:estudante, sessao_operacao: { catraca: :restaurante })
                     .order(data_hora: :desc)

    if params[:restaurante].present?
      @acessos = @acessos.joins(sessao_operacao: { catraca: :restaurante })
                         .where(restaurantes: { nome: params[:restaurante] })
    end

    if params[:catraca].present?
      @acessos = @acessos.joins(sessao_operacao: :catraca)
                         .where(catracas: { descricao: params[:catraca] })
    end
  end

  def index
  end

  def exportar
    @data_inicio = params[:data_inicio].presence || 1.week.ago.to_date.to_s
    @data_fim    = params[:data_fim].presence || Date.current.to_s

    inicio_dt = Date.parse(@data_inicio).beginning_of_day
    fim_dt    = Date.parse(@data_fim).end_of_day

    @acessos = Acesso.includes(:estudante, :turno)
                     .where(data_hora: inicio_dt..fim_dt)
                     .order(data_hora: :asc)

    if params[:tipo_refeicao].present?
      @acessos = @acessos.joins(:turno).where(turnos: { tipo_refeicao: params[:tipo_refeicao] })
    end

    if @acessos.blank?
      redirect_to relatorios_path, alert: "Não há movimentações no período selecionado."
      return
    end

    pdf = Prawn::Document.new(page_size: "A4", margin: 36)

    font_path = [
      "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
      "/usr/share/fonts/truetype/liberation2/LiberationSans-Regular.ttf",
      "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf"
    ].find { |path| File.exist?(path) }

    if font_path
      pdf.font_families.update(
        "CustomSans" => {
          normal: font_path,
          bold: font_path
        }
      )
      pdf.font "CustomSans"
    end
    
    pdf.text "Relatório de Movimentações", size: 18, style: :bold
    pdf.move_down 6
    pdf.text "Período: #{@data_inicio} a #{@data_fim}", size: 11
    pdf.move_down 14

    rows = [ [ "Data/Hora", "Matrícula", "Modalidade", "Resultado" ] ]
    @acessos.each do |acesso|
      data_formatada = acesso.data_hora&.strftime("%d/%m/%Y %H:%M").to_s
      matricula = acesso.identificacao_lida.presence || acesso.estudante&.matricula.to_s
      rows << [ data_formatada, matricula, acesso.modalidade.to_s, acesso.resultado.to_s ]
    end

    pdf.table(rows, header: true, width: pdf.bounds.width) do |t|
      t.row(0).font_style = :bold
      t.row(0).background_color = "E5E7EB"
      t.cells.padding = [ 6, 8 ]
      t.cells.size = 10
    end

    send_data pdf.render,
              filename: "relatorio_operacao_#{Date.current}.pdf",
              type: "application/pdf",
              disposition: "attachment"
  rescue ArgumentError
    redirect_to relatorios_path, alert: "Período inválido."
  end

  private

  def exigir_gestor_ou_administrador
    return if funcionario_logado&.perfil_gestor? || funcionario_logado&.perfil_administrador?

    redirect_to root_path, alert: "Acesso restrito a gestores e administradores"
  end

  def require_gestor
    funcionario = Funcionario.find_by(id: session[:funcionario_id])

    unless funcionario&.perfil.to_s.casecmp("gestor").zero?
      flash[:alert] = "Acesso restrito a gestores"
      redirect_to root_path
    end
  end
end