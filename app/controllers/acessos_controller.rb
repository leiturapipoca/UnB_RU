# frozen_string_literal: true
class AcessosController < ApplicationController
  def new
    # Renderiza a tela aguardando a leitura do cartão/matrícula
  end

  def sincronizar
    acessos_pendentes = params[:acessos] || []
    
    sessao = SessaoOperacao.where(encerrada_em: nil).first
    turno = Turno.where("hora_inicio <= ? AND hora_fim >= ?", Time.current.strftime("%H:%M:%S"), Time.current.strftime("%H:%M:%S")).first
    
    if sessao.present? && turno.present?
      acessos_pendentes.each do |matricula|
        estudante = Estudante.find_by(matricula: matricula)
        next unless estudante
        
        # Registra o acesso atrasado marcando a hora em que foi sincronizado
        begin
          Acesso.create(
            sessao_operacao_id: sessao.id,
            turno_id: turno.id,
            estudante_id: estudante.id,
            identificacao_lida: matricula,
            data_hora: Time.current, # No mundo real, viria do JS o horário exato do offline
            modalidade: 'COMUM',
            resultado: 'LIBERADO',
            sincronizado_em: Time.current
          )
        rescue ActiveRecord::StatementInvalid
          # Ignora caso a trigger do banco barre (ex: se o cara passou duas vezes offline)
          next
        end
      end
    end

    render json: { status: 'sucesso', sincronizados: acessos_pendentes.length }
  end



  def create
    matricula = params[:identificacao]
    estudante = Estudante.find_by(matricula: matricula)

    # 1. Se não achar o estudante (identificação inválida)
    if estudante.nil?
      flash.now[:alert] = "Acesso Não Autorizado"
      render :new, status: :unprocessable_entity
      return
    end

    # Para o MVP, vamos pegar um turno e uma sessão ativa fictícios/atuais
    # Na vida real, a sessão estaria vinculada ao operador logado.
    sessao = SessaoOperacao.where(encerrada_em: nil).first
    horario_atual = Time.current.strftime("%H:%M:%S")
    turno = Turno.where("hora_inicio <= ? AND hora_fim >= ?", horario_atual, horario_atual).first

    if turno.nil? || sessao.nil?
      flash.now[:alert] = "Sistema indisponível ou fora do horário"
      render :new, status: :unprocessable_entity
      return
    end

    # 2. Tenta registrar o acesso liberado
    acesso = Acesso.new(
      sessao_operacao_id: sessao.id,
      turno_id: turno.id,
      estudante_id: estudante.id,
      identificacao_lida: matricula,
      data_hora: Time.current,
      modalidade: 'COMUM',
      resultado: 'LIBERADO'
    )

    begin
      if acesso.save
        flash.now[:notice] = "Catraca Liberada"
      end
    rescue ActiveRecord::StatementInvalid => e
      # 3. Captura as exceções geradas pelas triggers do seu structure.sql
      if e.message.include?("Saldo insuficiente")
        flash.now[:alert] = "Acesso Não Autorizado"
      elsif e.message.include?("Entrada já registrada")
        flash.now[:alert] = "Entrada já registrada"
      else
        flash.now[:alert] = "Erro ao processar acesso"
      end
    end


        

    # Renderiza a mesma tela mostrando a mensagem (flash)
    render :new, status: :unprocessable_entity
  end
end