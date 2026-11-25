# frozen_string_literal: true

class FastpassSimulacaoController < ApplicationController
  before_action :require_gestor

  def create
    resultado = SimuladorFastpass.new.executar

    if resultado.sucesso?
      redirect_to turnos_path,
                  notice: "FastPass simulado! Contemplados: #{resultado.contemplados} · Não contemplados: #{resultado.nao_contemplados}. Notificações disparadas."
    else
      redirect_to turnos_path, alert: resultado.erro
    end
  end

  private

  def require_gestor
    funcionario = Funcionario.find_by(id: session[:funcionario_id])

    unless %w[gestor administrador].include?(funcionario&.perfil.to_s.downcase)
      flash[:alert] = "Acesso restrito a gestores"
      redirect_to root_path
    end
  end
end
