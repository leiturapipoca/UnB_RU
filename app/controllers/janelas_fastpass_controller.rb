# frozen_string_literal: true

class JanelasFastpassController < ApplicationController
  before_action :require_gestor
  before_action :set_turno
  before_action :set_janela, only: %i[edit update destroy]

  def create
    @janela = @turno.janelas_fastpass.new(janela_params)

    if @janela.save
      garantir_sorteio_aberto_hoje(@turno)
      redirect_to turno_path(@turno), notice: "Time-frame cadastrado com sucesso (inscrições de hoje liberadas)"
    else
      @janelas = @turno.janelas_fastpass.order(:hora_inicio)
      flash.now[:alert] = @janela.errors.full_messages.to_sentence
      render "turnos/show", status: :unprocessable_content
    end
  rescue ActiveRecord::StatementInvalid
    @janelas = @turno.janelas_fastpass.order(:hora_inicio)
    flash.now[:alert] = "Time-frame inválido ou em conflito com outro horário do turno"
    render "turnos/show", status: :unprocessable_content
  end

  def edit
  end

  def update
    if @janela.update(janela_params)
      redirect_to turno_path(@turno), notice: "Time-frame atualizado com sucesso"
    else
      flash.now[:alert] = @janela.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_content
    end
  rescue ActiveRecord::StatementInvalid
    flash.now[:alert] = "Time-frame inválido ou em conflito com outro horário do turno"
    render :edit, status: :unprocessable_content
  end

  def destroy
    if @janela.destroy
      redirect_to turno_path(@turno), notice: "Time-frame removido com sucesso"
    else
      redirect_to turno_path(@turno), alert: "Não é possível remover um time-frame que já possui inscrições"
    end
  end

  private

  def set_turno
    @turno = Turno.find(params[:turno_id])
  end

  def set_janela
    @janela = @turno.janelas_fastpass.find(params[:id])
  end

  def janela_params
    params.require(:janela_fastpass).permit(:hora_inicio, :hora_fim, :cota_vagas, :ativa)
  end

  def garantir_sorteio_aberto_hoje(turno)
    turno.update!(fastpass_habilitado: true) unless turno.fastpass_habilitado?
    Sorteio.find_or_create_by!(turno: turno, data: Date.current) do |s|
      s.data_hora_resultado = Time.current + 1.hour
      s.status = :inscricoes_abertas
    end
  end

  def require_gestor
    funcionario = Funcionario.find_by(id: session[:funcionario_id])

    unless funcionario&.perfil.to_s.casecmp("gestor").zero?
      flash[:alert] = "Acesso restrito a gestores"
      redirect_to root_path
    end
  end
end
