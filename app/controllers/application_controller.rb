class ApplicationController < ActionController::Base
  # Traz para todos os controllers: exigir_login, funcionario_logado, etc.
  include Autenticacao

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_estudante

  if Rails.env.development?
    require "active_support/testing/time_helpers"
    include ActiveSupport::Testing::TimeHelpers

    around_action :aplicar_hora_simulada_dev
  end

  private

  def current_estudante
    @current_estudante ||= Estudante.find_by(id: session[:estudante_id]) if session[:estudante_id]
  end

  def aplicar_hora_simulada_dev(&block)
    if params[:hora].present?
      valor = params[:hora].to_s.strip
      if %w[real limpar off].include?(valor.downcase)
        session.delete(:hora_simulada)
      elsif valor.match?(/\A([01]?\d|2[0-3]):[0-5]\d\z/)
        session[:hora_simulada] = valor
      end
    end

    if session[:hora_simulada].present?
      hora, minuto = session[:hora_simulada].split(":").map(&:to_i)
      travel_to(Time.current.change(hour: hora, min: minuto, sec: 0), &block)
    else
      yield
    end
  end
end
