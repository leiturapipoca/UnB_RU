# frozen_string_literal: true

class TurnosController < ApplicationController
  before_action :require_gestor

  def new
    @turno = Turno.new
  end

  def create
    campus = Campus.find_or_create_by!(nome: "Darcy Ribeiro")
    @turno = Turno.new(turno_params.merge(campus: campus))

    if @turno.save
      flash[:notice] = "Turno cadastrado com sucesso"
      redirect_to new_turno_path
    else
      flash.now[:alert] = @turno.errors.full_messages.first || "Erro ao cadastrar turno"
      render :new, status: :unprocessable_content
    end
  rescue ActiveRecord::StatementInvalid
    flash.now[:alert] = "Conflito de horário com turno existente"
    render :new, status: :unprocessable_content
  end

  private

  def turno_params
    params.require(:turno).permit(:tipo_refeicao, :hora_inicio, :hora_fim)
  end

  def require_gestor
    funcionario = Funcionario.find_by(id: session[:funcionario_id])

    unless funcionario&.perfil.to_s.casecmp("gestor").zero?
      flash[:alert] = "Acesso restrito a gestores"
      redirect_to root_path
    end
  end
end