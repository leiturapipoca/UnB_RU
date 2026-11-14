# Regra da issue 16 (Validação rigorosa do FastPass):
# o aluno sorteado chegou no horário? Se sim, libera a catraca e debita o saldo;
# se não, bloqueia. Todo resultado (liberado ou bloqueado) fica registrado em "acessos".
class ValidadorFastpass
  # Struct = "caixinha" com campos nomeados para devolver o resultado
  Resultado = Struct.new(:liberado, :motivo, :acesso, keyword_init: true) do
    def liberado? = liberado
  end

  def initialize(sessao_operacao:, codigo_passe:, momento: Time.current)
    @sessao = sessao_operacao
    @codigo = codigo_passe.to_s.strip
    @momento = momento # pode ser trocado nos testes para simular outro horário
  end

  def validar
    inscricao = InscricaoFastpass.status_contemplado
                                 .includes(:estudante, :sorteio, janela_fastpass: :turno)
                                 .find_by(codigo_passe: @codigo)
    return bloquear(:sem_fastpass) if inscricao.nil?

    janela = inscricao.janela_fastpass
    turno  = janela.turno

    return bloquear(:fora_do_turno, inscricao: inscricao, turno: turno) unless inscricao.sorteio.data == @momento.to_date
    return bloquear(:fora_da_janela, inscricao: inscricao, turno: turno) unless dentro_do_horario?(janela, turno)

    liberar(inscricao, turno)
  end

  private

  # REGRA A CONFIRMAR COM O TIME: horário vigente = janela do FastPass, com antecedência
  # antes do início e tolerância de atraso depois do fim. trava_pontualidade: false desliga o bloqueio.
  def dentro_do_horario?(janela, turno)
    return true unless turno.trava_pontualidade

    agora  = @momento.seconds_since_midnight
    inicio = janela.hora_inicio.seconds_since_midnight - turno.antecedencia_min * 60
    fim    = janela.hora_fim.seconds_since_midnight + turno.tolerancia_atraso_min * 60
    agora.between?(inicio, fim)
  end

  def liberar(inscricao, turno)
    acesso = nil
    # requires_new: cria um "savepoint". Se o gatilho do banco recusar o acesso (saldo insuficiente,
    # por exemplo), só este bloco é desfeito e ainda podemos gravar o bloqueio em seguida.
    ActiveRecord::Base.transaction(requires_new: true) do
      acesso = Acesso.create!(
        sessao_operacao: @sessao, turno: turno, estudante: inscricao.estudante,
        inscricao_fastpass: inscricao, identificacao_lida: @codigo,
        data_hora: @momento, modalidade: :fastpass, resultado: :liberado
      )
      inscricao.status_utilizada!
    end
    # O gatilho do banco (fn_acesso_validar/fn_acesso_debitar) já calculou valor_cobrado e debitou o saldo
    comandar_catraca(:liberar)
    Resultado.new(liberado: true, acesso: acesso.reload)
  rescue ActiveRecord::StatementInvalid => e
    motivo = motivo_do_erro(e.message)
    raise if motivo.nil? # erro que não conhecemos: não esconder
    bloquear(motivo, inscricao: inscricao, turno: turno)
  end

  def bloquear(motivo, inscricao: nil, turno: nil)
    acesso = Acesso.create!(
      sessao_operacao: @sessao, turno: turno, estudante: inscricao&.estudante,
      inscricao_fastpass: inscricao, identificacao_lida: @codigo.presence || "desconhecido",
      data_hora: @momento, modalidade: :fastpass, resultado: :bloqueado,
      motivo_bloqueio: motivo, valor_cobrado: 0
    )
    comandar_catraca(:bloquear)
    Resultado.new(liberado: false, motivo: motivo, acesso: acesso)
  end

  # Ponto de integração com a catraca física. Por enquanto só registra no log.
  def comandar_catraca(acao)
    Rails.logger.info("[Catraca #{@sessao.catraca.numero}] #{acao.to_s.upcase}")
  end

  def motivo_do_erro(mensagem)
    if mensagem.include?("Saldo insuficiente")
      :saldo_insuficiente
    elsif mensagem.include?("Entrada")
      :entrada_ja_registrada
    end
  end
end
