# frozen_string_literal: true

class FastpassController < ApplicationController
  before_action :exigir_login

  def new
    momento_simulado if Rails.env.development?
  end

  def create
    sessao = sessao_operacao_atual ||
             SessaoOperacao.where(encerrada_em: nil).order(id: :desc).first ||
             SessaoOperacao.order(id: :desc).first

    resultado = ValidadorFastpass.new(
      sessao_operacao: sessao,
      codigo_passe: params[:codigo_passe],
      momento: Rails.env.development? ? momento_simulado : Time.current
    ).validar

    destino = if Rails.env.development? && session[:hora_simulada].present?
                fastpass_path(hora: session[:hora_simulada])
    else
                fastpass_path
    end

    if resultado.liberado?
      redirect_to destino, notice: "Entrada liberada"
    else
      redirect_to destino, alert: "Entrada bloqueada: #{resultado.motivo.to_s.humanize}"
    end
  end

  private

  def momento_simulado
    if params[:hora].present?
      valor = params[:hora].to_s.strip
      if %w[real limpar off].include?(valor.downcase)
        session.delete(:hora_simulada)
      elsif valor.match?(/\A([01]?\d|2[0-3]):[0-5]\d\z/)
        session[:hora_simulada] = valor
      end
    end

    return Time.current if session[:hora_simulada].blank?

    hora, minuto = session[:hora_simulada].split(":").map(&:to_i)
    Time.current.change(hour: hora, min: minuto, sec: 0)
  end
end
