# frozen_string_literal: true

class AcessosController < ApplicationController
  def new
  end

  def create
    matricula = params[:identificacao].to_s.strip

    if session[:modo_offline]
      processar_offline(matricula)
      return
    end

    estudante = Estudante.find_by(matricula: matricula)
    if estudante.nil?
      flash.now[:alert] = "Acesso Não Autorizado"
      render :new, status: :unprocessable_entity
      return
    end

    sessao = SessaoOperacao.where(encerrada_em: nil).first
    horario_atual = Time.current.strftime("%H:%M:%S")
    turno = Turno.where("hora_inicio <= ? AND hora_fim >= ?", horario_atual, horario_atual).first

    if turno.nil? || sessao.nil?
      flash.now[:alert] = "Fora do horário de atendimento"
      render :new, status: :unprocessable_entity
      return
    end

    acesso = Acesso.new(
      sessao_operacao_id: sessao.id,
      turno_id: turno.id,
      estudante_id: estudante.id,
      identificacao_lida: matricula,
      data_hora: Time.current,
      modalidade: "COMUM",
      resultado: "LIBERADO"
    )

    begin
      if acesso.save
        flash.now[:notice] = "Catraca Liberada"
        render :new, status: :ok
      end
    rescue ActiveRecord::StatementInvalid => e
      if e.message.include?("Saldo insuficiente")
        flash.now[:alert] = "Acesso Não Autorizado"
      elsif e.message.include?("Entrada já registrada")
        flash.now[:alert] = "Entrada já registrada"
      else
        flash.now[:alert] = "Erro ao processar acesso"
      end
      render :new, status: :unprocessable_entity
    end
  end

  def sincronizar
    session[:modo_offline] = false
    pendentes = session[:historico_local] || []

    sessao = SessaoOperacao.where(encerrada_em: nil).first
    horario_atual = Time.current.strftime("%H:%M:%S")
    turno = Turno.where("hora_inicio <= ? AND hora_fim >= ?", horario_atual, horario_atual).first

    sincronizados = 0

    if sessao.present? && turno.present?
      pendentes.each do |registro|
        matricula = registro.is_a?(Hash) ? registro["matricula"] : registro
        data_registro = registro.is_a?(Hash) && registro["data_hora"] ? Time.zone.parse(registro["data_hora"]) : Time.current

        estudante = Estudante.find_by(matricula: matricula)
        next unless estudante

        begin
          Acesso.create!(
            sessao_operacao_id: sessao.id,
            turno_id: turno.id,
            estudante_id: estudante.id,
            identificacao_lida: matricula,
            data_hora: data_registro,
            modalidade: "COMUM",
            resultado: "LIBERADO",
            sincronizado_em: Time.current
          )
          sincronizados += 1
        rescue ActiveRecord::StatementInvalid
          next
        end
      end
    end

    session[:historico_local] = []

    respond_to do |format|
      format.html do
        flash[:notice] = "Sincronizado com sucesso: #{sincronizados} acessos"
        redirect_to catraca_validacao_path
      end
      format.json { render json: { status: "sucesso", sincronizados: sincronizados } }
    end
  end

  private

  def processar_offline(matricula)
    if matricula.blank? || session[:falha_validacao_local]
      flash.now[:alert] = "Validação indisponível offline"
      render :new, status: :unprocessable_entity
      return
    end

    session[:historico_local] ||= []
    session[:historico_local] << {
      "matricula" => matricula,
      "data_hora" => Time.current.iso8601
    }

    flash.now[:notice] = "Catraca Liberada"
    render :new, status: :ok
  end
end