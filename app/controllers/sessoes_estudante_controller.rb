# frozen_string_literal: true

class SessoesEstudanteController < ApplicationController
  before_action :exigir_login_estudante, only: :destroy

  def new
    redirect_to extrato_estudante_path(current_estudante) if current_estudante
  end

  def create
    estudante = Estudante.autenticar(params[:matricula], params[:senha])

    if estudante
      reset_session
      session[:estudante_id] = estudante.id
      redirect_to extrato_estudante_path(estudante)
    else
      flash.now[:alert] = "Matrícula ou senha inválidos"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to login_estudante_path, notice: "Você saiu do sistema"
  end
end