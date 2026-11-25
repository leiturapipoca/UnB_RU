# frozen_string_literal: true

class InscricoesFastpassController < ApplicationController
  TURNO_LABELS = {
    "cafe_da_manha" => "Café da Manhã",
    "almoco" => "Almoço",
    "jantar" => "Jantar"
  }.freeze

  STATUS_LABELS = {
    "aguardando_sorteio" => "Aguardando sorteio",
    "contemplado" => "Contemplado",
    "nao_contemplado" => "Não contemplado",
    "vaga_liberada" => "Vaga liberada",
    "utilizada" => "Utilizada",
    "expirada" => "Expirada"
  }.freeze

  before_action :autenticar_estudante!
  before_action :carregar_contexto_formulario, only: %i[new create]

  def index
    @inscricoes = InscricaoFastpass.where(estudante_id: current_estudante.id)
                                   .includes(sorteio: :turno, janela_fastpass: :turno)
                                   .order(inscrito_em: :desc)
  end

  def new
    @inscricao = InscricaoFastpass.new
  end

  def create
    @inscricao = InscricaoFastpass.new(inscricao_params)
    @inscricao.estudante_id = current_estudante.id
    @inscricao.inscrito_em = Time.current
    @inscricao.status = :aguardando_sorteio

    @inscricao.valid?
    validar_regras_negocio(@inscricao)

    if @inscricao.errors.empty? && @inscricao.save(validate: false)
      redirect_to inscricoes_fastpass_path, notice: "Inscrição no FastPass realizada com sucesso!"
    else
      carregar_contexto_formulario
      flash.now[:alert] = mensagem_erro(@inscricao)
      render :new, status: :unprocessable_content
    end
  rescue ActiveRecord::RecordNotUnique
    carregar_contexto_formulario
    flash.now[:alert] = "Inscrição já realizada"
    render :new, status: :unprocessable_content
  end

  private

  def autenticar_estudante!
    redirect_to login_path, alert: "Faça login para acessar o FastPass." unless current_estudante
  end

  def carregar_contexto_formulario
    @sorteios = Sorteio.status_inscricoes_abertas.includes(:turno).order(:data)
    sorteio_id = params.dig(:inscricao_fastpass, :sorteio_id) || params[:sorteio_id]
    @sorteio_selecionado = @sorteios.find { |s| s.id.to_s == sorteio_id.to_s } || @sorteios.first

    @ja_inscrito = @sorteio_selecionado.present? &&
                   InscricaoFastpass.exists?(estudante_id: current_estudante.id, sorteio_id: @sorteio_selecionado.id)

    @janelas = if @ja_inscrito || @sorteio_selecionado.nil?
                 []
    else
                 JanelaFastpass.where(turno_id: @sorteio_selecionado.turno_id, ativa: true).order(:hora_inicio)
    end
  end

  def inscricao_params
    params.require(:inscricao_fastpass).permit(:sorteio_id, :janela_fastpass_id)
  end

  def validar_regras_negocio(inscricao)
    if current_estudante.fastpass_bloqueado_ate.present? && current_estudante.fastpass_bloqueado_ate > Time.current
      inscricao.errors.add(:base, "Estudante bloqueado para utilizar o FastPass no momento")
    end

    if inscricao.sorteio.present? && !inscricao.sorteio.status_inscricoes_abertas?
      inscricao.errors.add(:base, "As inscrições para este sorteio não estão abertas")
    end

    if inscricao.janela_fastpass.present? && !inscricao.janela_fastpass.ativa?
      inscricao.errors.add(:janela_fastpass, "não está ativa")
    end

    if inscricao.sorteio.present? && inscricao.janela_fastpass.present? &&
       inscricao.janela_fastpass.turno_id != inscricao.sorteio.turno_id
      inscricao.errors.add(:janela_fastpass, "não pertence ao turno do sorteio selecionado")
    end
  end

  def mensagem_erro(inscricao)
    if inscricao.errors.of_kind?(:estudante_id, :taken)
      "Inscrição já realizada"
    else
      inscricao.errors.full_messages.to_sentence
    end
  end

  def alternar_notificacoes
    novo_estado = !current_estudante.notificacoes_ativas?
    current_estudante.update!(notificacoes_ativas: novo_estado)
    mensagem = novo_estado ? "Notificações do FastPass ativadas." : "Notificações do FastPass bloqueadas."
    redirect_to inscricoes_fastpass_path, notice: mensagem
  end
end
