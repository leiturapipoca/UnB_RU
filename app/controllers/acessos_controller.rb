class AcessosController < ApplicationController
  before_action :exigir_ponto_de_acesso

  def new
  end

  def create
    resultado = ValidadorFastpass.new(
      sessao_operacao: sessao_operacao_atual, codigo_passe: params[:codigo_passe]
    ).validar

    if resultado.liberado?
      redirect_to new_acesso_path, notice: "Entrada liberada"
    else
      redirect_to new_acesso_path, alert: "Entrada bloqueada: #{resultado.motivo.to_s.humanize}"
    end
  end
end
