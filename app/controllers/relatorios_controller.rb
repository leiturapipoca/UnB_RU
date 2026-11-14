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
end
