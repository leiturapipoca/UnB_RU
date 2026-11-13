# Leitura do passe do FastPass na catraca (issue 16).
# A validação comum (matrícula) e a sincronização offline ficam no AcessosController.
class FastpassController < ApplicationController
  before_action :exigir_login
  before_action :exigir_ponto_de_acesso

  def new
  end

  def create
    resultado = ValidadorFastpass.new(
      sessao_operacao: sessao_operacao_atual, codigo_passe: params[:codigo_passe]
    ).validar

    if resultado.liberado?
      redirect_to fastpass_path, notice: "Entrada liberada"
    else
      redirect_to fastpass_path, alert: "Entrada bloqueada: #{resultado.motivo.to_s.humanize}"
    end
  end
end
