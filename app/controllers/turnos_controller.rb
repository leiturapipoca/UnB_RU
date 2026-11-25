# frozen_string_literal: true

class TurnosController < ApplicationController
  before_action :require_gestor
  before_action :set_turno, only: %i[show edit update]

  def index
    @turnos = Turno.includes(:campus, :janelas_fastpass).order(:campus_id, :hora_inicio)
    @inscricoes_hoje = InscricaoFastpass.joins(:sorteio)
                                        .where(sorteios: { data: Date.current })
                                        .includes(:estudante, :janela_fastpass, sorteio: :turno)
                                        .order(inscrito_em: :desc)
  end

  def show
    @janelas = @turno.janelas_fastpass.order(:hora_inicio)
    @janela = @turno.janelas_fastpass.new(ativa: true, cota_vagas: 10)
  end

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

  def edit
  end

  def update
    if @turno.update(turno_params)
      redirect_to turno_path(@turno), notice: "Turno atualizado com sucesso"
    else
      flash.now[:alert] = @turno.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_content
    end
  rescue ActiveRecord::StatementInvalid
    flash.now[:alert] = "Conflito de horário ou alteração incompatível com os time-frames existentes"
    render :edit, status: :unprocessable_content
  end

  private

  def set_turno
    @turno = Turno.find(params[:id])
  end

  def turno_params
    params.require(:turno).permit(
      :tipo_refeicao, :hora_inicio, :hora_fim, :ativo,
      :fastpass_habilitado, :tolerancia_atraso_min, :antecedencia_min, :trava_pontualidade
    )
  end

  def require_gestor
    funcionario = Funcionario.find_by(id: session[:funcionario_id])

    unless funcionario&.perfil.to_s.casecmp("gestor").zero?
      flash[:alert] = "Acesso restrito a gestores"
      redirect_to root_path
    end
  end
end
