class Acesso < ApplicationRecord
  self.table_name = "acessos"
  belongs_to :sessao_operacao
  belongs_to :turno, optional: true
  belongs_to :estudante, optional: true
  belongs_to :inscricao_fastpass, optional: true
  enum :modalidade, { comum: "COMUM", fastpass: "FASTPASS" }, prefix: :modalidade
  enum :resultado, { liberado: "LIBERADO", bloqueado: "BLOQUEADO" }, prefix: :resultado
  enum :motivo_bloqueio, {
    identificacao_invalida: "IDENTIFICACAO_INVALIDA", saldo_insuficiente: "SALDO_INSUFICIENTE",
    entrada_ja_registrada: "ENTRADA_JA_REGISTRADA", fora_do_turno: "FORA_DO_TURNO",
    fora_da_janela: "FORA_DA_JANELA", sem_fastpass: "SEM_FASTPASS",
    validacao_offline_indisponivel: "VALIDACAO_OFFLINE_INDISPONIVEL"
  }, prefix: :motivo
  enum :divergencia, { entrada_duplicada: "ENTRADA_DUPLICADA", saldo_negativo: "SALDO_NEGATIVO" }, prefix: :divergencia
  validates :valor_cobrado, numericality: { greater_than_or_equal_to: 0 }
  validates :identificacao_lida, presence: true, length: { maximum: 64 }
  validates :data_hora, presence: true
  validate :sincronizacao_valida

  private
  def sincronizacao_valida
    if sincronizado_em.present? && data_hora.present? && sincronizado_em < data_hora
      errors.add(:sincronizado_em, "não pode ser anterior à data/hora original do acesso")
    end
  end
end
