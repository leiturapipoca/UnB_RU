# frozen_string_literal: true

module AutenticacaoEstudante
  extend ActiveSupport::Concern

  included do
    helper_method :current_estudante
  end

  private

  def current_estudante
    return @current_estudante if defined?(@current_estudante)
    @current_estudante = Estudante.find_by(id: session[:estudante_id]) if session[:estudante_id]
  end

  def exigir_login_estudante(mensagem: "Faça login para continuar")
    return if current_estudante
    redirect_to login_estudante_path, alert: mensagem
  end
end
