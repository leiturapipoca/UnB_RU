# frozen_string_literal: true

class NotificadorFastpass
  def self.processar(sorteio)
    inscricoes_pendentes = sorteio.inscricoes_fastpass.where(
      status: [ "CONTEMPLADO", "NAO_CONTEMPLADO" ],
      notificado_em: nil
    )

    inscricoes_pendentes.find_each do |inscricao|
      estudante = inscricao.estudante

      if estudante.notificacoes_ativas?
        FastpassMailer.resultado_sorteio(inscricao).deliver_now
      end

      inscricao.update!(notificado_em: Time.current)
    end
  end
end
