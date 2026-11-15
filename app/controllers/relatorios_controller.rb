# frozen_string_literal: true

class RelatoriosController < ApplicationController
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

before_action :require_gestor, only: [ :index, :exportar ]

  def index
  end

  def exportar
    data_inicio = params[:data_inicio].presence
    data_fim = params[:data_fim].presence

    if data_inicio && data_fim
      @movimentacoes = Acesso.where(data_hora: data_inicio.to_date.beginning_of_day..data_fim.to_date.end_of_day)
    else
      @movimentacoes = Acesso.none
    end

    if @movimentacoes.empty?
      flash[:alert] = "Nenhum registro encontrado para o período"
      redirect_to relatorios_path
    else
      respond_to do |format|
        format.pdf do
          pdf_data = render_to_string(
            pdf: "Relatorio_Operacao_#{Date.current}",
            template: "relatorios/exportar",
            formats: [ :html ],
            layout: false
          )
          send_data pdf_data,
                    filename: "Relatorio_Operacao_#{Date.current}.pdf",
                    type: "application/pdf",
                    disposition: "attachment"
        end
      end
    end
  end

  private

  def require_gestor
    funcionario = Funcionario.find_by(id: session[:funcionario_id])

    unless funcionario&.perfil.to_s.casecmp("gestor").zero?
      flash[:alert] = "Acesso restrito a gestores"
      redirect_to root_path
    end
  end
end
