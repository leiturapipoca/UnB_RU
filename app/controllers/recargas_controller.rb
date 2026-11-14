# frozen_string_literal: true

class RecargasController < ApplicationController
  before_action :autenticar_estudante!
  before_action :set_recarga, only: %i[show confirmar expirar]

  def new
    @recarga = current_estudante.recargas.build
  end

  def create
    @recarga = current_estudante.recargas.build(recarga_params)

    if recarga_params[:metodo_pagamento].present?
      @recarga.metodo_pagamento = mapear_metodo_pagamento(recarga_params[:metodo_pagamento])
    end

    @recarga.status = :pendente
    @recarga.solicitada_em = Time.current
    @recarga.codigo_transacao = SecureRandom.hex(16)

    if @recarga.save
      redirect_to @recarga, notice: "Solicitação de recarga criada. Aguardando pagamento."
    else
      flash.now[:alert] = @recarga.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  def show
    # Renderiza a view app/views/recargas/show.html.erb com os dados e os botões do MVP
  end

  def confirmar
    unless @recarga.status_pendente?
      redirect_to @recarga, alert: "Esta recarga já foi processada."
      return
    end

    ActiveRecord::Base.transaction do
      @recarga.update!(
        status: :confirmada,
        confirmada_em: Time.current
      )

      estudante = @recarga.estudante
      novo_saldo = estudante.saldo.to_f + @recarga.valor.to_f
      estudante.update!(saldo: novo_saldo)
    end

    redirect_to @recarga, notice: "Recarga confirmada com sucesso!"
  rescue ActiveRecord::RecordInvalid => e
    redirect_to @recarga, alert: "Erro ao efetivar pagamento: #{e.message}"
  end

  def expirar
    if @recarga.status_pendente?
      @recarga.update!(status: :expirada)
    end

    redirect_to @recarga, alert: "Erro ao efetivar pagamento"
  end

  private

  def set_recarga
    @recarga = current_estudante.recargas.find(params[:id])
  end

  def recarga_params
    params.require(:recarga).permit(:valor, :metodo_pagamento)
  end

  def mapear_metodo_pagamento(valor)
    case valor.to_s.upcase
    when "PIX" then :pix
    when "CARTAO_CREDITO" then :cartao_credito
    else valor
    end
  end

  def autenticar_estudante!
    unless current_estudante
      redirect_to login_path, alert: "Faça login para acessar esta página."
    end
  end
end
